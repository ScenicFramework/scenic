defmodule Scenic.Component.Input.RadioButton do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort

  import IEx


  @default_width      80
  @default_height     32
  @default_radius     6
  @default_type       6

  @blue_color         :steel_blue
  @text_color         :white

  @valid_sizes [:small, :normal, :large]
  @valid_colors [:primary, :secondary, :success, :danger, :warning, :info, :light, :dark, :text]
  @valid_other [:outline]

  # type is {text_color, box_background, border_color, pressed_color, checkmark_color}
  # nil for text_color means to use whatever is inherited
  @colors %{
    light:    {:black, :white, :grey, {215, 215, 215}, :cornflower_blue},
    dark:     {:white, :black, :grey, {40,40,40}, :cornflower_blue},
  }

#  #--------------------------------------------------------
  def info() do
#    "#{IO.ANSI.red()}RadioButton must be initialized with" <>
#    "{text, message, value, opts}#{IO.ANSI.default_color()}\r\n"
    "help goes here"
  end

  #--------------------------------------------------------
  def valid?( {text, msg, value} ), do: valid?( {text, msg, value, []} )
  def valid?( {text, msg, value, opts} ) when is_atom(opts), do: valid?( {text, msg, value, [opts]} )

  def valid?( {text, msg, value, opts} ) when is_bitstring(text) and is_boolean(value)
  and is_list(opts), do: true
  def valid?( d ), do: false


  #--------------------------------------------------------
  def init( {text, msg} ), do: init( {text, msg, false, []} )
  def init( {text, msg, value} ), do: init( {text, msg, value, []} )
  def init( {text, msg, value, opt} ) when is_atom(opt), do: init( {text, msg, value, [opt]} )
  def init( {text, msg, value, opts} ) when is_list(opts) do
    # get the color
    color_opt = Enum.find(opts, &Enum.member?(@valid_colors, &1) ) || :dark

    colors = @colors[color_opt]
    {text_color, box_background, border_color, _, checkmark_color} = colors

    graph = Graph.build( font: {:roboto, 16} )
    |> Primitive.Group.add_to_graph(fn(graph) ->
      graph
      |> Primitive.Rectangle.add_to_graph({{-2,-2}, 140, 16}, color: :clear)
      |> Primitive.Oval.add_to_graph({{6,6}, 8}, color: box_background, border_color: border_color, border_width: 2, id: :box)
      |> Primitive.Oval.add_to_graph({{6,6}, 5}, color: checkmark_color, id: :chx, hidden: !value)
    end, translate: {0, -11})
    |> Primitive.Text.add_to_graph({{20,0}, text}, color: text_color )

    state = %{
      graph: graph,
      colors: colors,
      pressed: false,
      contained: false,
      checked: value,
      msg: msg
    }

IO.puts "RadioButton.init"
    push_graph( graph )

    {:ok, state}
  end

  #--------------------------------------------------------
  def handle_cast({:set_value, new_value}, %{checked: value} = state) do
    state = Map.put( state, :checked, new_value )
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_cast({:set_to_msg, set_msg}, %{msg: msg} = state) do
    state = Map.put( state, :checked, set_msg == msg )
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_activate( _args, %{graph: graph} = state ) do
IO.puts "RadioButton.handle_activate"
    push_graph( graph )
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_deactivate( _args, %{graph: graph} = state ) do
IO.puts "RadioButton.handle_deactivate"
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_enter, uid}, _, state ) do
    state = Map.put(state, :contained, true)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, uid}, _, state ) do
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
  %{contained: contained, msg: msg, pressed: pressed, checked: checked} = state ) do
    state = Map.put(state, :pressed, false)

    ViewPort.release_input( [:cursor_button, :cursor_pos])

    # only do the action if the cursor is still contained in the target
    if pressed && contained do
      send_event({:click, msg})
    end

    graph = update_graph(state)

    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( event, context, state ) do
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
        Graph.modify( graph, :box, &Primitive.put_style(&1, :color, pressed_color) )
      false ->
        Graph.modify( graph, :box, &Primitive.put_style(&1, :color, box_background) )
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










