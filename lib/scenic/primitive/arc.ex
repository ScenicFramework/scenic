#
#  Created by Boyd Multerer on June 6, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Arc do
  use Scenic.Primitive
  alias Scenic.Primitive.Sector
  alias Scenic.Primitive.Triangle

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :fill, :stroke]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Arc should look like this: {{0,y}, radius, start, finish}\r\n" <>
  "Add a scale transform to make it an arc along an ellipse"

  #--------------------------------------------------------
  def verify( data ) do
    try do
      normalize(data)
      {:ok, data}
    rescue
      _ -> :invalid_data
    end
  end


  #--------------------------------------------------------
  def normalize( {{x, y}, radius, start, finish} = data ) when
  is_number(x) and is_number(y) and
  is_number(start) and is_number(finish) and
  is_number(radius), do: data


  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def default_pin( data ) do
    {{x, y},_,_,_} = normalize(data)
    {x,y}
  end

  #--------------------------------------------------------
  def expand( {{x, y},r,s,f}, amount ) do
    {{x, y},r + amount,s,f}
  end

  #--------------------------------------------------------
  def contains_point?( {{x, y} = p0, radius, start, finish} = data, pt ) do
    # first, see if it is in the sector described by the arc data
    if Sector.contains_point?(data, pt) do
      # See if it is NOT in the triangle part of sector.
      # If it isn't in the triangle, then it must be in the arc part.
      p1 = {
        x + radius * :math.cos(start),
        y + radius * :math.sin(start)
      }
      p2 = {
        x + radius * :math.cos(finish),
        y + radius * :math.sin(finish)
      }
      !Triangle.contains_point?( {p0,p1,p2}, pt )
    else
      false
    end
  end


end