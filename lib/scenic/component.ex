#
#  Created by Boyd Multerer on 2018-03-26.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Component do
  @moduledoc """
  A Component is Scene that is optimized to be used as a child of another scene.

  These are typically controls that you want to define once and use in multiple places.

  ## Standard Components

  Scenic includes a several standard components that you can use in your
  scenes. These were chosen to be in the main library because:
    * They are used frequently
    * Their use promotes a certain amount of "common" look and feel

  All of these components are typically added/modified via the helper functions in the
  [`Scenic.Components`](Scenic.Components.html) module.

  | Helper | Component Module | Description |
  |---|---|---|
  | [`button/3`](Scenic.Components.html#button/3) | `Scenic.Component.Button` | A simple button |
  | [`checkbox/3`](Scenic.Components.html#checkbox/3) | `Scenic.Component.Input.Checkbox` | A boolean checkbox control |
  | [`dropdown/3`](Scenic.Components.html#dropdown/3) | `Scenic.Component.Input.Dropdown` | A menu-like dropdown control |
  | [`radio_group/3`](Scenic.Components.html#radio_group/3) | `Scenic.Component.Input.RadioGroup` | A group of radio controls |
  | [`slider/3`](Scenic.Components.html#slider/3) | `Scenic.Component.Input.Slider` | A slider ranging from one value to another |
  | [`text_field/3`](Scenic.Components.html#text_field/3) | `Scenic.Component.Input.TextField` | A text input field. |
  | [`toggle/3`](Scenic.Components.html#toggle/3) | `Scenic.Component.Input.Toggle` | A boolean toggle control. |

  ```elixir
  defmodule MyApp.Scene.MyScene do
    use Scenic.Scene
    import Scenic.Components

    @impl Scenic.Scene
    def init(scene, text, opts) do
      graph =
        Scenic.Graph.build()
        |> button( "Press Me", id: :press_me )
        |> slider( {{0,100}, 0}, id: :slide_me )

      { :ok, push_graph(scene, graph) }
    end
  end
  ```

  ## Creating Custom Components

  Creating a custom component that you can use in your scenes is just like creating a scene
  with an extra validation function. This validation function is used when the graph that 
  uses your component is built in order to make sure it uses data that conforms to what your
  component expects.

  ```elixir
    defmodule MyApp.Component.Fancy do
      use Scenic.Component

      @impl Scenic.Component
      def validate(data) when is_bitstring(data), do: {:ok, data}
      def validate(_), do: {:error, "Descriptive error message goes here."}

      @impl Scenic.Scene
      def init(scene, data, opts) do
        { :ok, scene }
      end
    end
  ```

  ## Generating/Sending Events

  Communication from a component to it's parent is usually done via event messages. Scenic knows how
  to route events to a component's parent. If that parent doesn't handle it, then it is automatically
  routed to the parent's parent. If it gets all the way to the ViewPort itself, then it is ignored.

  ```elixir
    defmodule MyApp.Component.Fancy do
      
    # ... validate, and other setup ...

      @impl Scenic.Scene
      def init(scene, data, opts) do
        # setup and push a graph here...
        { :ok, assign(scene, id: opts[:id] }
      end

      @impl Scenic.Scene
      def handle_input( {:cursor_button, {0, :release, _, _}}, :btn,
            %Scene{assigns: %{id: id}} = scene
          ) do
        :ok = send_parent_event( scene, {:click, id}  )
        { :noreply, scene }
      end

    end
  ```

  Notice how the component saved the original `id` that was passed in to the `init` function via
  the `opts` list. This is then used to identify the click to the parent. This is a common pattern. 


  ## Optional: Fetch/Put Handlers

  If you would like the parent scene to be able to query your component's state without waiting
  for the component to send events, you can optionally implement the following handle_call functions.

  This is an "informal" spec... You don't have to implement it, but it is nice when you do.

  ```elixir
  defmodule MyApp.Component.Fancy do
    use Scenic.Component
    
    # ... init, validate, and other functions ...

    def handle_call(:fetch, _, %{assigns: %{value: value}} = scene) do
      { :reply, {:ok, value}, scene }
    end

    def handle_call({:put, value}, _, scene) when is_bitstring(value) do
      { :reply, :ok, assign(scene, value: value) }
    end

    def handle_call({:put, _}, _, scene) do
      {:reply, {:error, :invalid}, scene}
    end
  end
  ```

  To make the above example more practical, you would probably also modify and push a graph when
  handling the `:put` message. See the code for the standard input components for deeper examples.


  ## Optional: `has_children: false`

  If you know for certain that your component will not itself use any components, you can
  set `:has_children` to `false` like this.

  ```elixir
  defmodule MyApp.Component.Fancy do
    use Scenic.Component, has_children: false
    # ...
  end
  ```

  When `:has_children` is set to `false`, no `DynamicSupervisor` is started to manage the
  scene's children, overall resource use is improved, and startup time is faster. You will not,
  however, be able to nested components in any scene where `:has_children` is `false`.

  For example, the `Scenic.Component.Button` component sets `:has_children` to `false`.

  This option is available for any Scene, not just components.
  """

  alias Scenic.Primitive

  @doc """
  Add this component to a Graph.

  A standard `add_to_graph/3` is automatically added to your component. Override this
  callback if you want to customize it.
  """
  @callback add_to_graph(graph :: Scenic.Graph.t(), data :: any, opts :: Keyword.t()) ::
              Scenic.Graph.t()

  @doc """
  Validate that the data for a component is correctly formed.

  This callback is required. 
  """
  @callback validate(data :: any) :: {:ok, data :: any} | {:error, String.t()}

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
    :cap,
    :fill,
    :font,
    :font_size,
    :hidden,
    :input,
    :join,
    :line_height,
    :miter_limit,
    :scissor,
    :stroke,
    :text_align,
    :text_base,
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
end
