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
  def verify( {{x0, y0}, width, height, radius} ) when
    is_number(x0) and is_number(y0) and
    is_number(width) and is_number(height) and
    is_integer(radius) and (radius >= 0) and (radius <= 255), do: true
  def verify( _ ), do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {{x0, y0}, width, height, radius}, :native ) do
    { :ok,
      <<
        x0      :: integer-size(16)-native,
        y0      :: integer-size(16)-native,
        width   :: integer-size(16)-native,
        height  :: integer-size(16)-native,
        radius  :: size(8)
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
        radius  :: size(8)
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
      radius  :: size(8),
      bin     :: binary
    >>, :native ) do
    {:ok, {{x0, y0}, width, height, radius}, bin}
  end
  def deserialize( <<
      x0      :: integer-size(16)-big,
      y0      :: integer-size(16)-big,
      width   :: integer-size(16)-big,
      height  :: integer-size(16)-big,
      radius  :: size(8),
      bin     :: binary
    >>, :big ) do
    {:ok, {{x0, y0}, width, height, radius}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


#  #--------------------------------------------------------
#  def serialize( {{x0, y0}, width, height, radius} ) do
#    { :ok,
#      <<
#        x0      :: integer-size(16)-big,
#        y0      :: integer-size(16)-big,
#        width   :: integer-size(16)-big,
#        height  :: integer-size(16)-big,
#        radius  :: size(8)
#      >>
#    }
#  end
#
#  #--------------------------------------------------------
#  def deserialize( binary_data )
#  def deserialize( <<
#      x0      :: integer-size(16)-big,
#      y0      :: integer-size(16)-big,
#      width   :: integer-size(16)-big,
#      height  :: integer-size(16)-big,
#      radius  :: size(8),
#      bin     :: binary
#    >> ) do
#    {:ok, {{x0, y0}, width, height, radius}, bin}
#  end
#  def deserialize( binary_data ), do: {:err_invalid, binary_data }


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

end