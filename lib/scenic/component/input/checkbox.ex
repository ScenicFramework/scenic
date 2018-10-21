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

  Buttons honor the following standard styles

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
  alias Scenic.ViewPort
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives

  # import IEx

  @default_font :roboto
  @default_font_size 20

  # @default_width     140
  # @default_height    16
  # @default_radius    3

  # --------------------------------------------------------
  @doc false
  def info(data) do
    """
    #{IO.ANSI.red()}Checkbox data must be: {text, checked?}
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  @doc false
  def verify({text, checked} = data) when is_bitstring(text) and is_boolean(checked) do
    {:ok, data}
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  @doc false
  def init({text, checked?}, opts) do
    id = opts[:id]
    styles = opts[:styles]

    # theme is passed in as an inherited style
    theme =
      (styles[:theme] || Theme.preset(:primary))
      |> Theme.normalize()

    # get button specific styles
    # width = styles[:width] || @default_width
    # height = styles[:height] || @default_height
    # radius = styles[:radius] || @default_radius
    # font = styles[:component_font] || @default_font
    # font_size = styles[:component_font_size] || @default_font_size
    # alignment = styles[:component_align] || @default_alignment

    graph =
      Graph.build(font: @default_font, font_size: @default_font_size)
      |> group(
        fn graph ->
          graph
          |> rect({140, 16}, fill: :clear, translate: {-2, -2})
          |> rrect({16, 16, 3},
            fill: theme.background,
            stroke: {2, theme.border},
            id: :box,
            translate: {-2, -2}
          )
          |> group(
            fn graph ->
              graph
              # this is the checkmark
              |> path(
                [
                  {:move_to, 1, 7},
                  {:line_to, 5, 10},
                  {:line_to, 10, 1}
                ],
                stroke: {2, theme.thumb},
                join: :round
              )
            end,
            id: :chx,
            hidden: !checked?
          )
        end,
        translate: {0, -11}
      )
      |> text(text, fill: theme.text, translate: {20, 0})

    state = %{
      graph: graph,
      theme: theme,
      pressed: false,
      contained: false,
      checked: checked?,
      id: id
    }

    push_graph(graph)

    {:ok, state}
  end

  # --------------------------------------------------------
  @doc false
  def handle_input({:cursor_enter, _uid}, _, %{pressed: true} = state) do
    state = Map.put(state, :contained, true)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_exit, _uid}, _, %{pressed: true} = state) do
    state = Map.put(state, :contained, false)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input({:cursor_button, {:left, :press, _, _}}, context, state) do
    state =
      state
      |> Map.put(:pressed, true)
      |> Map.put(:contained, true)

    graph = update_graph(state)

    ViewPort.capture_input(context, [:cursor_button, :cursor_pos])

    {:noreply, %{state | graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input(
        {:cursor_button, {:left, :release, _, _}},
        context,
        %{contained: contained, id: id, pressed: pressed, checked: checked} = state
      ) do
    state = Map.put(state, :pressed, false)

    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    # only do the action if the cursor is still contained in the target
    state =
      case pressed && contained do
        true ->
          checked = !checked
          send_event({:value_changed, id, checked})
          Map.put(state, :checked, checked)

        false ->
          state
      end

    graph = update_graph(state)

    {:noreply, %{state | graph: graph}}
  end

  # --------------------------------------------------------
  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  # ============================================================================
  # internal utilities
  # {text_color, box_background, border_color, pressed_color, checkmark_color}

  defp update_graph(%{
         graph: graph,
         theme: theme,
         pressed: pressed,
         contained: contained,
         checked: checked
       }) do
    graph =
      case pressed && contained do
        true ->
          Graph.modify(graph, :box, &Primitive.put_style(&1, :fill, theme.active))

        false ->
          Graph.modify(graph, :box, &Primitive.put_style(&1, :fill, theme.background))
      end

    case checked do
      true ->
        Graph.modify(graph, :chx, &Primitive.put_style(&1, :hidden, false))

      false ->
        Graph.modify(graph, :chx, &Primitive.put_style(&1, :hidden, true))
    end
    |> push_graph()
  end
end
