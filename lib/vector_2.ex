#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Vector2 do
  alias Scenic.Math.Vector2
  alias Scenic.Math.Matrix

#  import IEx

  # a vector2 is a tuple with two dimentions. {x, y}

  # common constants
  def zero(),       do: {0.0, 0.0}
  def one(),        do: {1.0, 1.0}
  def unity_x(),    do: {1.0, 0.0}
  def unity_y(),    do: {0.0, 1.0}

  def up(),         do: {0.0, 1.0}
  def down(),       do: {0.0, -1.0}
  def left(),       do: {-1.0, 0.0}
  def right(),       do: {1.0, 0.0}

  #--------------------------------------------------------
  # build from values
  def build( x, y ) when is_float(x) and is_float(y), do: {x,y}


  #--------------------------------------------------------
  # add and subtract
  def add( a, b )
  def add({ax,ay}, {bx,by}),        do: {ax + bx, ay + by}

  def sub( a, b )
  def sub({ax,ay}, {bx,by}),        do: {ax - bx, ay - by}

  #--------------------------------------------------------
  # multiply by scalar
  def mul( a, s )
  def mul( {ax, ay}, s) when is_number(s), do: {ax * s, ay * s}

#--------------------------------------------------------
  # divide by scalar
  def div( a, s )
  def div( {ax, ay}, s) when is_number(s), do: {ax / s, ay / s}


  #--------------------------------------------------------
  # dot product
  def dot(a, b)
  def dot({ax,ay}, {bx,by}),        do: (ax * bx) + (ay * by)


  #--------------------------------------------------------
  # cross product https://www.gamedev.net/topic/289972-cross-product-of-2d-vectors/
  def cross(a, b)
  def cross({ax,ay}, {bx,by}),        do: (ax * by) - (ay * bx)

  #--------------------------------------------------------
  # length
  def length_squared( a )
  def length_squared( {ax,ay} ),    do: (ax * ax) + (ay * ay)

  def length(a)
  def length( {ax,ay} ),            do: :math.sqrt( (ax * ax) + (ay * ay) )


  #--------------------------------------------------------
  # distance
  def distance_squared( a, b )
  def distance_squared( {ax,ay}, {bx,by} ),
    do: ((bx - ax) * (bx - ax)) + ((by - ay) * (by - ay))

  def distance(a, b)
  def distance( {ax,ay}, {bx,by} ), do: :math.sqrt( distance_squared({ax,ay},{bx,by}) )


  #--------------------------------------------------------
  # normalize
  def normalize( a )
  def normalize( {ax,ay} ) do
    case Vector2.length({ax,ay}) do
      0.0 -> {ax,ay}
      len ->
        {ax / len, ay / len}
    end
  end

  #--------------------------------------------------------
  # min / max
  def min( a, b )
  def min( {ax,ay}, {bx,by} ) do
    x = cond do
      ax > bx ->  bx
      true ->     ax
    end
    y = cond do
      ay > by ->  by
      true ->     ay
    end
    {x,y}
  end

  def max( a, b )
  def max( {ax,ay}, {bx,by} ) do
    x = cond do
      ax > bx ->  ax
      true ->     bx
    end
    y = cond do
      ay > by ->  ay
      true ->     by
    end
    {x,y}
  end

  #--------------------------------------------------------
  # clamp a vector between two other vectors
  def clamp(vector, min, max)
  def clamp({vx,vy}, {minx, miny}, {maxx, maxy}) do
    x = cond do
      vx < minx ->  minx
      vx > maxx ->  maxx
      true ->       vx
    end
    y = cond do
      vy < miny ->  miny
      vy > maxy ->  maxy
      true ->       vy
    end
    {x,y}
  end


  #--------------------------------------------------------
  def in_bounds( vector, bounds )
  def in_bounds( {vx,vy}, {boundsx, boundsy} ),
    do: {vx,vy} == clamp( {vx,vy}, {-boundsx, -boundsy}, {boundsx, boundsy} )

  #--------------------------------------------------------
  def in_bounds( vector, min_bounds, max_bounds )
  def in_bounds( {vx,vy}, {minx, miny}, {maxx, maxy} ),
    do: {vx,vy} == clamp( {vx,vy}, {minx, miny}, {maxx, maxy} )

  #--------------------------------------------------------
  # lerp( a, b, t )
  # https://keithmaggio.wordpress.com/2011/02/15/math-magician-lerp-slerp-and-nlerp/
  def lerp( a, b, t ) when is_float(t) and t >= 0.0 and t <= 1.0 do
    sub(b,a)
    |> mul( t )
    |> add( a )
  end

  #--------------------------------------------------------
  # nlerp( a, b, t )
  # https://keithmaggio.wordpress.com/2011/02/15/math-magician-lerp-slerp-and-nlerp/
  def nlerp( a, b, t ) when is_float(t) and t >= 0.0 and t <= 1.0 do
    sub(b,a)
    |> mul( t )
    |> add( a )
    |> normalize()
  end

  #--------------------------------------------------------
  def project( {x,y}, matrix ) do
    Matrix.project_vector(matrix, {x,y})
  end
  
  #--------------------------------------------------------
  def project( vectors, matrix ) do
    Matrix.project_vector2s(matrix, vectors)
  end

end























