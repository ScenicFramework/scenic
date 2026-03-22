defmodule Scenic.Widget do
  @moduledoc """
  A Widget is a Frame-aware Component.

  Where a Component is a "small scene managed by another scene", a Widget goes
  further: it receives a `Widgex.Frame` as part of its data — its allocated space.
  A Widget renders within that frame without knowing or caring about its container.
  Same abstraction at every nesting level.

  ## The Browser Analogy

  | Browser         | Scenic Widget                     |
  |-----------------|-----------------------------------|
  | CSS box model   | `Widgex.Frame` (pin + size)       |
  | `resize` event  | `handle_frame_change/2`           |
  | React `render`  | `render/1` callback               |
  | CSS Grid        | `Widgex.Frame.Grid` (layout)      |
  | DOM element     | Scenic primitive tree             |

  ## Usage

      defmodule MyApp.Panel do
        use Scenic.Widget

        @impl Scenic.Widget
        def validate(%{frame: %Widgex.Frame{}} = data), do: {:ok, data}
        def validate(_), do: {:error, "Panel requires a frame"}

        @impl Scenic.Widget
        def render(assigns) do
          %{data: %{frame: frame}} = assigns
          %{width: w, height: h} = frame.size

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

      # Parent computes child frames via Grid or Layout:
      grid = Frame.Grid.new(viewport_frame)
        |> Frame.Grid.rows([40, :auto])
        |> Frame.Grid.columns([1.0])
      cells = Frame.Grid.calculate(grid)
      panel_frame = Frame.Grid.cell_frame(cells, 1, 0)

      MyApp.Panel.add_to_graph(graph,
        %{frame: panel_frame, title: "My Panel"},
        id: :my_panel,
        translate: panel_frame.pin.point
      )

  ## Frame

  Widgets use `Widgex.Frame` — the standard bounds representation across the
  flx ecosystem. A Frame has:
  - `pin` — position (`%{x, y, point: {x, y}}`)
  - `size` — dimensions (`%{width, height, box: {w, h}}`)

  Parents compute child frames using `Widgex.Frame.Grid` (CSS Grid layout),
  `Widgex.Frame.Utils` (splits), or `Scenic.Layout` (simple helpers).

  ## Lifecycle

  1. Parent computes child frames (Grid, Layout, or manual)
  2. Parent adds widget to graph with frame in data
  3. Widget's `init_widget/3` is called — set up state
  4. `render/1` is called — build graph from frame
  5. Parent recomputes frames (e.g., on viewport resize)
  6. `manage_children` detects change → `handle_update` fires
  7. Widget detects frame changed → `handle_frame_change/2` → re-render

  ## Options

      use Scenic.Widget, has_children: false   # Leaf widget (no children)
      use Scenic.Widget, has_children: true    # Container widget (default)
  """

  @doc """
  Render the widget's graph from its assigns.

  Called by the default `handle_frame_change/2`. Returns a `Scenic.Graph.t()`
  built from `assigns.data.frame`.
  """
  @callback render(assigns :: map()) :: Scenic.Graph.t()

  @doc """
  Handle a frame change from the parent.

  Called when the parent provides a new frame (different size or position).
  Default implementation calls `render/1` and pushes the new graph.

  Override for custom resize behavior (debounce, animate, skip unchanged).
  """
  @callback handle_frame_change(
              frame :: struct(),
              scene :: Scenic.Scene.t()
            ) :: {:ok, Scenic.Scene.t()}

  @doc """
  Initialize the widget after the first render.

  Called after `render/1` has been called and the graph pushed. The scene
  already has `data` in assigns. Use this for subscriptions, timers, etc.
  """
  @callback init_widget(
              scene :: Scenic.Scene.t(),
              data :: map(),
              opts :: Keyword.t()
            ) :: {:ok, Scenic.Scene.t()}

  @optional_callbacks handle_frame_change: 2

  # ===========================================================================
  defmacro __using__(opts) do
    quote do
      use Scenic.Component, unquote(opts)
      @behaviour Scenic.Widget

      # ── Scenic.Scene callback: init → render → init_widget ──
      @impl Scenic.Scene
      def init(scene, data, opts) do
        scene = assign(scene, data: data)
        graph = render(scene.assigns)
        scene = scene |> push_graph(graph)
        init_widget(scene, data, opts)
      end

      # ── Scenic.Scene callback: handle_update → detect frame change ──
      @impl Scenic.Scene
      def handle_update(data, _opts, scene) do
        old_frame = get_in(scene.assigns, [:data, :frame])
        new_frame = Map.get(data, :frame)

        scene = assign(scene, data: data)

        if frames_differ?(old_frame, new_frame) do
          handle_frame_change(new_frame, scene)
        else
          # Data changed but frame didn't — still re-render
          graph = render(scene.assigns)
          {:ok, scene |> push_graph(graph)}
        end
      end

      # ── Default callbacks ──

      def handle_frame_change(_frame, scene) do
        graph = render(scene.assigns)
        {:ok, scene |> push_graph(graph)}
      end

      def init_widget(scene, _data, _opts), do: {:ok, scene}

      # ── Frame comparison ──
      # Compares size only — position changes are handled by Scenic's
      # :translate style, not by the widget re-rendering.
      defp frames_differ?(nil, _new), do: true
      defp frames_differ?(_old, nil), do: true
      defp frames_differ?(old, new) do
        old.size != new.size
      end

      # ── Allow overrides ──
      defoverridable init_widget: 3,
                     handle_frame_change: 2,
                     init: 3,
                     handle_update: 3
    end
  end
end
