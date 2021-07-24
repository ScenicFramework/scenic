defmodule Scenic.Component.Input.Checkbox do
  @moduledoc """
  Add a checkbox to a graph

  ## Data

  `{text, checked?}`

  * `text` - must be a bitstring
  * `checked?` - must be a boolean and indicates if the checkbox is set.

  ## Messages

  When the state of the checkbox, it sends an event message to the host scene
  in the form of:

  `{:value_changed, id, checked?}`

  ## Styles

  Buttons honor the following styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:dark`

  ## Theme

  Checkboxes work well with the following predefined themes: `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text in the button
  * `:background` - the background of the box
  * `:border` - the border of the box
  * `:active` - the border of the box while the button is pressed
  * `:thumb` - the color of the check mark itself

  ## Usage

  You should add/modify components via the helper functions in
  [`Scenic.Components`](Scenic.Components.html#checkbox/3)

  ### Examples

  The following example creates a checkbox and positions it on the screen.

      graph
      |> checkbox({"Example", true}, id: :checkbox_id, translate: {20, 20})
  """

  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Style.Theme
  alias Scenic.Script
  alias Scenic.Assets.Static

  import Scenic.Primitives

  # import IEx

  @default_font :roboto
  @default_font_size 20

  @border_width 2

  # --------------------------------------------------------
  @impl Scenic.Component
  def validate({text, checked}) when is_bitstring(text) and is_boolean(checked) do
    {:ok, {text, checked}}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Checkbox specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a Checkbox is {text, checked?}#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def init(scene, {text, checked?}, opts) do
    id = opts[:id]

    # theme is passed in as an inherited style
    theme =
      (opts[:theme] || Theme.preset(:dark))
      |> Theme.normalize()

    # font related info
    {:ok, {Static.Font, fm}} = Static.fetch(@default_font)
    ascent = FontMetrics.ascent(@default_font_size, fm)
    fm_width = FontMetrics.width(text, @default_font_size, fm)
    space_width = FontMetrics.width(' ', @default_font_size, fm)
    # box_width = fm_width + ascent + space_width * 2 + @border_width

    box_height = ascent
    box_width = fm_width + box_height + space_width + @border_width

    # build the checkmark script
    # I'd build it at compile time if it weren't for the theme.thumb color...
    chx_script =
      Script.start()
      |> Script.push_state()
      |> Script.join(:round)
      |> Script.stroke_width(@border_width + 1)
      |> Script.stroke_color(theme.thumb)
      |> Script.begin_path()
      |> Script.move_to(0, 8)
      |> Script.line_to(5, 13)
      |> Script.line_to(12, 1)
      |> Script.stroke_path()
      |> Script.pop_state()
      |> Script.finish()

    scene = push_script(scene, chx_script, :__check_mark)

    # tune final position
    dx = @border_width / 2
    dy = @border_width / 2

    graph =
      Graph.build(font: @default_font, font_size: @default_font_size, t: {dx, dy})
      |> group(fn graph ->
        graph
        |> rect(
          {box_width, box_height},
          id: :btn,
          input: true
        )
        |> rrect({box_height, box_height, 3},
          fill: theme.background,
          stroke: {@border_width, theme.border},
          id: :box
        )
        |> script(:__check_mark, id: :chx, hidden: !checked?, t: {3, 2})
      end)
      |> text(text,
        fill: theme.text,
        translate: {box_height + space_width + @border_width, ascent - @border_width}
      )

    scene =
      scene
      |> assign(
        graph: graph,
        theme: theme,
        pressed: false,
        checked: checked?,
        id: id
      )
      |> push_graph(graph)

    {:ok, scene}
  end

  # --------------------------------------------------------
  # pressed in the button
  @impl Scenic.Scene
  def handle_input(
        {:cursor_button, {0, :press, _, _}},
        :btn,
        %{assigns: %{graph: graph, theme: theme}} = scene
      ) do
    :ok = capture_input(scene, :cursor_button)

    graph = Graph.modify(graph, :box, &Primitive.put_style(&1, :fill, theme.active))

    scene =
      scene
      |> assign(graph: graph, pressed: true)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # pressed outside the button
  # only happens when input is captured
  # could happen when reconnecting to a driver...
  def handle_input(
        {:cursor_button, {0, :press, _, _}},
        _id,
        %{assigns: %{graph: graph, theme: theme}} = scene
      ) do
    :ok = release_input(scene)

    graph = Graph.modify(graph, :box, &Primitive.put_style(&1, :fill, theme.background))

    scene =
      scene
      |> assign(graph: graph, pressed: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # released inside the button while pressed
  def handle_input(
        {:cursor_button, {0, :release, _, _}},
        :btn,
        %{
          assigns: %{
            pressed: true,
            id: id,
            graph: graph,
            checked: checked,
            theme: theme
          }
        } = scene
      ) do
    :ok = release_input(scene)
    send_parent_event(scene, {:value_changed, id, !checked})

    graph =
      graph
      |> Graph.modify(:box, &Primitive.put_style(&1, :fill, theme.background))
      |> Graph.modify(:chx, &Primitive.put_style(&1, :hidden, checked))

    scene =
      scene
      |> assign(graph: graph, checked: !checked, pressed: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # released either outside the button or when not pressed
  # only happens when input is captured
  def handle_input(
        {:cursor_button, {0, :release, _, _}},
        _id,
        %{assigns: %{graph: graph, theme: theme}} = scene
      ) do
    :ok = release_input(scene)

    graph = Graph.modify(graph, :box, &Primitive.put_style(&1, :fill, theme.background))

    scene =
      scene
      |> assign(graph: graph, pressed: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # ignore other button press events
  def handle_input({:cursor_button, {_, _, _, _}}, _id, scene) do
    {:noreply, scene}
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Component
  def handle_fetch( _, %{assigns: %{checked: checked?}} = scene) do
    {:reply, {:ok, checked?}, scene}
  end

  @doc false
  @impl Scenic.Component
  def handle_put(checked?, _, %{assigns: %{graph: graph}} = scene) when is_boolean(checked?) do
    graph = Graph.modify(graph, :chx, &Primitive.put_style(&1, :hidden, checked?))

    scene =
      scene
      |> assign(graph: graph, checked: checked?)
      |> push_graph(graph)

    {:reply, :ok, scene}
  end

  def handle_put(_, _, scene) do
    {:reply, {:error, :invalid}, scene}
  end
end
