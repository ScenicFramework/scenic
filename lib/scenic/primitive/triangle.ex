#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Triangle do
  use Scenic.Primitive

#  alias Scenic.Primitive
#  alias Scenic.Primitive.Style

  @styles   [:hidden, :color, :border_color, :border_width]


  #===========================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Triangle data must be three points, like this: {{x0,y0}, {x1,y1}, {x2,y2}}"

  def verify( {{x0, y0}, {x1, y1}, {x2, y2}} ) when
    is_number(x0) and is_number(y0) and
    is_number(x1) and is_number(y1) and
    is_number(x2) and is_number(y2), do: true
  def verify( _ ), do: false


  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {{x0, y0}, {x1, y1}, {x2, y2}}, :native ) do
    { :ok,
      <<
        x0      :: integer-size(16)-native,
        y0      :: integer-size(16)-native,
        x1      :: integer-size(16)-native,
        y1      :: integer-size(16)-native,
        x2      :: integer-size(16)-native,
        y2      :: integer-size(16)-native,
      >>
    }
  end
  def serialize( {{x0, y0}, {x1, y1}, {x2, y2}}, :big ) do
    { :ok,
      <<
        x0      :: integer-size(16)-big,
        y0      :: integer-size(16)-big,
        x1      :: integer-size(16)-big,
        y1      :: integer-size(16)-big,
        x2      :: integer-size(16)-big,
        y2      :: integer-size(16)-big,
      >>
    }
  end

  #--------------------------------------------------------
  def deserialize( binary_data, order \\ :native )
  def deserialize( <<
      x0      :: integer-size(16)-native,
      y0      :: integer-size(16)-native,
      x1      :: integer-size(16)-native,
      y1      :: integer-size(16)-native,
      x2      :: integer-size(16)-native,
      y2      :: integer-size(16)-native,
      bin     :: binary
    >>, :native ) do
    {:ok, {{x0, y0}, {x1, y1}, {x2, y2}}, bin}
  end
  def deserialize( <<
      x0      :: integer-size(16)-big,
      y0      :: integer-size(16)-big,
      x1      :: integer-size(16)-big,
      y1      :: integer-size(16)-big,
      x2      :: integer-size(16)-big,
      y2      :: integer-size(16)-big,
      bin     :: binary
    >>, :big ) do
    {:ok, {{x0, y0}, {x1, y1}, {x2, y2}}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }

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

end