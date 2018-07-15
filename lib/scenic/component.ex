#
#  Created by Boyd Multerer on 3/26/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#


defmodule Scenic.Component do
  alias Scenic.Primitive


  @callback add_to_graph(map, any, list) :: map
  @callback verify( any ) :: any
  @callback info() :: String.t

#  import IEx

  #===========================================================================
  defmodule Error do
    defexception [ message: nil, error: nil, data: nil ]
  end

  #===========================================================================
  defmacro __using__(opts) do
    quote do
      @behaviour Scenic.Component

      use Scenic.Scene, unquote(opts)

#      def build(data \\ nil, opts \\ [])
#      def build(data, opts) do
#        Component = verify!( data )
#        Primitive.build(__MODULE__, data, opts)
#      end

      def add_to_graph(graph, data \\ nil, opts \\ [])
      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        IO.inspect data
        verify!(data)
        Primitive.SceneRef.add_to_graph(graph, {__MODULE__, data}, opts)
      end

      # def valid?(nil),              do: true
      def verify(nil),              do: {:ok, nil}
      def info() do
        "#{inspect(__MODULE__)} invalid add_to_graph data"
      end

      @doc false
      def verify!( data ) do
        case verify(data) do
          {:ok, data} -> data
          err -> raise Error, message: info(), error: err, data: data
        end
      end


#      def start_child_scene( parent_scene, ref, args, with_children \\ false ) do
#        IO.puts "in component start_child_scene, with_children: #{with_children}"
#        Scenic.Component.start_child_scene( parent_scene, ref, __MODULE__, args, with_children )
#      end

#      def normalize( data ),              do: data

      #--------------------------------------------------------
      defoverridable [
        add_to_graph:         3,
        # valid?:               1,
        info:                 0,
#        start_child_scene:  4
#        normalize:        1
      ]
    end # quote
  end # defmacro

#  def start_child_scene( parent_scene, ref, mod, args, with_children ) do
#    Scenic.Scene.start_child_scene( parent_scene, ref, mod, args, with_children )
#  end

end