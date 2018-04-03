defmodule Scenic.Component.Input.Slider do
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort

  import IEx


  @height             16
  @mid_height         trunc(@height / 2)
  @radius             5
  @btn_size           14

  @extents_mismatch   "Numeric extents must be the same type. Either both floats or both integers."

  @slider_color       :antique_white
  @hit_target_color   :clear
  @line_color         :cornflower_blue
  @line_width         4

#  #--------------------------------------------------------
  def info() do
    "#{IO.ANSI.red()}Slider must be initialized with {extents, initial, width, id}#{IO.ANSI.default_color()}\r\n"
  end

  #--------------------------------------------------------
  def valid?( {ext, init, width, id} ), do: true
  def valid?( d ), do: false


  #--------------------------------------------------------
  def init( {extents, value, width, id} ) do

    graph = Graph.build()
      |> Primitive.Rectangle.add_to_graph( {{0,0}, width, @height}, color: :clear )
      |> Primitive.Line.add_to_graph( {{0,@mid_height},{width,@mid_height}}, color: @line_color, line_width: @line_width )
      |> Primitive.RoundedRectangle.add_to_graph( {{0,1}, @btn_size, @btn_size, @radius}, color: @slider_color, id: :thumb )
      |> update_slider_position( value, extents, width )

    state = %{
      graph: graph,
      value: value,
      extents: extents,
      width: width,
      id: id,
      tracking: false
    }

IO.puts "Slider.init"

    {:ok, state}
  end


  #--------------------------------------------------------
  def handle_activate( _args, %{graph: graph} = state ) do
IO.puts "Slider.handle_activate"
    ViewPort.put_graph( graph )
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_deactivate( _args, %{graph: graph} = state ) do
IO.puts "Slider.handle_deactivate"
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :press, _, {x,_}}}, context, state ) do
    state = state
    |> Map.put( :tracking, true )

    state = update_slider( x, state )

    ViewPort.capture_input(context, [:cursor_button, :cursor_pos])

    {:noreply, state} #%{state | graph: graph}}
  end

  #--------------------------------------------------------
  def handle_input( {:cursor_button, {:left, :release, _, _}}, context, state ) do
    state = Map.put(state, :tracking, false)

    ViewPort.release_input( [:cursor_button, :cursor_pos])

    {:noreply, state} #%{state | graph: graph}}
  end


  #--------------------------------------------------------
  def handle_input( {:cursor_pos, {x,_}}, context, %{tracking: true} = state ) do
    state = update_slider( x, state )
    {:noreply, state}
  end


  #--------------------------------------------------------
  def handle_input( event, context, state ) do
    {:noreply, state}
  end


  #============================================================================
  # internal utilities
  # {text_color, box_background, border_color, pressed_color, checkmark_color}

  defp update_slider( x, %{
    graph: graph,
    value: old_value,
    extents: extents,
    width: width,
    id: id,
    tracking: true
  } = state ) do

    # pin x to be inside the width
    x = cond do
      x < 0     -> 0
      x > width -> width
      true -> x
    end

    # calc the new value based on it's position across the slider
    new_value = calc_value_by_percent(extents, x / width)

    # update the slider position
    graph = update_slider_position(graph, new_value, extents, width)

    if new_value != old_value do
      send_event({:value_changed, id, new_value})
    end

    %{ state |
      graph: graph,
      value: new_value
    }
  end

  #--------------------------------------------------------
  defp update_slider_position(graph, new_value, extents, width) do
    # calculate the slider position
    new_x = calc_slider_position( width, extents, new_value )

    # apply the x position
    graph = Graph.modify(graph, :thumb, fn(p) ->
      #Primitive.put_transform( p, :translate, {x,0} )
      { {_, y}, width, height, radius } = Primitive.get(p)
      Primitive.put(p, { {new_x, y}, width, height, radius })    
    end)
    |> ViewPort.put_graph()
  end


  #--------------------------------------------------------
  # calculate the position if the extents are numeric
  defp calc_slider_position(width, extents, value)
  defp calc_slider_position(width, {min,max}, value) when value < min do
    calc_slider_position(width, {min,max}, min)
  end
  defp calc_slider_position(width, {min,max}, value) when value > max do
    calc_slider_position(width, {min,max}, max)
  end
  defp calc_slider_position(width, {min,max}, value) do
    width = width - @btn_size
    percent = (value - min) / (max - min)
    trunc( width * percent )
  end

  #--------------------------------------------------------
  # calculate the position if the extents is a list of arbitrary values
  defp calc_slider_position(width, extents, value)
  defp calc_slider_position(width, ext, value) when is_list(ext) do
    max_index = Enum.count(ext) - 1

    index = case Enum.find_index(ext, fn(v) -> v == value end) do
      nil ->    raise Error, "Slider value not in extents list"
      index ->  index
    end

    # calc position of slider
    width = width - @btn_size
    percent = index / max_index
    round( width * percent )
  end

  #--------------------------------------------------------
  defp calc_value_by_percent({min,max}, percent) when is_integer(min) and is_integer(max) do
    round((max - min) * percent) + min
  end

  defp calc_value_by_percent({min,max}, percent)when is_float(min) and is_float(max) do
    ((max - min) * percent) + min
  end

  defp calc_value_by_percent(extents, percent) when is_list(extents) do
    max_index = Enum.count(extents) - 1
    index = round(max_index * percent)
    Enum.at(extents, index)
  end


end










