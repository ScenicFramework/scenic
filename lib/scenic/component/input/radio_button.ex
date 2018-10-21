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
  alias Scenic.ViewPort
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives, only: [{:rect, 3}, {:circle, 3}, {:text, 3}]

  # import IEx

  # --------------------------------------------------------
  @doc false
  def info(data) do
    """
    #{IO.ANSI.red()}RadioButton data must be: {text, id} or {text, id, checked?}
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  @doc false
  def verify({text, _} = data) when is_bitstring(text) do
    {:ok, data}
  end

  def verify({text, _, checked?} = data) when is_bitstring(text) and is_boolean(checked?) do
    {:ok, data}
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  @doc false
  def init({text, id}, opts) when is_bitstring(text), do: init({text, id, false}, opts)

  def init({text, id, checked?}, opts) do
    styles = opts[:styles]

    # theme is passed in as an inherited style
    theme =
      (styles[:theme] || Theme.preset(:dark))
      |> Theme.normalize()

    graph =
      Graph.build(font: :roboto, font_size: 16)
      |> Primitive.Group.add_to_graph(
        fn graph ->
          graph
          |> rect({140, 16}, fill: :clear, translate: {-2, -2})
          |> circle(8, fill: theme.background, stroke: {2, theme.border}, id: :box, t: {6, 6})
          |> circle(5, fill: theme.thumb, id: :chx, hidden: !checked?, t: {6, 6})
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
  def handle_cast({:set_to_msg, set_id}, %{id: id} = state) do
    state = Map.put(state, :checked, set_id == id)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  # --------------------------------------------------------
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
  @doc false
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
        %{contained: contained, id: id, pressed: pressed} = state
      ) do
    state = Map.put(state, :pressed, false)

    ViewPort.release_input(context, [:cursor_button, :cursor_pos])

    # only do the action if the cursor is still contained in the target
    if pressed && contained do
      send_event({:click, id})
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
