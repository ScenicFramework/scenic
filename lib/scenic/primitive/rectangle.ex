#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Rectangle do
  use Scenic.Primitive

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :color, :border_color, :border_width]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Rectangle data must be a point, width and height. Like this: {{x0,y0}, width, height}"

  #--------------------------------------------------------
  def verify( {{x0, y0}, width, height} ) when
    is_number(x0) and is_number(y0) and
    is_number(width) and is_number(height), do: true
  def verify( _ ), do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {{x0, y0}, width, height}, :native ) do
    { :ok,
      <<
        x0      :: integer-size(16)-native,
        y0      :: integer-size(16)-native,
        width   :: integer-size(16)-native,
        height  :: integer-size(16)-native,
      >>
    }
  end
  def serialize( {{x0, y0}, width, height}, :big ) do
    { :ok,
      <<
        x0      :: integer-size(16)-big,
        y0      :: integer-size(16)-big,
        width   :: integer-size(16)-big,
        height  :: integer-size(16)-big,
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
      bin     :: binary
    >>, :native ) do
    {:ok, {{x0, y0}, width, height}, bin}
  end
  def deserialize( <<
      x0      :: integer-size(16)-big,
      y0      :: integer-size(16)-big,
      width   :: integer-size(16)-big,
      height  :: integer-size(16)-big,
      bin     :: binary
    >>, :big ) do
    {:ok, {{x0, y0}, width, height}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


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

end