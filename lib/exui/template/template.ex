#
#  Created by Boyd Multerer on 5/13/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Template do
  alias Scenic.Graph

#  import IEx

#  @identity       MatrixBin.identity()

  @callback build(any, list) :: tuple
  @callback add_to_graph(map, any, list) :: map


  # { parent_id, module, event_handler, transform, styles, data }


  #===========================================================================
  # define a policy error here - not found or something like that
  defmodule StyleError do
    defexception [
      message:    "#{IO.ANSI.red}Unable to add style to template\n",
      template:  nil,
      style:     nil
    ]
  end


  #===========================================================================
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Template

      def add_to_graph(graph, data \\ nil, opts \\ [])
      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        Graph.add(graph, __MODULE__, data, opts )
      end


      #--------------------------------------------------------
#      defoverridable [
#        put_style:  3
#      ]
    end # quote
  end # defmacro

  #============================================================================
  # shared functions



end