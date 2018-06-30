#
#  Created by Boyd Multerer on June 6, 2018.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Ellipse do
  use Scenic.Primitive

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :fill, :stroke]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Ellipse data must be a point, and a two radii. Like this: {{x,y}, r1, r2}\r\n" <>
    "hint: if you want to rotate or skew the ellipse, apply transforms..."

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
  def normalize( {{x, y}, r1, r2} = data )
  when is_number(x) and is_number(y) and is_number(r1) and is_number(r2) do
    data
  end


  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def default_pin( data ) do
    {{x, y},_,_} = normalize(data)
    {x,y}
  end

  #--------------------------------------------------------
  def contains_point?( {{x, y}, r1, r2}, {xp,yp} ) do
    dx = ((x - xp) * (x - xp)) / (r1 * r1)
    dy = ((y - yp) * (y - yp)) / (r2 * r2)
    # test if less or equal to 1
    dx + dy <= 1
  end
end