#
#  Created by Boyd Multerer on 3/26/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#


defmodule Scenic.Component do
  alias Scenic.Primitive


  @callback add_to_graph(map, any, list) :: map
  @callback info() :: String.t


  #===========================================================================
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Component

      use Scenic.Scene

#      def build(data \\ nil, opts \\ [])
#      def build(data, opts) do
#        Component = verify!( data )
#        Primitive.build(__MODULE__, data, opts)
#      end

      def add_to_graph(graph, data \\ nil, opts \\ [])
      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        unless valid?(data), do: raise info()
        Primitive.SceneRef.add_to_graph(graph, {__MODULE__, data}, opts)
      end

      def valid?(nil),              do: true
      def info(),                   do: "#{inspect(__MODULE__)} invalid add_to_graph data."

      def start_dynamic_scene( dyn_sup, ref, opts ), do:
        Scenic.Component.start_dynamic_scene( dyn_sup, ref, __MODULE__, opts )

#      def normalize( data ),              do: data

      #--------------------------------------------------------
      defoverridable [
        add_to_graph:         3,
        valid?:               1,
        info:                 0,
        start_dynamic_scene:  3
#        normalize:        1
      ]
    end # quote
  end # defmacro


  #--------------------------------------------------------
  def start_dynamic_scene( dyn_sup, ref, mod, opts ) do
    DynamicSupervisor.start_child( dyn_sup, {Scenic.Scene, {ref, mod, opts}} )
  end


end