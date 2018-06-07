defmodule Scenic.Component.Input.Checkbox do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [{:group, 3}, {:rect, 3}, {:rrect, 3},
                                {:text, 3}, {:path, 3}]
#  import IEx


#  @default_width      80
#  @default_height     32
#  @default_radius     6
#  @default_type       6

#  @blue_color         :steel_blue
#  @text_color         :white

  @valid_colors [:light, :dark]

  # type is {text_color, box_background, border_color, pressed_color, checkmark_color}
  # nil for text_color means to use whatever is inherited
  @colors %{
    light:    {:black, :white, :grey, {215, 215, 215}, :cornflower_blue},
    dark:     {:white, :black, :grey, {40,40,40}, :cornflower_blue},
  }

#  #--------------------------------------------------------
  def info() do
    "#{IO.ANSI.red()}Checkbox must be initialized with {text, message, opts}#{IO.ANSI.default_color()}\r\n"
  end

  #--------------------------------------------------------
  def valid?( {text, msg, value} ), do: valid?( {text, msg, value, []} )
  def valid?( {text, msg, value, opts} ) when is_atom(opts), do: valid?( {text, msg, value, [opts]} )

  def valid?( {text, _msg, value, opts} ) when is_bitstring(text) and is_boolean(value)
  and is_list(opts), do: true
  def valid?( _ ), do: false


  #--------------------------------------------------------
  def init( {text, msg, value}, i_opts ), do: init( {text, msg, value, []}, i_opts )
  def init( {text, msg, value, opt}, i_opts ) when is_atom(opt) do
      init( {text, msg, value, [opt]}, i_opts )
    end
  def init( {text, msg, value, opts}, _ ) when is_list(opts) do
    # get the color
    color_opt = Enum.find(opts, &Enum.member?(@valid_colors, &1) ) || :dark

    colors = @colors[color_opt]
    {text_color, box_background, border_color, _, checkmark_color} = colors

    graph = Graph.build( font: :roboto, font_size: 16 )
    |> group(fn(graph) ->
      graph
      |> rect({{-2,-2}, 140, 16}, fill: :clear)
      |> rrect({{-2,-2}, 16, 16, 3},
        fill: box_background, stroke: {2, border_color}, id: :box )

      |> group(fn(graph) ->
        graph
        |> path([                 # this is the checkmark
            {:move_to, 1, 7},
            {:line_to, 5, 10},
            {:line_to, 10,1}
          ], stroke: {2, checkmark_color}, join: :round)
      end, id: :chx, hidden: !value)
    end, translate: {0, -11})
    |> text({{20,0}, text}, fill: text_color )

    state = %{
      graph: graph,
      colors: colors,
      pressed: false,
      contained: false,
      checked: value,
      msg: msg
    }

#IO.puts "Checkbox.init"
    push_graph( graph )

    {:ok, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_enter, _uid}, _, state ) do
    state = Map.put(state, :contained, true)
    graph = update_graph(state)
    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_exit, _uid}, _, state ) do
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

    ViewPort.capture_input( context, [:cursor_button, :cursor_pos] )

    {:noreply, %{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :release, _, _}}, context,
  %{contained: contained, msg: msg, pressed: pressed, checked: checked} = state ) do
    state = Map.put(state, :pressed, false)

    ViewPort.release_input( context, [:cursor_button, :cursor_pos])

    # only do the action if the cursor is still contained in the target
    state = case pressed && contained do
      true ->
        checked = !checked
        send_event({:value_changed, msg, checked})
        Map.put(state, :checked, checked)

      false ->
        state
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










