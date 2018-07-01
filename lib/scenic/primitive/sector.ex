#
#  Created by Boyd Multerer on 10/29/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Sector do
  use Scenic.Primitive

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style

# import IEx

  @styles   [:hidden, :fill, :stroke]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Sector should look like this: {{0,y}, radius, start, finish}\r\n" <>
  "Add a scale transform to make it a sector of an ellipse"

  #--------------------------------------------------------
  def verify( data ) do
    try do
      normalize(data)
      {:ok, data}
    rescue
      _ -> :invalid_data
    end
  end


  #--------------------------------------------------------
  def normalize( {radius, start, finish} = data ) when
  is_number(start) and is_number(finish) and
  is_number(radius), do: data


  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def contains_point?( {radius, start, finish}, {xp,yp} ) do
    # using polar coordinates...
    point_angle = :math.atan2( yp, xp )
    point_radius_sqr = (xp * xp) + (yp * yp)

    # calculate the sector radius for that angle. Not just a simple
    # radius check as h and k get muliplied in to make it a sector
    # of an ellipse. Gotta check that too
    sx = radius * :math.cos(point_angle);
    sy = radius * :math.sin(point_angle);
    sector_radius_sqr = (sx * sx) + (sy * sy)

    if start <= finish do
      # clockwise winding
      point_angle >= start &&
      point_angle <= finish &&
      point_radius_sqr <= sector_radius_sqr
    else
      # counter-clockwise winding
      point_angle <= start &&
      point_angle >= finish &&
      point_radius_sqr <= sector_radius_sqr
    end
  end

end






