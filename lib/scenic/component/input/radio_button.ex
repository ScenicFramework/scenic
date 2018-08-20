defmodule Scenic.Component.Input.RadioButton do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Primitive.Style.Paint.Color
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives, only: [{:rect, 3}, {:circle, 3}, {:text, 3}]

  # import IEx


#  #--------------------------------------------------------
  def info() do
#    "#{IO.ANSI.red()}RadioButton must be initialized with" <>
#    "{text, message, value, opts}#{IO.ANSI.default_color()}\r\n"
    "help goes here" <>
    "\r\n" <>
    IO.ANSI.default_color()
  end

  #--------------------------------------------------------
  def verify( data ) do
    try do
      {_, _, _, opts} = normalize( data )
      opts
      |> Enum.all?( &verify_option(&1) )
      |> case do
        true -> {:ok, data}
        _ -> :invalid_data
      end
    rescue
      _ -> :invalid_data
    end
  end


  #--------------------------------------------------------
  defp verify_option( {:theme, :light} ), do: true
  defp verify_option( {:theme, :dark} ), do: true
  defp verify_option( {:theme, {text_color, box_background, border_color,
  pressed_color, checkmark_color}} ) do
    Color.verify( text_color ) &&
    Color.verify( box_background ) &&
    Color.verify( border_color ) &&
    Color.verify( pressed_color ) &&
    Color.verify( checkmark_color )
  end

  defp verify_option( _ ), do: false


  #--------------------------------------------------------
  defp normalize( data )

  defp normalize( {text, id} ), do: normalize( {text, id, false, []} )

  defp normalize( {text, id, checked?} ) when is_boolean(checked?) do
    normalize( {text, id, checked?, []} )
  end

  defp normalize( {text, id, opts} ) when is_list(opts) do
    normalize( {text, id, false, opts} )
  end

  defp normalize( {text, _id, checked?, opts} = data) when is_bitstring(text) and
  is_boolean(checked?) and is_list(opts) do
    data
  end


  #--------------------------------------------------------
  def init( data, args ) do
    # normalize the incoming data
    {text, id, checked?, _opts} = normalize( data )

    # theme is passed in as an inherited style
    theme = (args[:styles][:theme] || Theme.preset(:dark))
    |> Theme.normalize()


    graph = Graph.build( font: :roboto, font_size: 16 )
    |> Primitive.Group.add_to_graph(fn(graph) ->
      graph
      |> rect({140, 16}, fill: :clear, translate: {-2,-2})
      |> circle(8, fill: theme.background, stroke: {2, theme.border}, id: :box, t: {6,6})
      |> circle(5, fill: theme.thumb, id: :chx, hidden: !checked?, t: {6,6})
    end, translate: {0, -11})
    |> text(text, fill: theme.text, translate: {20,0})

    state = %{
      graph: graph,
      theme: theme,
      pressed: false,
      contained: false,
      checked: checked?,
      id: id
    }

    push_graph( graph )

    {:ok, state}
  end

  #--------------------------------------------------------
  def handle_cast({:set_value, new_value},  state) do
    state = Map.put( state, :checked, new_value )
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_cast({:set_to_msg, set_id}, %{id: id} = state) do
    state = Map.put( state, :checked, set_id == id )
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_enter, _uid}, _, %{pressed: true} = state ) do
    state = Map.put(state, :contained, true)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, _uid}, _, %{pressed: true} = state ) do
    state = Map.put(state, :contained, false)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :press, _, _}}, context, state ) do
    state = state
    |> Map.put( :pressed, true )
    |> Map.put( :contained, true )
    graph = update_graph(state)

    ViewPort.capture_input( context, [:cursor_button, :cursor_pos])

    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :release, _, _}}, context,
  %{contained: contained, id: id, pressed: pressed} = state ) do
    state = Map.put(state, :pressed, false)

    ViewPort.release_input( context, [:cursor_button, :cursor_pos])

    # only do the action if the cursor is still contained in the target
    if pressed && contained do
      send_event({:click, id})
    end

    graph = update_graph(state)

    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( _event, _context, state ) do
    {:noreply, state}
  end


  #============================================================================
  # internal utilities
  # {text_color, box_background, border_color, pressed_color, checkmark_color}

  defp update_graph( %{
    graph: graph,
    theme: theme,
    pressed: pressed,
    contained: contained,
    checked: checked
  } ) do
    graph = case pressed && contained do
      true ->
        Graph.modify( graph, :box, &Primitive.put_style(&1, :fill, theme.active) )
      false ->
        Graph.modify( graph, :box, &Primitive.put_style(&1, :fill, theme.background) )
    end
    case checked do
      true ->
        Graph.modify( graph, :chx, &Primitive.put_style(&1, :hidden, false) )
      false ->
        Graph.modify( graph, :chx, &Primitive.put_style(&1, :hidden, true) )
    end
    |> push_graph()
  end


end










