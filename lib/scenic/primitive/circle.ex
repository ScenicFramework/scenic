#
#  Created by Boyd Multerer on June 5, 2018.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Circle do
  use Scenic.Primitive

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
    normalize(data)
    {:ok, data}
  rescue
    _ -> :invalid_data
  end

  # --------------------------------------------------------
  @spec normalize(number()) :: number()
  def normalize(radius) when is_number(radius) do
    radius
  end

  # ============================================================================
  @spec valid_styles() :: [:hidden | :fill | :stroke]
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  def contains_point?(radius, {xp, yp}) do
    # calc the distance squared fromthe pont to the center
    d_sqr = xp * xp + yp * yp
    # test if less or equal to radius squared
    d_sqr <= radius * radius
  end
end
