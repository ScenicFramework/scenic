#
#  Created by Boyd Multerer on July 23, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# Seperate Context out into it's own file


defmodule Scenic.ViewPort.Context do
  alias Scenic.Math
  alias Scenic.Graph
  alias Scenic.ViewPort.Context

  # note: would like to define tx: and inverse_tx: as Matrix.identity() directly
  # as defaults in the struct. However, this breaks when cross-compiling to
  # opposite endian devices under Nerves. So call Context.build() when you want
  # to create a new Context, or fill in the matrices with a runtime call
  # to Matrix.identity yourself.

  # @identity   Matrix.identity

  defstruct viewport: nil, graph_key: nil, tx: nil, inverse_tx: nil, uid: nil, id: nil

  @type t :: %Context{
    viewport:   GenServer.server,
    graph_key:  Graph.key,
    tx:         Math.matrix,
    inverse_tx: Math.matrix,
    uid:        pos_integer,
    id:         any
  }

  @spec build( map ) :: Context.t
  def build( %{} = params ) do
    Map.merge(
      %Context{tx: Math.Matrix.identity(), inverse_tx: Math.Matrix.identity()},
      params
    )
  end
end
