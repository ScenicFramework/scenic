
#  Created by Boyd Multerer on 9/13/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Animation.Basic.Rotate do
  use Scenic.Animation
  alias Scenic.Graph
  alias Scenic.Primitive


  def tick( :step, graph, elapsed_ms, {id, rads, rads_per_second} ) do
    angle = elapsed_ms * (rads_per_second / 1000)
    graph = Graph.modify(graph, id, fn(p) ->
      Primitive.put_transform(p, :rotate, angle)
      |> Primitive.put_transform( :translate, {20,30})
    end)
    {:continue, graph, {id, angle, rads_per_second} }
  end

end