defmodule Scenic.Component.Button do
  @moduledoc false

  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives, only: [{:rrect, 3}, {:text, 3}, {:update_opts, 2}]

  # import IEx

  @default_width 80
  @default_height 30
  @default_radius 3

  @default_font :roboto
  @default_font_size 20
  @default_alignment :center

  # --------------------------------------------------------
  def info(data) do
    """
    #{IO.ANSI.red()}Button data must be a bitstring: initial_text
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  def verify(text) when is_bitstring(text), do: {:ok, text}
  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  def init(text, opts) when is_bitstring(text) and is_list(opts) do
    id = opts[:id]
    styles = opts[:styles]

    # theme is passed in as an inherited style
    theme =
      (styles[:theme] || Theme.preset(:primary))
      |> Theme.normalize()

    # get button specific styles
    width = styles[:width] || @default_width
    height = styles[:height] || @default_height
    radius = styles[:radius] || @default_radius
    font = styles[:button_font] || @default_font
    font_size = styles[:button_font_size] || @default_font_size
    alignment = styles[:alignment] || @default_alignment

    # build the graph

    graph =
      Graph.build(font: font, font_size: font_size)
      |> rrect({width, height, radius}, fill: theme.background, id: :btn)
      |> do_aligned_text(alignment, text, theme.text, width, height)

    # special case the dark and light themes to show an outline
    graph = do_special_theme_outline(styles[:theme], graph, theme.border)

    state = %{
      graph: graph,
      theme: theme,
      pressed: false,
      contained: false,
      align: alignment,
      id: id
    }

    push_graph(graph)

    {:ok, state}
  end

  defp do_aligned_text(graph, :center, text, fill, width, height) do
    text(graph, text,
      fill: fill,
      translate: {width / 2, height * 0.7},
      text_align: :center,
      id: :title
    )
  end

  defp do_aligned_text(graph, :left, text, fill, _width, height) do
    text(graph, text,
      fill: fill,
      translate: {8, height * 0.7},
      text_align: :left,
      id: :title
    )
  end

  defp do_aligned_text(graph, :right, text, fill, width, height) do
    text(graph, text,
      fill: fill,
      translate: {width - 8, height * 0.7},
      text_align: :right,
      id: :title
    )
  end

  defp do_special_theme_outline(:dark, graph, border) do
    Graph.modify(graph, :btn, &update_opts(&1, stroke: {1, border}))
  end

  defp do_special_theme_outline(:light, graph, border) do
    Graph.modify(graph, :btn, &update_opts(&1, stroke: {1, border}))
  end

  defp do_special_theme_outline(_, graph, _border) do
    graph
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_enter, _uid},
        _context,
        %{
          pressed: true
        } = state
      ) do
    state = Map.put(state, :contained, true)
    update_color(state)
    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_exit, _uid},
        _context,
        %{
          pressed: true
        } = state
      ) do
    state = Map.put(state, :contained, false)
    update_color(state)
    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_button, {:left, :press, _, _}}, context, state) do
    state =
      state
      |> Map.put(:pressed, true)
      |> Map.put(:contained, true)

    update_color(state)

    ViewPort.capture_input(context, [:cursor_button, :cursor_pos])

    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_button, {:left, :release, _, _}},
        context,
        %{pressed: pressed, contained: contained, id: id} = state
      ) do
    state = Map.put(state, :pressed, false)
    update_color(state)

    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    if pressed && contained do
      send_event({:click, id})
    end

    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  # ============================================================================
  # internal utilities

  defp update_color(%{graph: graph, theme: theme, pressed: false, contained: false}) do
    Graph.modify(graph, :btn, fn p ->
      p
      |> Primitive.put_style(:fill, theme.background)
    end)
    |> push_graph()
  end

  defp update_color(%{graph: graph, theme: theme, pressed: false, contained: true}) do
    Graph.modify(graph, :btn, fn p ->
      p
      |> Primitive.put_style(:fill, theme.background)
    end)
    |> push_graph()
  end

  defp update_color(%{graph: graph, theme: theme, pressed: true, contained: false}) do
    Graph.modify(graph, :btn, fn p ->
      p
      |> Primitive.put_style(:fill, theme.background)
    end)
    |> push_graph()
  end

  defp update_color(%{graph: graph, theme: theme, pressed: true, contained: true}) do
    Graph.modify(graph, :btn, fn p ->
      Primitive.put_style(p, :fill, theme.active)
    end)
    |> push_graph()
  end
end
