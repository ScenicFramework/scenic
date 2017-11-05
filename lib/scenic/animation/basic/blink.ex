
#  Created by Boyd Multerer on 9/13/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Animation.Basic.Blink do
  use Scenic.Animation
  alias Scenic.Graph
  alias Scenic.Primitive


  def add_to_graph(graph, {id, period}, opts) when is_integer(period) do
    super(graph, {id, period, true, 0}, opts)
  end

  def step( graph, elapsed_time, {id, period, on, total_time} ) do
    total_time = total_time + elapsed_time

    visible = (rem( total_time, period ) < (period / 2))

    graph = if visible != on do
      Graph.modify(graph, id, fn(p) ->
        case visible do
          true ->   Primitive.put_style( p, :hidden, false )
          false ->  Primitive.put_style( p, :hidden, true )
        end
      end)
    else
      graph
    end

    {:continue, graph, {id, period, visible, total_time} }
  end

end