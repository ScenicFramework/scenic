#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Line do
  use Scenic.Primitive
#  alias Scenic.Primitive
#  alias Scenic.Primitive.Style

#  import IEx

  @styles   [:hidden, :color, :line_width]

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Line data must be two points, like this: {{x0,y0}, {x1,y1}}"


  #--------------------------------------------------------
  def verify( {{x0, y0}, {x1, y1}} = data ) when
    is_number(x0) and is_number(y0) and
    is_number(x1) and is_number(y1), do: {:ok, data}
  def verify( _ ), do: :invalid_data

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {{x0, y0}, {x1, y1}}, :native ) do
    { :ok,
      <<
        x0      :: integer-size(16)-native,
        y0      :: integer-size(16)-native,
        x1      :: integer-size(16)-native,
        y1      :: integer-size(16)-native
      >>
    }
  end
  def serialize( {{x0, y0}, {x1, y1}}, :big ) do
    { :ok,
      <<
        x0      :: integer-size(16)-big,
        y0      :: integer-size(16)-big,
        x1      :: integer-size(16)-big,
        y1      :: integer-size(16)-big
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
      bin     :: binary
    >>, :native ) do
    {:ok, {{x0, y0}, {x1, y1}}, bin}
  end
  def deserialize( <<
      x0      :: integer-size(16)-big,
      y0      :: integer-size(16)-big,
      x1      :: integer-size(16)-big,
      y1      :: integer-size(16)-big,
      bin     :: binary
    >>, :big ) do
    {:ok, {{x0, y0}, {x1, y1}}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }




  #============================================================================
  def valid_styles(), do: @styles

  #============================================================================

  #--------------------------------------------------------
  def default_pin(data), do: centroid( data )

  #--------------------------------------------------------
  def centroid(data)
  def centroid({{x0, y0}, {x1, y1}}) do
    {
      round( (x0 + x1) / 2 ),
      round( (y0 + y1) / 2 )
    }
  end

end

