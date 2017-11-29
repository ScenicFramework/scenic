#
#  Created by Boyd Multerer on Noveber 16, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Texture do
  use Scenic.Primitive
  alias Scenic.Math
  alias Scenic.Cache
  alias Scenic.Primitive.Triangle

#  import IEx

  @styles   [:hidden, :color, :border_color, :border_width]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Texture data must be a (point or rect or quad) and a cache key: {{x0,y0}, {x1,y1}, {x2,y2}, {x3,y3}, key}"

  def verify( {quad, key} ) do
    verify( {quad, {{0,0},{1,0},{1,1},{0,1}}, key} )
  end
  def verify( {{{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}, {{s0, t0}, {s1, t1}, {s2, t2}, {s3, t3}}, key} = data )
  when is_bitstring(key) and
  is_number(x0) and is_number(y0) and
  is_number(x1) and is_number(y1) and
  is_number(x2) and is_number(y2) and
  is_number(x3) and is_number(y3) and
  is_number(s0) and is_number(t0) and
  is_number(s1) and is_number(t1) and
  is_number(s2) and is_number(t2) and
  is_number(s3) and is_number(t3) do
    case Math.Quad.classification({{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}) == :convex do
      true  -> {:ok, data}
      false -> :invalid_data
    end
  end
  def verify( _ ), do: :invalid_data


  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3},_}, :native ) do
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
  def serialize( {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3},_}, :big ) do
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
  def default_pin( {{p0,p1,p2,p3}, _} ),    do: do_default_pin( p0, p1, p2, p3 )
  def default_pin( {{p0,p1,p2,p3}, _, _} ), do: do_default_pin( p0, p1, p2, p3 )

  defp do_default_pin( {x0, y0}, {x1, y1}, {x2, y2}, {x3, y3} ) do
    {
      round( (x0 + x1 + x2 + x3) / 4 ),
      round( (y0 + y1 + y2 + y3) / 4 ),
    }
  end



  #------------------------------------
  def expand({p0, p1, p2, p3, key}, width) do
    # account for the winding of quad - assumes convex, which is checked above
    cross = Math.Vector2.cross(
      Math.Vector2.sub(p1, p0),
      Math.Vector2.sub(p3, p0)
    )
    width = cond do
      cross < 0 -> -width
      true      -> width
    end

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
    {p0, p1, p2, p3, key}
  end

  #--------------------------------------------------------
  def contains_point?( {p0, p1, p2, p3, _}, px ) do
    # assumes convex, which is verified above
    Triangle.contains_point?({p0, p1, p2}, px) || Triangle.contains_point?({p1, p2, p3}, px)
  end


end








