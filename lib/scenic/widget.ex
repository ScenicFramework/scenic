defmodule Scenic.Widget do
  @moduledoc """
  A Widget is a Frame-aware Component with declarative rendering.

  Where a Component is a "small scene managed by another scene", a Widget goes
  further: it receives a `Widgex.Frame` as part of its data — its allocated space.
  A Widget renders within that frame without knowing or caring about its container.
  Same abstraction at every nesting level.

  ## Rendering Model

  Widgets use a **hybrid immediate/retained** rendering model:

  - **Immediate-style authoring**: `render/1` rebuilds the graph from state every time
    (like React's render function). No manual graph mutation needed.
  - **Retained-mode execution**: the `widget_push/2` function handles how the new graph
    gets applied. By default it uses Scenic's `push_graph` (full replace). Override it
    to use a differ (e.g., ScenicDiff) for incremental updates.

  This gives you the convenience of "re-render from scratch" thinking with the option
  of retained-mode performance when you need it.

  ```elixir
  # Default: full graph push (simple, correct)
  defp widget_push(scene, graph), do: push_graph(scene, graph)

  # Override for diff-based updates (efficient for complex graphs):
  defp widget_push(scene, graph), do: ScenicDiff.push(scene, graph)
  ```

  ## The Browser/React Analogy

  | Browser/React         | Scenic Widget                     |
  |-----------------------|-----------------------------------|
  | CSS box model         | `Widgex.Frame` (pin + size)       |
  | `resize` observer     | `handle_frame_change/2`           |
  | `render()`            | `render/1` callback (pure)        |
  | Virtual DOM diff      | `widget_push/2` (configurable)    |
  | CSS Grid              | `Widgex.Frame.Grid`               |
  | Render props / slots  | `render_item` function injection  |
  | `useEffect([], ...)`  | `init_widget/3`                   |

  ## Usage

      defmodule MyApp.Panel do
        use Scenic.Widget

        @impl Scenic.Component
        def validate(%{frame: %Widgex.Frame{}} = data), do: {:ok, data}
        def validate(_), do: {:error, "Panel requires a frame"}

        @impl Scenic.Widget
        def render(assigns) do
          %{data: %{frame: frame}} = assigns
          %{width: w, height: h} = frame.size

          Scenic.Graph.build()
          |> Scenic.Primitives.rect({w, h}, fill: :steel_blue)
        end

        # Opt into diff-based rendering:
        # defp widget_push(scene, graph), do: ScenicDiff.push(scene, graph)
      end

  ## Lifecycle

  1. Parent computes child frames (Grid, Layout, or manual)
  2. Parent adds widget to graph with frame in data
  3. Widget's `render/1` builds initial graph → pushed via `widget_push/2`
  4. Widget's `init_widget/3` runs (subscriptions, timers, etc.)
  5. Parent provides new frame → `handle_frame_change/2` → re-render
  6. Data changes (same frame) → `handle_update` → re-render

  ## Options

      use Scenic.Widget, has_children: false   # Leaf widget (no children)
      use Scenic.Widget, has_children: true    # Container widget (default)
  """

  @doc """
  Render the widget's graph from its assigns. Pure function: assigns → Graph.
  """
  @callback render(assigns :: map()) :: Scenic.Graph.t()

  @doc """
  Handle a frame change. Default calls `render/1` and pushes via `widget_push/2`.
  Override for custom resize behavior (debounce, animate, skip).
  """
  @callback handle_frame_change(
              frame :: struct(),
              scene :: Scenic.Scene.t()
            ) :: {:ok, Scenic.Scene.t()}

  @doc """
  Initialize after first render. For subscriptions, timers, one-time setup.
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
        scene = widget_push(scene, graph)
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
          {:ok, widget_push(scene, graph)}
        end
      end

      # ── Default callbacks ──

      def handle_frame_change(_frame, scene) do
        graph = render(scene.assigns)
        {:ok, widget_push(scene, graph)}
      end

      def init_widget(scene, _data, _opts), do: {:ok, scene}

      # ── Graph push strategy ──
      # Default: Scenic's push_graph (full replace, simple, always correct).
      # Override to use ScenicDiff.push for diff-based updates on complex graphs.
      defp widget_push(scene, graph) do
        push_graph(scene, graph)
      end

      # ── Frame comparison ──
      # Size-only — position changes handled by Scenic's :translate.
      defp frames_differ?(nil, _new), do: true
      defp frames_differ?(_old, nil), do: true
      defp frames_differ?(old, new), do: old.size != new.size

      # ── Allow overrides ──
      defoverridable init_widget: 3,
                     handle_frame_change: 2,
                     widget_push: 2,
                     init: 3,
                     handle_update: 3
    end
  end
end
