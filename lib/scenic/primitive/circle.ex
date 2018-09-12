#
#  Created by Boyd Multerer on June 5, 2018.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Circle do
  use Scenic.Primitive

  # alias Scenic.Primitive
  #  alias Scenic.Primitive.Style

  @styles [:hidden, :fill, :stroke]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be: radius
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(data) do
    try do
      normalize(data)
      {:ok, data}
    rescue
      _ -> :invalid_data
    end
  end

  # --------------------------------------------------------
  def normalize(radius) when is_number(radius) do
    radius
  end

  # ============================================================================
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  def contains_point?(radius, {xp, yp}) do
    # calc the distance squared fromthe pont to the center
    d_sqr = xp * xp + yp * yp
    # test if less or equal to radius squared
    d_sqr <= radius * radius
  end
end
