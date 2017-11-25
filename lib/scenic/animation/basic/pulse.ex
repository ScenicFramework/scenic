
#  Created by Boyd Multerer on November 25, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Animation.Basic.Pulse do
  use Scenic.Animation
  alias Scenic.Graph
  alias Scenic.Primitive

  import IEx

  #--------------------------------------------------------
  def tick( :step, graph, elapsed_ms, {id, factor, speed} ) do
    # this is the first time step is called. Save the original scale
    orig_data = Graph.get(graph, id)
    |> Enum.reduce(%{}, fn(%Primitive{uid: uid} = p, acc) ->
      data = case Primitive.get_transform( p, :scale ) do
        nil  -> {1.0, nil}
        orig -> {orig, orig}
      end
      Map.put(acc, uid, data)
    end)

    tick( :step, graph, elapsed_ms, {id, factor, speed, orig_data} )
  end

  #--------------------------------------------------------
  def tick( :step, graph, elapsed_ms, {id, factor, speed, orig_data} ) do
    graph = Graph.modify(graph, id, fn(%Primitive{uid: uid} = p) ->

      {mid_point, _} = Map.get(orig_data, uid)
      scale = mid_point + :math.sin(elapsed_ms * speed) * factor * mid_point

      Primitive.put_transform(p, :scale, scale)
    end)
    {:continue, graph, {id, factor, speed, orig_data} }
  end

  #--------------------------------------------------------
  def tick( :stop, graph, elapsed_ms, {id, _, _, orig_data} ) do
    # restore the original scale
    graph = Graph.modify(graph, id, fn(p) ->
      {_, scale} = Map.get(orig_data, id)
      Primitive.put_transform(p, :scale, scale)
    end)
    {:stop, graph }
  end

end