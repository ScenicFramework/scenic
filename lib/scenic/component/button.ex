defmodule Scenic.Component.Button do
  @default_radius 3
  @default_font :roboto
  @default_font_size 20
  @default_alignment :center

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

  These messages can be received and handled in your scene via
  `c:Scenic.Scene.handle_event/3`. For example:

  ```
  ...

  @impl Scenic.Scene
  def init(_, _opts) do
    graph =
      Graph.build()
      |> Scenic.Components.button("Sample Button", id: :sample_btn_id, t: {10, 10})

    state = %{}

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_event({:click, :sample_btn_id}, _from, state) do
    IO.puts("Sample button was clicked!")
    {:cont, event, state}
  end
  ```

  ## Styles

  Buttons honor the following standard styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:primary`

  ## Sendable Styles
  Styles can be sent directly to the Button Component by adding a :styles list.

      graph
      |> button(
        "Example",
        styles: [font_size: 32, text_align: :right]
      )

  The following standard styles are supported

  * `:font` - The default is #{inspect(@default_font)}
  * `:font_size` - The default is #{inspect(@default_font_size)}
  * `:text_align` - The default is #{inspect(@default_alignment)}


  ## Options

  Buttons the following options.

  * `:width` - :auto (default) or pass in a number to set the width of the button
  * `:height` - :auto (default) or pass in a number to set the height of the button.
  * `:radius` - pass in a number to set the radius of the button's rounded
  rectangle. The default is #{inspect(@default_radius)}

  Buttons do not use the inherited `:font_size` style as they should look
  consistent regardless of what size the surrounding text is.

  ## Theme

  Buttons work well with the following predefined themes:
  `:primary`, `:secondary`, `:success`, `:danger`, `:warning`, `:info`,
  `:text`, `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text in the button
  * `:background` - the normal background of the button
  * `:border` - the border of the button
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

  The final example changes the text size and alignment

      graph
      |> button(
        "Example",
        id: :button_id,
        translate: {20, 20},
        theme: :warning,
        styles: [text_size: 32, text_align: :right]
      )

  """
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.Primitive.Style.Theme
  alias Scenic.Assets.Static

  import Scenic.Primitives, only: [{:rrect, 3}, {:text, 3}, {:update_opts, 2}]

  # import IEx
  @impl Scenic.Component
  def validate(text) when is_bitstring(text) do
    {:ok, text}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Button specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a button is just the text string to be displayed in the button.#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def init(scene, text, opts) when is_bitstring(text) and is_list(opts) do
    styles = Keyword.get(opts, :styles, [])
    id = opts[:id]

    # theme is passed in as an inherited style
    theme =
      case opts[:theme] do
        nil -> Theme.preset(:primary)
        :dark -> Theme.preset(:primary)
        :light -> Theme.preset(:primary)
        theme -> theme
      end
      |> Theme.normalize()

    # font related info
    font = Keyword.get(styles, :font, @default_font)
    {:ok, {Static.Font, fm}} = Static.meta(font)
    font_size = Keyword.get(styles, :font_size, @default_font_size)
    alignment = Keyword.get(styles, :text_align, @default_alignment)

    ascent = FontMetrics.ascent(font_size, fm)
    descent = FontMetrics.descent(font_size, fm)
    fm_width = FontMetrics.width(text, font_size, fm)

    width =
      case opts[:width] || opts[:w] do
        nil -> fm_width + ascent + ascent
        :auto -> fm_width + ascent + ascent
        width when is_number(width) and width > 0 -> width
      end

    height =
      case opts[:height] || opts[:h] do
        nil -> font_size + ascent
        :auto -> font_size + ascent
        height when is_number(height) and height > 0 -> height
      end

    radius = opts[:radius] || @default_radius

    vpos = height / 2 + ascent / 2 + descent / 3

    # build the graph
    graph =
      Graph.build(font: font, font_size: font_size)
      |> rrect({width, height, radius}, fill: theme.background, id: :btn, input: :cursor_button)
      |> do_aligned_text(alignment, text, theme.text, width, vpos)
      # special case the dark and light themes to show an outline
      |> do_special_theme_outline(theme, theme.border)
      |> update_color(theme, Scene.get(scene, :pressed, false))

    scene =
      scene
      |> assign(
        vpos: vpos,
        graph: graph,
        theme: theme,
        id: id,
        text: text,
        theme: theme,
        opts: opts
      )
      |> assign_new(pressed: false)
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl Scenic.Component
  def bounds(text, opts) do
    # font related info
    {:ok, {Static.Font, fm}} = Static.meta(@default_font)
    font_size = opts[:button_font_size] || @default_font_size

    ascent = FontMetrics.ascent(font_size, fm)
    fm_width = FontMetrics.width(text, font_size, fm)

    width =
      case opts[:width] || opts[:w] do
        nil -> fm_width + ascent + ascent
        :auto -> fm_width + ascent + ascent
        width when is_number(width) and width > 0 -> width
      end

    height =
      case opts[:height] || opts[:h] do
        nil -> font_size + ascent
        :auto -> font_size + ascent
        height when is_number(height) and height > 0 -> height
      end

    {0.0, 0.0, width, height}
  end

  defp do_aligned_text(graph, :center, text, fill, width, vpos) do
    text(graph, text,
      fill: fill,
      translate: {width / 2, vpos},
      text_align: :center,
      id: :title
    )
  end

  defp do_aligned_text(graph, :left, text, fill, _width, vpos) do
    text(graph, text,
      fill: fill,
      translate: {8, vpos},
      text_align: :left,
      id: :title
    )
  end

  defp do_aligned_text(graph, :right, text, fill, width, vpos) do
    text(graph, text,
      fill: fill,
      translate: {width - 8, vpos},
      text_align: :right,
      id: :title
    )
  end

  defp do_special_theme_outline(graph, :dark, border) do
    Graph.modify(graph, :btn, &update_opts(&1, stroke: {1, border}))
  end

  defp do_special_theme_outline(graph, :light, border) do
    Graph.modify(graph, :btn, &update_opts(&1, stroke: {1, border}))
  end

  defp do_special_theme_outline(graph, _, _border) do
    graph
  end

  # --------------------------------------------------------
  # pressed in the button
  @impl Scenic.Scene
  def handle_input(
        {:cursor_button, {:btn_left, 1, _, _}},
        :btn,
        %Scene{assigns: %{graph: graph, theme: theme}} = scene
      ) do
    :ok = capture_input(scene, :cursor_button)

    graph = update_color(graph, theme, true)

    scene =
      scene
      |> assign(pressed: true)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # pressed outside the button
  # only happens when input is captured
  # could happen when reconnecting to a driver...
  def handle_input(
        {:cursor_button, {:btn_left, 1, _, _}},
        _id,
        %Scene{assigns: %{graph: graph, theme: theme}} = scene
      ) do
    :ok = release_input(scene)

    graph = update_color(graph, theme, false)

    scene =
      scene
      |> assign(pressed: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # released inside the button
  def handle_input(
        {:cursor_button, {:btn_left, 0, _, _}},
        :btn,
        %Scene{assigns: %{pressed: true, id: id, graph: graph, theme: theme}} = scene
      ) do
    :ok = release_input(scene)
    :ok = send_parent_event(scene, {:click, id})

    graph = update_color(graph, theme, false)

    scene =
      scene
      |> assign(pressed: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # released outside the button
  # only happens when input is captured
  def handle_input(
        {:cursor_button, {:btn_left, 0, _, _}},
        _id,
        %Scene{assigns: %{graph: graph, theme: theme}} = scene
      ) do
    :ok = release_input(scene)

    graph = update_color(graph, theme, false)

    scene =
      scene
      |> assign(pressed: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # ignore other input
  def handle_input(_input, _id, scene) do
    {:noreply, scene}
  end

  # ============================================================================
  # internal utilities

  defp update_color(graph, theme, true) do
    Graph.modify(graph, :btn, &update_opts(&1, fill: theme.active))
  end

  defp update_color(graph, theme, _) do
    Graph.modify(graph, :btn, &update_opts(&1, fill: theme.background))
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def handle_fetch(_, %{assigns: %{text: text}} = scene) do
    {:reply, {:ok, text}, scene}
  end
end
