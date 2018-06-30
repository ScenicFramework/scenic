#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Rectangle do
  use Scenic.Primitive

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :fill, :stroke]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Rectangle data must be a point, width and height. Like this: {{x0,y0}, width, height}"

  #--------------------------------------------------------
  def verify( {{x0, y0}, width, height} = data ) when
    is_number(x0) and is_number(y0) and
    is_number(width) and is_number(height), do: {:ok, data}
  def verify( _ ), do:  :invalid_data


  #============================================================================
  def valid_styles(), do: @styles


  #--------------------------------------------------------
  def default_pin(data), do: centroid( data )

  #--------------------------------------------------------
  def centroid(data)
  def centroid({{x0, y0}, width, height}) do
    {
      x0 + round(width / 2),
      y0 + round(height / 2),
    }
  end

  #--------------------------------------------------------
  def contains_point?( { {x,y}, w, h }, {xp,yp} ) do
    cond do
      xp < x       -> false
      yp < y       -> false
      xp > x + w   -> false
      yp > y + h   -> false
      true         -> true
    end
  end

end











