#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Triangle do
  use Scenic.Primitive
  alias Scenic.Math
#  alias Scenic.Primitive
#  alias Scenic.Primitive.Style

  @styles   [:hidden, :fill, :stroke]


  #===========================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Triangle data must be three points, like this: {{x0,y0}, {x1,y1}, {x2,y2}}"

  def verify( {{x0, y0}, {x1, y1}, {x2, y2}} = data ) when
    is_number(x0) and is_number(y0) and
    is_number(x1) and is_number(y1) and
    is_number(x2) and is_number(y2), do: {:ok, data}
  def verify( _ ), do: :invalid_data


  #============================================================================
  def valid_styles(), do: @styles


  #--------------------------------------------------------
  def default_pin(data), do: centroid( data )

  #--------------------------------------------------------
  def centroid(data)
  def centroid({{x0, y0}, {x1, y1}, {x2, y2}}) do
    {
      round( (x0 + x1 + x2) / 3 ),
      round( (y0 + y1 + y2) / 3 )
    }
  end

  # http://blackpawn.com/texts/pointinpoly/
  #--------------------------------------------------------
  @degenerate 0.0001
  def contains_point?( {{x0,y0}=p0, {x1,y1}=p1, {x2,y2}=p2}, px ) do

    # make sure the points are not collinear, if so the abs(area) will be very small
    area = abs(x0 * (y1 - y2) + x1 * (y2 - y0) + x2 * (y0 - y1))

    if area < @degenerate do
      false
    else
      # compute vectors
      v0 = Math.Vector2.sub( p2, p0 )
      v1 = Math.Vector2.sub( p1, p0 )
      v2 = Math.Vector2.sub( px, p0 )

      # compute dot products
      dot00 = Math.Vector2.dot(v0, v0)
      dot01 = Math.Vector2.dot(v0, v1)
      dot02 = Math.Vector2.dot(v0, v2)
      dot11 = Math.Vector2.dot(v1, v1)
      dot12 = Math.Vector2.dot(v1, v2)

      # Compute barycentric coordinates
      invDenom = 1.0 / (dot00 * dot11 - dot01 * dot01)
      u = (dot11 * dot02 - dot01 * dot12) * invDenom
      v = (dot00 * dot12 - dot01 * dot02) * invDenom

      # Check if point is in triangle
      (u >= 0) && (v >= 0) && (u + v < 1)
    end
  end


end