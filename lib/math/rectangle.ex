#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Rectangle do

  # rectangle is defined as a tuple: {x, y, width, height}

  #----------------------------------------------------------------------------
  # build new
  def build( opts ) when is_list(opts), do: build( Enum.into(opts, %{}) )
  def build( %{x: x, y: y, width: width, height: height} ) do
    { x, y, width, height }
  end
  def build( %{left: left, top: top, right: right, bottom: bottom} ), do:
    { left, top, (right - left), (bottom - top) }


  #============================================================================
  # operations that inspect rectangles

  #--------------------------------------------------------
  def location( {x, y, _, _} ),   do: { x, y }
  
  #--------------------------------------------------------
  def center( {x, y, w, h} ),     do: {x + (w / 2), y + (h / 2)}
  
  #--------------------------------------------------------
  def is_empty?( {_, _, 0, 0} ),      do: true
  def is_empty?( {_, _, 0.0, 0.0} ),  do: true
  def is_empty?( _ ),  do: false

  #--------------------------------------------------------
  def contains?( rect, {{vx, vy},{vw, vh}} ), do: contains?(rect, {vx, vy, vw, vh})
  def contains?( {x, y, w, h}, {cx, cy, cw, ch} ) do 
    (x <= cx) &&
    ((cx + cw) <= (x + w)) &&
    (y <= cy) &&
    ((cy + ch) <= (y + h))
  end

  #--------------------------------------------------------
  def intersects?( rect, {{vx, vy},{vw, vh}} ), do: intersects?(rect, {vx, vy, vw, vh})
  def intersects?( {x, y, w, h}, {ix, iy, iw, ih} ) do 
    (ix < (x + w)) &&
    (x < (ix + iw)) &&
    (iy < (y + h)) &&
    (y < (iy + ih))
  end


  #============================================================================
  # operations that mutate rectangles

  #--------------------------------------------------------
  def normalize( rect ) do
    {l, t, r, b} = to_ltrb( rect )
    {l, t, r, b} = cond do
      l <= r -> {l, t, r, b}
      true ->  {r, t, l, b}
    end
    {l, t, r, b} = cond do
      t <= b -> {l, t, r, b}
      true ->  {l, b, r, t}
    end
    from_ltrb( {l, t, r, b} )
  end

  #--------------------------------------------------------
  def inflate( {x, y, w, h}, ix, iy ),  do: {(x - ix), (y - iy), (w + ix), (h + iy)}

  #--------------------------------------------------------
  def offset( {x, y, w, h}, ox, oy ),   do: {(x + ox), (y + oy), w, h}

  #--------------------------------------------------------
  def intersect( rect_a, rect_b ) do
    {xa,ya,ra,ba} = to_ltrb( rect_a )
    {xb,yb,rb,bb} = to_ltrb( rect_b )

    # find the greater of the left/top sides
    max_x = cond do
      xa > xb -> xa
      true -> xb
    end
    max_y = cond do
      ya > yb -> ya
      true -> yb
    end

    # find the lesser of the right/bottom sides
    min_right = cond do
      ra < rb -> ra
      true -> rb
    end
    min_bottom = cond do
      ba < bb -> ba
      true -> bb
    end

    # calculate the final intersection
    cond do
      (min_right > max_x) && (min_bottom > max_y) ->    # calc interior width and height
        {max_x, max_y, (min_right - max_x), (min_bottom - max_y)}
      true ->                                           # no intersection
        {0,0,0,0}   
    end
  end

  #--------------------------------------------------------
  def union( rect_a, rect_b ) do
    {xa,ya,ra,ba} = to_ltrb( rect_a )
    {xb,yb,rb,bb} = to_ltrb( rect_b )

    # find the lesser of the left/top sides
    min_x = cond do
      xa < xb -> xa
      true -> xb
    end
    min_y = cond do
      ya < yb -> ya
      true -> yb
    end

    # find the greater of the right/bottom sides
    max_right = cond do
      ra > rb -> ra
      true -> rb
    end
    max_bottom = cond do
      ba > bb -> ba
      true -> bb
    end

    # calculate the final union
    {min_x, min_y, (max_right - min_x), (max_bottom - min_y)}
  end

  #============================================================================
  # helper functions - maybe make private?
  def to_ltrb( {x, y, w, h} ),    do: {x, y, (x + w), (y + h)}
  def to_ltrb( x, y, w, h ),      do: to_ltrb( {x, y, w, h} )

  def from_ltrb( {l, t, r, b} ),  do: {l, t, (r - l), (b - t)}
  def from_ltrb( l, t, r, b ),    do: from_ltrb( {l, t, r, b} )


end

































