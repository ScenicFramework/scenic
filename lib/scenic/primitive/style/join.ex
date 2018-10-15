#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Join do
  @moduledoc """
  Set how to connect two lines in a path.

  Works with primitives that have clear joints, such as Rectangle,
  Quad, Triangle, and Path.

  Example:

      graph
      |> triangle( {{0,40},{40,40},{40,0}}
        join: :round,
        stroke: {2, :green}
      )

  ## Data
  * `:miter` - Miter the pointy part of the joint.
  * `:round` - Round the entire joint.
  * `:bevel` - Bevel the joint.
  """

  use Scenic.Primitive.Style

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be one of :miter, :round, :bevel
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(stroke) do
    try do
      normalize(stroke)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  @doc false
  def normalize(:miter), do: :miter
  def normalize(:round), do: :round
  def normalize(:bevel), do: :bevel
end
