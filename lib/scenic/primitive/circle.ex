#
#  Created by Boyd Multerer on June 5, 2018.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Circle do
  use Scenic.Primitive

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :fill, :stroke]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Circle data must be a point, and a radius. Like this: {{x,y}, radius}"

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
  def normalize( {{x, y}, radius} = data )
  when is_number(x) and is_number(y) and is_number(radius) do
    data
  end


  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def default_pin( data ) do
    {{x, y},_} = normalize(data)
    {x,y}
  end

  #--------------------------------------------------------
  def expand( data, width ) do
    { {x,y}, r } = normalize(data)
    { {x,y}, r + width }
  end

  #--------------------------------------------------------
  def contains_point?( {{x, y}, radius}, {xp,yp} ) do
    # calc the distance squared fromthe pont to the center
    d_sqr = (x - xp) * (x - xp) + (y - yp) * (y - yp)
    # test if less or equal to radius squared
    d_sqr <= radius * radius
  end


end