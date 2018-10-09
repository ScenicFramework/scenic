#
#  Created by Boyd Multerer on June 5, 2018.2017-10-29.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Sector do
  @moduledoc false

  use Scenic.Primitive

  # import IEx

  @styles [:hidden, :fill, :stroke]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be: {radius, start_angle, end_angle}
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
  @spec normalize({number(), number(), number()}) :: {number(), number(), number()}
  def normalize({radius, start, finish} = data)
      when is_number(start) and is_number(finish) and is_number(radius),
      do: data

  # ============================================================================
  @spec valid_styles() :: [:fill | :hidden | :stroke, ...]
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  def contains_point?({radius, start, finish}, {xp, yp}) do
    # using polar coordinates...
    point_angle = :math.atan2(yp, xp)
    point_radius_sqr = xp * xp + yp * yp

    # calculate the sector radius for that angle. Not just a simple
    # radius check as h and k get muliplied in to make it a sector
    # of an ellipse. Gotta check that too
    sx = radius * :math.cos(point_angle)
    sy = radius * :math.sin(point_angle)
    sector_radius_sqr = sx * sx + sy * sy

    if start <= finish do
      # clockwise winding
      point_angle >= start && point_angle <= finish && point_radius_sqr <= sector_radius_sqr
    else
      # counter-clockwise winding
      point_angle <= start && point_angle >= finish && point_radius_sqr <= sector_radius_sqr
    end
  end
end
