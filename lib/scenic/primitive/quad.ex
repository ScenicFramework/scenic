#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Quad do
  use Scenic.Primitive
  alias Scenic.Math

#  alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :color, :border_color, :border_width]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Quad data must be four points, like this: {{x0,y0}, {x1,y1}, {x2,y2}, {x3,y3}}"

  def verify( {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}} ) when
    is_number(x0) and is_number(y0) and
    is_number(x1) and is_number(y1) and
    is_number(x2) and is_number(y2) and
    is_number(x3) and is_number(y3), do: true
  def verify( _ ), do: false


  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}, :native ) do
    { :ok,
      <<
        x0      :: integer-size(16)-native,
        y0      :: integer-size(16)-native,
        x1      :: integer-size(16)-native,
        y1      :: integer-size(16)-native,
        x2      :: integer-size(16)-native,
        y2      :: integer-size(16)-native,
        x3      :: integer-size(16)-native,
        y3      :: integer-size(16)-native
      >>
    }
  end
  def serialize( {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}, :big ) do
    { :ok,
      <<
        x0      :: integer-size(16)-big,
        y0      :: integer-size(16)-big,
        x1      :: integer-size(16)-big,
        y1      :: integer-size(16)-big,
        x2      :: integer-size(16)-big,
        y2      :: integer-size(16)-big,
        x3      :: integer-size(16)-big,
        y3      :: integer-size(16)-big
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
      x3      :: integer-size(16)-native,
      y3      :: integer-size(16)-native,
      bin     :: binary
    >>, :native ) do
    {:ok, {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}, bin}
  end
  def deserialize( <<
      x0      :: integer-size(16)-big,
      y0      :: integer-size(16)-big,
      x1      :: integer-size(16)-big,
      y1      :: integer-size(16)-big,
      x2      :: integer-size(16)-big,
      y2      :: integer-size(16)-big,
      x3      :: integer-size(16)-big,
      y3      :: integer-size(16)-big,
      bin     :: binary
    >>, :big ) do
    {:ok, {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }

  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def default_pin( data )
  def default_pin( {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}} ) do
    {
      round( (x0 + x1 + x2 + x3) / 4 ),
      round( (y0 + y1 + y2 + y3) / 4 ),
    }
  end


  #------------------------------------
  def expand({p0, p1, p2, p3}, width) do
    # find the new parallel lines
    l01 = Math.Line.parallel( {p0, p1}, width )
    l12 = Math.Line.parallel( {p1, p2}, width )
    l23 = Math.Line.parallel( {p2, p3}, width )
    l30 = Math.Line.parallel( {p3, p0}, width )

    # calc the new poins from the intersections of the lines
    p0 = Math.Line.intersection( l30, l01 )
    p1 = Math.Line.intersection( l01, l12 )
    p2 = Math.Line.intersection( l12, l23 )
    p3 = Math.Line.intersection( l23, l30 )

    # return the expanded quad
    {p0, p1, p2, p3}
  end

end