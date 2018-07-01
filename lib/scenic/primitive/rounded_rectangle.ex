#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.RoundedRectangle do
  use Scenic.Primitive
  alias Scenic.Primitive.Rectangle

  # import IEx

  @styles   [:hidden, :fill, :stroke]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Rounded Rectangle data must be {width, height, radius}\r\n" <>
    "Radius will be clamped to half of the smaller of width or height."
  end

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
  def normalize( {width, height, radius} ) when
  is_number(width) and is_number(height) and
  is_number(radius) and (radius >= 0) do
    w = abs(width)
    h = abs(height)
    
    # clamp the radius
    radius = case w <= h do
      true -> # width is smaller
        case radius > w / 2 do
          true -> w / 2
          false -> radius
        end
      false -> # height is smaller
        case radius > h / 2 do
          true -> h / 2
          false -> radius
        end
    end

    {width, height, radius}
  end




  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def default_pin(data), do: centroid( data )

  #--------------------------------------------------------
  def centroid(data)
  def centroid({width, height, _}) do
    { width / 2, height / 2 }
  end

  #--------------------------------------------------------
  def contains_point?( { w, h, r }, {xp,yp} ) do
    # check that it is in the bounding rectangle first
    if Rectangle.contains_point?( { w, h }, {xp,yp} ) do
      # we now know the signs are the same, so we can use abs to make things easier
      inner_left    = r
      inner_top     = r
      inner_right   = abs(w) - r
      inner_bottom  = abs(h) - r
      xp = abs(xp)
      yp = abs(yp)
      point = {xp,yp}

      # check the rounding quadrants
      cond do
        # # if it is in the inner rect, then we are done
        # Rectangle.contains_point?(
        #   {
        #     abs(inner_right - inner_left),
        #     abs(inner_bottom - inner_top)
        #   },
        #   {abs(xp-r),abs(yp-r)}
        # ) -> true

        # top left
        (xp < inner_left) && (yp < inner_top) ->
          inside_radius?({inner_left, inner_left}, r, point)

        # top right
        (xp > inner_right) && (yp < inner_top) ->
          inside_radius?({inner_right, inner_left}, r, point)

        # bottom right
        (xp > inner_right) && (yp > inner_bottom) ->
          inside_radius?({inner_right, inner_bottom}, r, point)

        # bottom left
        (xp < inner_left) && (yp > inner_bottom) ->
          inside_radius?({inner_left, inner_bottom}, r, point)

        # not in the radius areas, but in the overall rect
        true -> true
      end
    else
      # not in the bounding rectangle
      false
    end
  end

  defp inside_radius?({x,y}, r, {xp,yp}) do
    # calc the squared distance from the point to the center of the arc
    dx = xp - x
    dy = yp - y
    d_sqr = (dx * dx) + (dy * dy)
    # if r squared is bigger, then it is inside the radius
    (r * r) >= d_sqr
  end

end










