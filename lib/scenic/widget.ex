defmodule Scenic.Widget do
  @moduledoc """
  A Widget is a bounds-aware Component.

  Where a Component is a "small scene managed by another scene", a Widget goes
  further: it receives allocated space (`bounds`) as part of its data and renders
  within those bounds. A Widget doesn't know or care if it's the root of a
  viewport or nested 5 levels deep — same abstraction at every level.

  ## The Browser Analogy

  In a browser, a `<div>` doesn't know its container. It receives available space
  from the layout engine and renders within it. Scenic Widgets work the same way:

  | Browser         | Scenic Widget                |
  |-----------------|------------------------------|
  | CSS box model   | `bounds` map in data         |
  | `resize` event  | `handle_bounds_change/2`     |
  | React `render`  | `render/1` callback          |
  | DOM element     | Scenic primitive tree        |

  ## Usage

      defmodule MyApp.Panel do
        use Scenic.Widget

        @impl Scenic.Widget
        def validate(%{bounds: %{w: w, h: h}} = data) when w > 0 and h > 0 do
          {:ok, data}
        end
        def validate(_), do: {:error, "Panel requires bounds with positive w and h"}

        @impl Scenic.Widget
        def init_widget(scene, data, _opts) do
          {:ok, assign(scene, data: data)}
        end

        @impl Scenic.Widget
        def render(assigns) do
          %{data: %{bounds: %{w: w, h: h}}} = assigns

          Scenic.Graph.build()
          |> Scenic.Primitives.rect({w, h}, fill: :steel_blue)
          |> Scenic.Primitives.text("Hello",
            translate: {w / 2, h / 2},
            text_align: :center,
            fill: :white
          )
        end
      end

  ## Adding to a Parent Graph

      MyApp.Panel.add_to_graph(graph,
        %{bounds: %{x: 0, y: 0, w: 400, h: 300}, title: "My Panel"},
        id: :my_panel,
        translate: {100, 50}
      )

  ## Bounds

  Bounds are a simple map with at minimum `w` (width) and `h` (height):

      %{w: 400, h: 300}             # Size only (position via :translate opt)
      %{x: 100, y: 50, w: 400, h: 300}  # Position + size (for layout engines)

  The `x` and `y` fields are optional — many widgets only need `w` and `h`
  and let the parent position them via Scenic's `:translate` style.

  ## Lifecycle

  1. Parent adds widget to graph with bounds in data
  2. Widget's `init_widget/3` is called — set up state, push initial graph
  3. Parent rebuilds graph with new bounds (e.g., on resize)
  4. `manage_children` detects the change, sends `{:_update_}`
  5. Widget's `handle_bounds_change/2` fires — re-render with new bounds

  By default, `handle_bounds_change/2` calls `render/1` and pushes the new graph.
  Override it if you need custom logic (e.g., animation, lazy re-render).

  ## Options

  `use Scenic.Widget` accepts all options that `use Scenic.Component` accepts:

      use Scenic.Widget, has_children: false   # No child components
      use Scenic.Widget, has_children: true    # Can nest widgets (default)
  """

  @doc """
  Render the widget's graph from its assigns.

  Called by the default `handle_bounds_change/2` implementation.
  Should return a `Scenic.Graph.t()` built from `assigns.data.bounds`.
  """
  @callback render(assigns :: map()) :: Scenic.Graph.t()

  @doc """
  Handle a bounds change from the parent.

  Called when the parent rebuilds its graph with new bounds for this widget.
  The default implementation calls `render/1` and pushes the new graph.

  Override this if you need custom behavior on resize (e.g., debounce,
  animate, or skip re-render when bounds haven't meaningfully changed).
  """
  @callback handle_bounds_change(
              bounds :: map(),
              scene :: Scenic.Scene.t()
            ) :: {:ok, Scenic.Scene.t()}

  @doc """
  Initialize the widget with its data and options.

  Like `Scenic.Scene.init/3` but with bounds guaranteed in data.
  The scene already has `data` in assigns when this is called.
  """
  @callback init_widget(
              scene :: Scenic.Scene.t(),
              data :: map(),
              opts :: Keyword.t()
            ) :: {:ok, Scenic.Scene.t()}

  @optional_callbacks handle_bounds_change: 2

  # ===========================================================================
  defmacro __using__(opts) do
    quote do
      use Scenic.Component, unquote(opts)
      @behaviour Scenic.Widget

      # ── Scenic.Component callback: validate bounds presence ──
      # Widgets require bounds in their data. Individual widgets add their
      # own validate/1 clause BEFORE this one for custom validation.

      # ── Scenic.Scene callback: init → init_widget ──
      @impl Scenic.Scene
      def init(scene, data, opts) do
        scene = assign(scene, data: data)
        graph = render(scene.assigns)
        scene = scene |> push_graph(graph)
        init_widget(scene, data, opts)
      end

      # ── Scenic.Scene callback: handle_update → detect bounds change ──
      @impl Scenic.Scene
      def handle_update(data, opts, scene) do
        old_data = scene.assigns[:data]
        old_bounds = get_bounds(old_data)
        new_bounds = get_bounds(data)

        scene = assign(scene, data: data)

        if old_bounds != new_bounds do
          handle_bounds_change(new_bounds, scene)
        else
          # Data changed but bounds didn't — still re-render
          graph = render(scene.assigns)
          {:ok, scene |> push_graph(graph)}
        end
      end

      # ── Default callbacks ──

      def handle_bounds_change(_bounds, scene) do
        graph = render(scene.assigns)
        {:ok, scene |> push_graph(graph)}
      end

      def init_widget(scene, _data, _opts), do: {:ok, scene}

      # ── Bounds extraction helper ──
      defp get_bounds(%{bounds: bounds}) when is_map(bounds), do: bounds
      defp get_bounds(_), do: nil

      # ── Allow overrides ──
      defoverridable init_widget: 3,
                     handle_bounds_change: 2,
                     init: 3,
                     handle_update: 3
    end
  end
end
