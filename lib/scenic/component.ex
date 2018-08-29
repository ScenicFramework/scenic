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

      def add_to_graph(graph, data \\ nil, opts \\ [])
      def add_to_graph(%Scenic.Graph{} = graph, data, opts) do
        verify!(data)
        Primitive.SceneRef.add_to_graph(graph, {__MODULE__, data}, opts)
      end

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

      #--------------------------------------------------------
      defoverridable [
        add_to_graph:         3,
        info:                 0
      ]
    end # quote
  end # defmacro


end