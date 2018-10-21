defmodule Scenic.Component.Button do
  @moduledoc """
  Add a button to a graph

  A button is a small scene that is pretty much just some text drawn over a
  rounded rectangle. The button scene contains logic to detect when the button
  is pressed, tracks it as the pointer moves around, and when it is released.

  ## Data

  `title`

  * `title` - a bitstring describing the text to show in the button

  ## Messages

  If a button press is successful, it sends an event message to the host scene
  in the form of:

      {:click, id}

  ## Styles

  Buttons honor the following standard styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:primary`

  ## Additional Styles

  Buttons honor the following list of additional styles.

  * `:width` - pass in a number to set the width of the button.
  * `:height` - pass in a number to set the height of the button.
  * `:radius` - pass in a number to set the radius of the button's rounded
  rectangle.
  * `:alignment` - set the alignment of the text inside the button. Can be one
  of `:left, :right, :center`. The default is `:center`.
  * `:button_font_size` - the size of the font in the button

  Buttons do not use the inherited `:font_size` style as they should look
  consistent regardless of what size the surrounding text is.

  ## Theme

  Buttons work well with the following predefined themes:
  `:primary`, `:secondary`, `:success`, `:danger`, `:warning`, `:info`,
  `:text`, `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text in the button
  * `:background` - the normal background of the button
  * `:active` - the background while the button is pressed

  ## Usage

  You should add/modify components via the helper functions in
  [`Scenic.Components`](Scenic.Components.html#button/3)

  ### Examples

  The following example creates a simple button and positions it on the screen.

      graph
      |> button("Example", id: :button_id, translate: {20, 20})

  The next example makes the same button as before, but colors it as a warning
  button. See the options list above for more details.

      graph
      |> button("Example", id: :button_id, translate: {20, 20}, theme: :warning)
  """
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
  @doc false
  def info(data) do
    """
    #{IO.ANSI.red()}Button data must be a bitstring: initial_text
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  @doc false
  def verify(text) when is_bitstring(text), do: {:ok, text}
  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  @doc false
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
  @doc false
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
