
#  Created by Boyd Multerer on 9/13/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Animation.Basic.Blink do
  use Scenic.Animation
  alias Scenic.Graph
  alias Scenic.Primitive

#  import IEx

  @hz_to_rpms   2 * :math.pi / 1000

  def add_to_graph(graph, {id, frequency}, opts) when is_number(frequency) do
    super(graph, {id, frequency}, opts)
  end

  def tick( :step, graph, elapsed_ms, {id, frequency} ) do
    hidden = :math.sin(elapsed_ms * frequency * @hz_to_rpms) < 0
    graph = Graph.modify(graph, id, fn(p) ->
      Primitive.put_style( p, :hidden, hidden )
    end)
    {:continue, graph, {id, frequency} }
  end

end