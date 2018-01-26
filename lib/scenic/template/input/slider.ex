#
#  Created by Boyd Multerer
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Template.Input.Slider do
  use Scenic.Template.Input

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Template.Input
  alias Scenic.ViewPort.Input.Tracker
  alias Scenic.Math.MatrixBin, as: Matrix

#  import IEx

  #===========================================================================
  defmodule Error do
    defexception [ message: nil ]
  end

  @height             16
  @mid_height         trunc(@height / 2)
  @radius             5
  @btn_size           14

  @extents_mismatch   "Numeric extents must be the same type. Either both floats or both integers."


  @slider_color       :antique_white
  @hit_target_color   {:pink, 0}
  @line_color         :cornflower_blue
  @line_width         4

  #----------------------------------------------------------------------------
  def build( data, opts \\ [] )

  def build({e, i, w}, o ) when is_float(w), do: build({trunc(w), e, i}, o)

  def build({ext, init, width}, opts ) when is_integer(width) do
    opts = opts
      |> Keyword.put( :input_state, {:slider, width, prep_extents(ext)} )
      |> Keyword.put( :input_value, init )
      |> Keyword.put( :pin, {0, @height / 2} )

    Input.build(opts)
      |> Primitive.Rectangle.add_to_graph( {{0,0}, width, @height}, color: @hit_target_color )
      |> Primitive.Line.add_to_graph( {{0,@mid_height},{width,@mid_height}}, color: @line_color, line_width: @line_width )
      |> Primitive.RoundedRectangle.add_to_graph( {{0,1}, @btn_size, @btn_size, @radius}, color: @slider_color, tags: [:slider] )
      |> update_slider_position( 0 )
      |> Graph.put_event_filter(0, {Input.Slider, :filter_input})
  end

  defp prep_extents( extents )
  defp prep_extents( {min,max} ) when is_integer(min) and is_integer(max),  do: {min,max}
  defp prep_extents( {min,max} ) when is_float(min) and is_float(max),      do: {min,max}
  defp prep_extents( extents )   when is_list(extents), do: extents
  defp prep_extents( {min,max} ) when is_float(min) and is_integer(max) do
    raise Error, @extents_mismatch
  end
  defp prep_extents( {min,max} ) when is_integer(min) and is_float(max) do
    raise Error, @extents_mismatch
  end
  defp prep_extents( _ ) do
    raise Error, "Extents must be either a numeric {min,max} tuple or a list of values"
  end

  
  #----------------------------------------------------------------------------
  defp update_slider_position(graph, uid) when is_integer(uid) do
    update_slider_position( graph, Graph.get(graph, uid) )
  end

  defp update_slider_position(graph, slider) do
    # first find the uid for the slider button
    uid = Primitive.get_uid(slider)

    [btn] = Graph.find(graph, uid, tag: :slider)
    btn_uid = Primitive.get_uid( btn )

    # get the slider state data
    {:slider, width, extents} = Input.get_state( slider )

    # get the slider state data
    v = Input.get_value( slider )

    # calculate the slider position
    x = calc_slider_position( width, extents, v )

    # apply the x position as a translation transform
    Graph.modify(graph, btn_uid, fn(p) ->
      #Primitive.put_transform( p, :translate, {x,0} )
      { {_, y}, width, height, radius } = Primitive.get(p)
      Primitive.put(p, { {x, y}, width, height, radius })    
    end)
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


  #----------------------------------------------------------------------------
  def filter_input(event, slider, graph) do
    case event do

      {:cursor_button, :left, :press, _, _ } ->
        uid = Primitive.get_uid(slider)
        mx = Graph.get_inverse_tx(graph, slider)

        Tracker.Position.start( :left, slider, mx )
        {:stop,  graph}

      {:position, pos, inv_mx} ->
        # project the position by the inverse transform
        {x,_} = Matrix.project_vector( inv_mx, pos )

        # get the slider state data
        {:slider, width, extents} = Input.get_state( slider )

        # first, pin the extents
        x = cond do
          x < 0     -> 0
          x > width -> width
          true -> x
        end

        # calc the new value based on it's position across the slider
        old_value = Input.get_value( slider )
        new_value = calc_value_by_percent(extents, x / width)

        # if the value has changed, update the graph, otherwise stop here
        if new_value == old_value do
          {:stop,  graph}
        else
          # set the value and update the position
          uid = Primitive.get_uid(slider)
          slider = Input.put_value(slider, new_value)
          graph = Graph.put(graph, uid, slider)
            |> update_slider_position( uid )

          # create a new event to send up the chain from here
          event = {:value_changed, slider, new_value}
          {:continue, event, graph}
        end

      event ->
        {:continue, event, graph}
    end
  end

end