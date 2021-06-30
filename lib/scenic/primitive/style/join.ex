#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
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

  def validate(:miter), do: {:ok, :miter}
  def validate(:round), do: {:ok, :round}
  def validate(:bevel), do: {:ok, :bevel}

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Join specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :join style must be one of :miter, :round, or :bevel#{IO.ANSI.default_color()}
      """
    }
  end
end
