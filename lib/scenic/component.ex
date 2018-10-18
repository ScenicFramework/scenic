#
#  Created by Boyd Multerer on 2018-03-26.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component do
  @moduledoc """
  A Component is simply a Scene that is optimized to be referenced by another scene.

  All you need to do to create a Component is call

      use Scenic.Component

  instead of 

      use Scenic.Scene

  At the top of your module definition.

  ## Standard Components

  Scenic includes a small number of standard components that you can simply reuse in your
  scenes. These were chosen to be in the main library because a) they are used frequently,
  and b) their use promotes a certain amount of "common" look and feel.

  All of these components are typically added/modified via the helper functions in the
  [`Scenic.Components`](Scenic.Components.html) module.

  * [`Button`](Scenic.Component.Button.html) a simple button.
  * [`Checkbox`](Scenic.Component.Input.Checkbox.html) a checkbox input field. 
  * [`Dropdown`](Scenic.Component.Input.Dropdown.html) a dropdown / select input field.
  * [`RadioGroup`](Scenic.Component.Input.RadioGroup.html) a group of radio button inputs.
  * [`Slider`](Scenic.Component.Input.Slider.html) a slider input.
  * [`TextField`](Scenic.Component.Input.TextField.html) a text / password input field.
  * [`Toggle`](Scenic.Component.Input.Toggle.html) an on/off toggle input.

  ## Other Components

  For completeness, Scenic also includes the following standard components. They are used
  by the components above, although you are free to use them as well if they fit your needs.

  * [`Caret`](Scenic.Component.Input.Caret.html) the vertical, blinking, caret line in a text field.
  * [`RadioButton`](Scenic.Component.Input.RadioButton.html) a single radio button in a radio group.

  ## Verifiers

  One of the main differences between a Component and a Scene is the two extra callbacks
  that are used to verify incoming data. Since Components are meant to be reused, you
  should do some basic validation that the data being set up is valid, then provide
  feedback if it isn't.

  ## Optional: No Children

  There is an optimization you can use. If you know for certain that your component
  will not attempt to use any components, you can set `has_children` to `false` like this.

      use Scenic.Component, has_children: false

  Setting `has_children` to `false` this will do two things. First, it won't create
  a dynamic supervisor for this scene, which saves some resources. Second,
  `push_graph/1` goes through a fast pass that doesn't scan the graph for dynamic children.

  For example, the Button component sets `has_children` to `false`.

  This option is available for any Scene, not just components
  """

  alias Scenic.Primitive

  @callback add_to_graph(map, any, list) :: map
  @callback verify(any) :: any
  @callback info(data :: any) :: String.t()

  #  import IEx

  # ===========================================================================
  defmodule Error do
    @moduledoc false

    defexception message: nil, error: nil, data: nil
  end

  # ===========================================================================
  defmacro __using__(opts) do
    quote do
      @behaviour Scenic.Component

      use Scenic.Scene, unquote(opts)

      @spec add_to_graph(graph :: Scenic.Graph.t(), data :: any, opts :: list) :: Scenic.Graph.t()
      def add_to_graph(graph, data \\ nil, opts \\ [])

      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        verify!(data)
        Primitive.SceneRef.add_to_graph(graph, {__MODULE__, data}, opts)
      end

      @doc false
      @spec info(data :: any) :: String.t()
      def info(data) do
        """
        #{inspect(__MODULE__)} invalid add_to_graph data
        Received: #{inspect(data)}
        """
      end

      @doc false
      @spec verify!(data :: any) :: any
      def verify!(data) do
        case verify(data) do
          {:ok, data} -> data
          err -> raise Error, message: info(data), error: err, data: data
        end
      end

      # --------------------------------------------------------
      defoverridable add_to_graph: 3,
                     info: 1
    end

    # quote
  end

  # defmacro
end
