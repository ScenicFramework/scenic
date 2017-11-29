#
#  Created by Boyd Multerer on 10/30/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Oval do
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
  def verify( _ ), do: :invalid_data


  #--------------------------------------------------------
  def normalize( {center, radius} ), do: normalize( {center, radius, 1.0, 1.0} )
  def normalize( {{x, y}, radius, x_factor, y_factor} = data ) when
  is_number(x) and is_number(y) and is_number(radius) and
  is_number(x_factor) and is_number(y_factor), do: data

  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def default_pin(data) do
    {{x, y},_,_,_} = normalize( data )
    {x,y}
  end

  #--------------------------------------------------------
  def expand( data, width ) do
    { {x,y}, r, xf, yf } = normalize( data )
    {{x,y}, r + width, xf, yf}
  end

end