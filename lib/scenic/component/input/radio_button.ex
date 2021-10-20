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

  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Style.Theme
  alias Scenic.Assets.Static

  require Logger

  import Scenic.Primitives

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
      |> update_highlight(theme, Scene.get(scene, :pressed, false))

    scene =
      scene
      |> assign(
        graph: graph,
        theme: theme,
        checked?: checked?,
        text: text,
        id: id
      )
      |> assign_new(pressed: false)
      |> push_graph(graph)

    {:ok, scene}
  end

  @impl Scenic.Component
  def bounds({text, _id, _chk}, _styles) when is_bitstring(text) do
    {:ok, {Static.Font, fm}} = Static.meta(@default_font)
    ascent = FontMetrics.ascent(@default_font_size, fm)
    descent = FontMetrics.descent(@default_font_size, fm)
    fm_width = FontMetrics.width(text, @default_font_size, fm)
    space_width = FontMetrics.width(' ', @default_font_size, fm)
    box_width = fm_width + ascent + space_width + @border_width
    {0, 0, box_width, ascent - descent}
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
  def handle_input(
        {:cursor_button, {:btn_left, 1, _, _}},
        :btn,
        %{assigns: %{graph: graph, theme: theme}} = scene
      ) do
    :ok = capture_input(scene, [:cursor_button])

    graph = update_highlight(graph, theme, true)

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
        {:cursor_button, {:btn_left, 1, _, _}},
        _id,
        %{assigns: %{graph: graph, theme: theme}} = scene
      ) do
    :ok = release_input(scene)

    graph = update_highlight(graph, theme, false)

    scene =
      scene
      |> assign(graph: graph, pressed: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # released inside the button
  def handle_input(
        {:cursor_button, {:btn_left, 0, _, _}},
        :btn,
        %{assigns: %{pressed: pressed, id: id, graph: graph, theme: theme}} = scene
      ) do
    :ok = release_input(scene)

    if pressed do
      :ok = send_parent_event(scene, {:click, id})
    end

    graph = update_highlight(graph, theme, false)

    scene =
      scene
      |> assign(graph: graph, pressed: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # released outside the button
  # only happens when input is captured
  def handle_input(
        {:cursor_button, {:btn_left, 0, _, _}},
        _id,
        %{assigns: %{graph: graph, theme: theme}} = scene
      ) do
    :ok = release_input(scene)

    graph = update_highlight(graph, theme, false)

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

  # ============================================================================
  # internal utilities

  # --------------------------------------------------------
  defp update_highlight(graph, theme, pressed)

  defp update_highlight(graph, theme, true) do
    Graph.modify(graph, :box, &update_opts(&1, fill: theme.active))
  end

  defp update_highlight(graph, theme, _) do
    Graph.modify(graph, :box, &update_opts(&1, fill: theme.background))
  end

  # --------------------------------------------------------
  defp update_check(graph, true) do
    Graph.modify(graph, :chx, &Primitive.put_style(&1, :hidden, false))
  end

  defp update_check(graph, false) do
    Graph.modify(graph, :chx, &Primitive.put_style(&1, :hidden, true))
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def handle_get(_, %{assigns: %{checked?: checked?}} = scene) do
    {:reply, checked?, scene}
  end

  @doc false
  @impl Scenic.Scene
  def handle_put(chk?, %{assigns: %{checked: checked}} = scene) when chk? == checked do
    # no change
    {:noreply, scene}
  end

  def handle_put(chk?, %{assigns: %{graph: graph, id: id}} = scene) when is_boolean(chk?) do
    send_parent_event(scene, {:value_changed, id, chk?})

    graph = update_check(graph, chk?)

    scene =
      scene
      |> assign(graph: graph, checked?: chk?)
      |> push_graph(graph)

    {:noreply, scene}
  end

  def handle_put(v, %{assigns: %{id: id}} = scene) do
    Logger.warn(
      "Attempted to put an invalid value on Radio Button id: #{inspect(id)}, value: #{inspect(v)}"
    )

    {:noreply, scene}
  end

  @doc false
  @impl Scenic.Scene
  def handle_fetch(_, %{assigns: %{text: text, id: id, checked?: checked?}} = scene) do
    {:reply, {:ok, {text, id, checked?}}, scene}
  end
end
