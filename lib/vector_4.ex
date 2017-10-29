#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Vector4 do
  alias Scenic.Math.Vector4

  # a vector4 is a tuple with three dimentions. {x, y, z, w}

  # common constants
  def zero(),       do: {0.0, 0.0, 0.0, 0.0}
  def one(),        do: {1.0, 1.0, 1.0, 1.0}

  def unity_x(),    do: {1.0, 0.0, 0.0, 0.0}
  def unity_y(),    do: {0.0, 1.0, 0.0, 0.0}
  def unity_z(),    do: {0.0, 0.0, 1.0, 0.0}
  def unity_w(),    do: {0.0, 0.0, 0.0, 1.0}

  #--------------------------------------------------------
  # build from values
  def build( x, y, z, w ) when is_float(x) and is_float(y) and is_float(z) and is_float(w), do: {x,y,z,w}

  #--------------------------------------------------------
  # add and subtract
  def add( a, b )
  def add({ax,ay,az,aw}, {bx,by,bz,bw}),        do: {ax + bx, ay + by, az + bz, aw + bw}

  def sub( a, b )
  def sub({ax,ay,az,aw}, {bx,by,bz,bw}),        do: {ax - bx, ay - by, az - bz, aw - bw}

  #--------------------------------------------------------
  # multiply by scalar
  def mul( a, s )
  def mul( {ax,ay,az,aw}, s) when is_float(s), do: {ax * s, ay * s, az * s, aw * s}

  #--------------------------------------------------------
  # length
  def length_squared( a )
  def length_squared( {ax,ay,az,aw} ),    do: (ax * ax) + (ay * ay) + (az * az) + (aw * aw)

  def length(a)
  def length( {ax,ay,az,aw} ),            do: :math.sqrt( (ax * ax) + (ay * ay) + (az * az) + (aw * aw) )


  #--------------------------------------------------------
  # distance
  def distance_squared( a, b )
  def distance_squared( {ax,ay,az,aw}, {bx,by,bz,bw} ),
    do: ((bx - ax) * (bx - ax)) + ((by - ay) * (by - ay)) + ((bz - az) * (bz - az)) + ((bw - aw) * (bw - aw))

  def distance(a, b)
  def distance( {ax,ay,az,aw}, {bx,by,bz,bw} ),
    do: :math.sqrt( distance_squared({ax,ay,az,aw}, {bx,by,bz,bw}) )


  #--------------------------------------------------------
  # dot product
  def dot(a, b)
  def dot({ax,ay,az,aw}, {bx,by,bz,bw}),    do: (ax * bx) + (ay * by) + (az * bz) + (aw * bw)

  #--------------------------------------------------------
  # normalize
  def normalize( a )
  def normalize( {ax,ay,az,aw} ) do
    case Vector4.length({ax,ay,az,aw}) do
      0.0 -> {ax,ay,az,aw}
      len ->
        {ax / len, ay / len, az / len, aw / len}
    end
  end

  #--------------------------------------------------------
  # min / max

  def min( a, b )
  def min( {ax,ay,az,aw}, {bx,by,bz,bw} ) do
    x = cond do
      ax > bx ->  bx
      true ->     ax
    end
    y = cond do
      ay > by ->  by
      true ->     ay
    end
    z = cond do
      az > bz ->  bz
      true ->     az
    end
    w = cond do
      aw > bw ->  bw
      true ->     aw
    end
    {x,y,z,w}
  end

  def max( a, b )
  def max( {ax,ay,az,aw}, {bx,by,bz,bw} ) do
    x = cond do
      ax > bx ->  ax
      true ->     bx
    end
    y = cond do
      ay > by ->  ay
      true ->     by
    end
    z = cond do
      az > bz ->  az
      true ->     bz
    end
    w = cond do
      aw > bw ->  aw
      true ->     bw
    end
    {x,y,z,w}
  end

  #--------------------------------------------------------
  # clamp a vector between two other vectors
  def clamp(vector, min, max)
  def clamp({vx,vy,vz,vw}, {minx, miny, minz, minw}, {maxx, maxy, maxz, maxw}) do
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
    z = cond do
      vz < minz ->  minz
      vz > maxz ->  maxz
      true ->       vz
    end
    w = cond do
      vw < minw ->  minw
      vw > maxw ->  maxw
      true ->       vw
    end
    {x,y,z,w}
  end

  #--------------------------------------------------------
  def in_bounds( vector, bounds )
  def in_bounds( {vx,vy,vz,vw}, {bdx, bdy, bdz, bdw} ),
    do: {vx,vy,vz,vw} == clamp( {vx,vy,vz,vw}, {-bdx,-bdy,-bdz,-bdw}, {bdx,bdy,bdz,bdw} )

  #--------------------------------------------------------
  def in_bounds( vector, min_bounds, max_bounds )
  def in_bounds( {vx,vy,vz,vw}, {minx, miny, minz, minw}, {maxx, maxy, maxz, maxw} ),
    do: {vx,vy,vz,vw} == clamp( {vx,vy,vz,vw}, {minx,miny,minz,minw}, {maxx,maxy,maxz,maxw} )


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
end
