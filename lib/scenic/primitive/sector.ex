#
#  Created by Boyd Multerer on 10/29/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Sector do
  use Scenic.Primitive

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :color, :border_color, :border_width]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Rectangle data must be a point, width and height. Like this: {{x0,y0}, width, height}"

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
  def normalize( {center, start, finish, radius} ), do: normalize( {center, start, finish, radius, {1.0,1.0}} )
  def normalize( {{x, y}, start, finish, radius, {h,k}} = data )
  when is_number(x) and is_number(y) and
  is_number(start) and is_number(finish) and is_number(radius) and
  is_number(h) and is_number(k), do: data


  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def default_pin( data ) do
    {{x, y},_,_,_,_} = normalize(data)
    {x,y}
  end

  #--------------------------------------------------------
  def expand( data, width ) do
    { {x,y}, s, f, r, factor } = normalize(data)
    {{x,y}, s, f, r + width, factor}
  end

end