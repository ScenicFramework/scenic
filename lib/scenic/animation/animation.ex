#
#  Created by Boyd Multerer on 5/9/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# in general any given animation will story any private state it needs
# in the primitive's assigns map, with that animation's reference as the key.

defmodule Scenic.Animation do
#  alias Scenic.Graph
#  alias Scenic.Scene
#  alias Scenic.Primitive
#  alias Scenic.Primitive.Style

#  import IEx

  @callback add_to_graph(map, any, atom | {atom,atom} | function) :: map



  #===========================================================================
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Animation


      def add_to_graph(graph, data, opts \\ [])
      def add_to_graph(%Scenic.Graph{} = graph, data, _opts) do
        Scenic.Graph.schedule_recurring_action!( graph, data, __MODULE__ )
      end

#      def filter_input(event, primitive, graph),    do: {:continue, event, graph}

      #--------------------------------------------------------
      defoverridable [
        add_to_graph:  3
      ]
    end # quote
  end # defmacro

end



