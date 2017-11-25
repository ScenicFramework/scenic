
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
    [p] = Graph.get(graph, id)

    {mid_point, original} = case Primitive.get_transform( p, :scale ) do
      nil  -> {1.0, nil}
      orig -> {orig, orig}
    end

    tick( :step, graph, elapsed_ms, {id, mid_point, factor, speed, original} )
  end

  #--------------------------------------------------------
  def tick( :step, graph, elapsed_ms, {id, mid_point, factor, speed, original_scale} ) do
    scale = mid_point + :math.sin(elapsed_ms * speed) * factor
    graph = Graph.modify(graph, id, fn(p) ->
      Primitive.put_transform(p, :scale, scale)
    end)
    {:continue, graph, {id, mid_point, factor, speed, original_scale} }
  end

  #--------------------------------------------------------
  def tick( :stop, graph, elapsed_ms, {id, _, _, _, original_scale} ) do
    # restore the original scale
    graph = Graph.modify(graph, id, fn(p) ->
      Primitive.put_transform(p, :scale, original_scale)
    end)
    {:stop, graph }
  end

end