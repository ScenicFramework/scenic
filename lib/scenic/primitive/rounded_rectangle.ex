#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.RoundedRectangle do
  use Scenic.Primitive

#  alias Scenic.Primitive
#  alias Scenic.Primitive.Style



  @styles   [:hidden, :color, :border_color, :border_width]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Rounded Rectangle data must be a point, width, height, and radius. Like this: {{x0,y0}, width, height, radius}"

  #--------------------------------------------------------
  def verify( {{x0, y0}, width, height, radius} = data ) when
    is_number(x0) and is_number(y0) and
    is_number(width) and is_number(height) and
    is_integer(radius) and (radius >= 0) and (radius <= 255), do: {:ok, data}
  def verify( _ ), do: :invalid_data

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {{x0, y0}, width, height, radius}, :native ) do
    { :ok,
      <<
        x0      :: integer-size(16)-native,
        y0      :: integer-size(16)-native,
        width   :: integer-size(16)-native,
        height  :: integer-size(16)-native,
        radius  :: integer-size(16)-native,
      >>
    }
  end
  def serialize( {{x0, y0}, width, height, radius}, :big ) do
    { :ok,
      <<
        x0      :: integer-size(16)-big,
        y0      :: integer-size(16)-big,
        width   :: integer-size(16)-big,
        height  :: integer-size(16)-big,
        radius  :: integer-size(16)-big,
      >>
    }
  end

  #--------------------------------------------------------
  def deserialize( binary_data, order \\ :native )
  def deserialize( <<
      x0      :: integer-size(16)-native,
      y0      :: integer-size(16)-native,
      width   :: integer-size(16)-native,
      height  :: integer-size(16)-native,
      radius  :: integer-size(16)-native,
      bin     :: binary
    >>, :native ) do
    {:ok, {{x0, y0}, width, height, radius}, bin}
  end
  def deserialize( <<
      x0      :: integer-size(16)-big,
      y0      :: integer-size(16)-big,
      width   :: integer-size(16)-big,
      height  :: integer-size(16)-big,
      radius  :: integer-size(16)-big,
      bin     :: binary
    >>, :big ) do
    {:ok, {{x0, y0}, width, height, radius}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }



  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def default_pin(data), do: centroid( data )

  #--------------------------------------------------------
  def centroid(data)
  def centroid({{x0, y0}, width, height, _}) do
    {
      x0 + round(width / 2),
      y0 + round(height / 2),
    }
  end

  #--------------------------------------------------------
  def expand( { {x,y}, w, h, r }, width ) do
    smaller = cond do
      w < h -> w
      true -> h
    end
    {
      {x - width, y - width},
      w + width + width,
      h + width + width,
      # radius of the border should be proportionally larger
      round((r / smaller) * (smaller + width + width))
    }
  end

  #--------------------------------------------------------
  def contains_point?( { {x,y}, w, h, r }, {xp,yp} ) do
    left          = x
    top           = y
    right         = x + w
    bottom        = y + h
    inner_left    = left + r
    inner_top     = top + r
    inner_right   = right - r
    inner_bottom  = bottom - r

    cond do
      # check the clear outer boundary
      xp < left    -> false
      yp < top     -> false
      xp > right   -> false
      yp > bottom  -> false

      # check the clear inner boundary
      (xp >= inner_left) && (xp <= inner_right)  -> true
      (yp >= inner_top) && (yp <= inner_bottom)  -> true

      # check the rounding quadrants
      # top left
      (xp < inner_left) && (yp < inner_top) ->
        inside_radius?({inner_left, inner_left}, r, {xp,yp})

      # top right
      (xp > inner_right) && (yp < inner_top) ->
        inside_radius?({inner_right, inner_left}, r, {xp,yp})

      # bottom right
      (xp > inner_right) && (yp > inner_bottom) ->
        inside_radius?({inner_right, inner_bottom}, r, {xp,yp})

      # bottom left
      (xp < inner_left) && (yp > inner_bottom) ->
        inside_radius?({inner_left, inner_bottom}, r, {xp,yp})

      # that should cover all the cases
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










