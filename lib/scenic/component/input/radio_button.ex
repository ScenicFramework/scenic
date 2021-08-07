defmodule Scenic.Component.Input.RadioButton do
  @moduledoc """
  Add a single radio button to a graph.

  ## Data

  `{text, id}`
  `{text, id, selected?}`

  * `text` - a bitstring of the text to display
  * `id` - any term. Identifies the radio button.
  * `selected?` - boolean. `true` if selected. `false if not`. Default is `false` if
  this term is not provided.

  ## Usage

  The RadioButton component is used by the RadioGroup component and usually isn't accessed
  directly, although you are free to do so if it fits your needs. There is no short-cut
  helper function so you will need to add it to the graph manually.

  The following example adds a caret to a graph.

      graph
      |> RadioButton.add_to_graph({"A button", :an_id, true})

  """

  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Style.Theme
  alias Scenic.Assets.Static

  import Scenic.Primitives, only: [{:rect, 3}, {:circle, 3}, {:text, 3}]

  # import IEx

  @default_font :roboto
  @default_font_size 20
  @border_width 2

  # --------------------------------------------------------
  @impl Scenic.Component
  def validate({text, id, checked?}) when is_bitstring(text) and is_boolean(checked?) do
    {:ok, {text, id, checked?}}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid RadioButton specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a RadioButton is {text, id, checked?}#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def init(scene, {text, id}, opts) when is_bitstring(text),
    do: init(scene, {text, id, false}, opts)

  def init(scene, {text, id, checked?}, opts) do
    # theme is passed in as an inherited style
    theme =
      (opts[:theme] || Theme.preset(:dark))
      |> Theme.normalize()

    # font related info
    {:ok, {Static.Font, fm}} = Static.meta(@default_font)
    ascent = FontMetrics.ascent(@default_font_size, fm)
    fm_width = FontMetrics.width(text, @default_font_size, fm)
    space_width = FontMetrics.width(' ', @default_font_size, fm)
    outer_radius = ascent * 0.5
    inner_radius = ascent * 0.3125

    box_height = ascent
    box_width = fm_width + box_height + space_width + @border_width

    # tune final position
    # original behavior had the toggle higher up, use :compat for that mode
    {dx, dv} =
      case opts[:compat] do
        true -> {-@border_width, -ascent + @border_width + 1}
        _ -> {@border_width / 2, @border_width / 2}
      end

    graph =
      Graph.build(font: @default_font, font_size: @default_font_size, t: {dx, dv})
      |> Primitive.Group.add_to_graph(fn graph ->
        graph
        |> rect({box_width, box_height}, id: :btn, input: :cursor_button)
        |> circle(
          outer_radius,
          fill: theme.background,
          stroke: {2, theme.border},
          id: :box,
          t: {outer_radius, outer_radius}
        )
        |> circle(
          inner_radius,
          fill: theme.thumb,
          id: :chx,
          hidden: !checked?,
          t: {outer_radius, outer_radius}
        )
      end)
      |> text(
        text,
        fill: theme.text,
        t: {box_height + space_width + @border_width, ascent - @border_width}
      )

    push_graph(scene, graph)

    scene =
      scene
      |> assign(
        graph: graph,
        theme: theme,
        pressed: false,
        checked?: checked?,
        id: id
      )

    {:ok, scene}
  end

  # --------------------------------------------------------
  @doc false
  @impl GenServer
  def handle_cast({:set_to_msg, set_id}, %{assigns: %{id: id, graph: graph}} = scene) do
    graph = update_check(graph, set_id == id)

    scene =
      scene
      |> assign(graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  @doc false

  # --------------------------------------------------------
  # pressed in the button
  @impl Scenic.Scene
  def handle_input({:cursor_button, {0, :press, _, _}}, :btn, scene) do
    scene = update_highlight(true, true, scene)

    :ok = capture_input(scene, [:cursor_button])

    {:noreply, assign(scene, pressed: true)}
  end

  # --------------------------------------------------------
  # pressed outside the button
  # only happens when input is captured
  # could happen when reconnecting to a driver...
  def handle_input({:cursor_button, {0, :press, _, _}}, _id, scene) do
    scene = update_highlight(false, false, scene)

    :ok = release_input(scene)

    {:noreply, assign(scene, pressed: false)}
  end

  # --------------------------------------------------------
  # released inside the button
  def handle_input(
        {:cursor_button, {0, :release, _, _}},
        :btn,
        %{assigns: %{pressed: pressed, id: id}} = scene
      ) do
    :ok = release_input(scene)

    if pressed do
      :ok = send_parent_event(scene, {:click, id})
    end

    scene = update_highlight(false, true, scene)

    {:noreply, assign(scene, pressed: false)}
  end

  # --------------------------------------------------------
  # released outside the button
  # only happens when input is captured
  def handle_input({:cursor_button, {0, :release, _, _}}, _id, scene) do
    scene = update_highlight(false, true, scene)

    :ok = release_input(scene)

    {:noreply, assign(scene, pressed: false)}
  end

  # ignore other button press events
  def handle_input({:cursor_button, {_, _, _, _}}, _id, scene) do
    {:noreply, scene}
  end

  # ============================================================================
  # internal utilities
  # {text_color, box_background, border_color, pressed_color, checkmark_color}

  defp update_highlight(pressed, contained, scene)

  defp update_highlight(true, true, %{assigns: %{graph: graph, theme: theme}} = scene) do
    push_graph(
      scene,
      Graph.modify(graph, :box, &Primitive.put_style(&1, :fill, theme.active))
    )
  end

  defp update_highlight(_, _, %{assigns: %{graph: graph, theme: theme}} = scene) do
    push_graph(
      scene,
      Graph.modify(graph, :box, &Primitive.put_style(&1, :fill, theme.background))
    )
  end

  defp update_check(graph, true) do
    Graph.modify(graph, :chx, &Primitive.put_style(&1, :hidden, false))
  end

  defp update_check(graph, false) do
    Graph.modify(graph, :chx, &Primitive.put_style(&1, :hidden, true))
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def handle_fetch(_, %{assigns: %{checked?: checked?}} = scene) do
    {:reply, {:ok, checked?}, scene}
  end
end
