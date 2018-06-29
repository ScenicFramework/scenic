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
  def info(), do: "Sector should look like this: {{0,y}, radius, start, finish, h, k}\r\n" <>
  "Circle sector looks like this: {{x0,y0}, width, height, 1.0, 1.0}\r\n" <>
  "Ellipse sector looks like this: {{x0,y0}, width, height, 2.0, 1.0}"

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
  def normalize( {{x, y}, radius, start, finish, h, k} = data )
  when is_number(x) and is_number(y) and
  is_number(start) and is_number(finish) and is_number(radius) and
  is_number(h) and is_number(k), do: data


  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def expand( {{x, y}, radius, start, finish, h, k}, width ) do
    {{x, y}, radius + width, start, finish, h, k}
  end

  #--------------------------------------------------------
  def default_pin( data ) do
    {{x, y},_,_,_,_,_} = normalize(data)
    {x,y}
  end

  #--------------------------------------------------------
  def contains_point?( {{x, y}, radius, start, finish, h, k}, {xp,yp} ) do
    xp = xp - x
    yp = yp - y
    # using polar coordinates...
    point_angle = :math.atan2( yp, xp )
    point_radius_sqr = xp * xp + yp * yp

    # calculate the sector radius for that angle. Not just a simple
    # radius check as h and k get muliplied in to make it a sector
    # of an ellipse. Gotta check that too
    sx = h * radius * :math.cos(point_angle);
    sy = k * radius * :math.sin(point_angle);
    sector_radius_sqr = sx * sx + sy * sy

    if point_angle > start &&
    point_angle < finish &&
    point_radius_sqr < sector_radius_sqr do
      true
    else
      false
    end
  end

end