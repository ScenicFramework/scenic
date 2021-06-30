#
#  Created by Boyd Multerer on 2018-03-26.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
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

  ## Optional: Named Component

  Whether you override one or more message handlers, like `handle_info/2`,
  you might want to use registered name as
  [`Process.dest()`](https://hexdocs.pm/elixir/Process.html?#t:dest/0).
  For this to be possible, you might pass `name:` keyword argument in a call
  to `use Scenic.Component`.

      use Scenic.Component, name: __MODULE__

  Once passed, it limits the usage of this particular component to
  a single instance, because two processes cannot be registered under the same name.

  ## Optional: No Children

  There is an optimization you can use. If you know for certain that your component
  will not attempt to use any components, you can set `has_children` to `false` like this.

      use Scenic.Component, has_children: false

  Setting `has_children` to `false` this will do two things. First, it won't create
  a dynamic supervisor for this scene, which saves some resources.

  For example, the Button component sets `has_children` to `false`.

  This option is available for any Scene, not just components
  """

  alias Scenic.Primitive

  # @optional_callbacks add_to_graph: 3, info: 1

  @doc """
  Add this component to a `Scenic.Graph`
  """
  @callback add_to_graph(graph :: Scenic.Graph.t(), data :: any, opts :: Keyword.t()) ::
              Scenic.Graph.t()

  @doc """
  Validate that the data for a component is correctly formed
  """
  @callback validate(data :: any) :: {:ok, data :: any} | {:error, String.t()}

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

      def add_to_graph(graph, data, opts \\ [])

      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        Primitive.Component.add_to_graph(graph, {__MODULE__, data}, opts)
      end

      # --------------------------------------------------------
      defoverridable add_to_graph: 3
    end

    # quote
  end

  # defmacro

  @filter_out [
    :input,
    :hidden,
    :fill,
    :stroke,
    :stroke_width,
    :join,
    :cap,
    :miter_limit,
    :font,
    :font_size,
    :text_align,
    :text_base,
    :text_height,
    :scissor,
    :translate,
    :scale,
    :rotate,
    :pin,
    :matrix
  ]

  # prepare the list of opts to send to a component as it is being started up
  # the main task is to remove styles that have already been consumed or don't make
  # sense, while leaving any opts/styles that are intended for the component itself.
  # also, add the viewport as an option.
  @doc false
  def filter_opts(opts) when is_list(opts) do
    Enum.reject(opts, fn {key, _} -> Enum.member?(@filter_out, key) end)
  end

  @spec fetch(component_pid :: pid) :: {:ok, any} | {:error, atom}
  def fetch(component_pid) do
    GenServer.call(component_pid, :fetch)
  end

  @spec put(component_pid :: pid, value :: any) :: :ok | {:error, atom}
  def put(component_pid, value) do
    GenServer.call(component_pid, {:put, value}, 5_000_000)
  end
end
