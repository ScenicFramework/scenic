defmodule Scenic.Component.Input.RadioButton do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Primitive.Style.Paint.Color
  import Scenic.Primitives, only: [{:rect, 3}, {:circle, 3}, {:text, 3}]

  # import IEx


#  @default_width      80
#  @default_height     32
#  @default_radius     6
#  @default_type       6

#  @blue_color         :steel_blue
#  @text_color         :white


  # {text_color, box_background, border_color, pressed_color, checkmark_color}
  @themes %{
    light:    {:black, :white, :dark_grey, {215, 215, 215}, :cornflower_blue},
    dark:     {:white, :black, :light_grey, {40,40,40}, {0x00,0x71,0xBC}},
  }


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
  def init( data, _args ) do
    # normalize the incoming data
    {text, id, checked?, opts} = normalize( data )

    # get the theme
    theme = case opts[:theme] do
      {_,_,_,_,_} = theme -> theme
      type -> Map.get(@themes, type) || Map.get(@themes, :dark)
    end
    {text_color, box_background, border_color, _, checkmark_color} = theme

    graph = Graph.build( font: :roboto, font_size: 16 )
    |> Primitive.Group.add_to_graph(fn(graph) ->
      graph
      |> rect({140, 16}, fill: :clear, translate: {-2,-2})
      |> circle(8, fill: box_background, stroke: {2, border_color}, id: :box, t: {6,6})
      |> circle(5, fill: checkmark_color, id: :chx, hidden: !checked?, t: {6,6})
    end, translate: {0, -11})
    |> text(text, fill: text_color, translate: {20,0})

    state = %{
      graph: graph,
      colors: theme,
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
    colors: {_, box_background, _, pressed_color, _},
    pressed: pressed,
    contained: contained,
    checked: checked
  } ) do
    graph = case pressed && contained do
      true ->
        Graph.modify( graph, :box, &Primitive.put_style(&1, :fill, pressed_color) )
      false ->
        Graph.modify( graph, :box, &Primitive.put_style(&1, :fill, box_background) )
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










