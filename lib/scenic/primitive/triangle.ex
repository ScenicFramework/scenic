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

  #--------------------------------------------------------
  # given three points, find the three points that expands
  # that triangle by a given width on each side.
  # General plan is this:
  # first, find three parallel lines that are moved outwards
  # by the width.
  # second, find the points that intersect those new lines.
  #
  # Special thanks to Mike Schacht, who is a math/physics wiz.
  # Seriously.
  #
  def expand( {p0, p1, p2}, width ) do
    # account for the winding of triangle
    cross = Math.Vector2.cross(
      Math.Vector2.sub(p1, p0),
      Math.Vector2.sub(p2, p0)
    )
    width = cond do
      cross < 0 -> -width
      true      -> width
    end
    
    # find the new parallel lines
    l01 = Math.Line.parallel( {p0, p1}, width )
    l12 = Math.Line.parallel( {p1, p2}, width )
    l20 = Math.Line.parallel( {p2, p0}, width )

    # calc the new poins from the intersections of the lines
    p0 = Math.Line.intersection( l01, l12 )
    p1 = Math.Line.intersection( l12, l20 )
    p2 = Math.Line.intersection( l20, l01 )

    # return the new triangle
    {p0, p1, p2}
  end



  # http://blackpawn.com/texts/pointinpoly/
  #--------------------------------------------------------
  def contains_point?( {p0, p1, p2}, px ) do
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