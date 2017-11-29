#
#  Created by Boyd Multerer on Noveber 16, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Texture do
  use Scenic.Primitive
  alias Scenic.Math
  alias Scenic.Cache
  alias Scenic.Primitive.Triangle
  alias Scenic.Primitive.Quad

#  import IEx

  @styles   [:hidden, :color, :border_color, :border_width]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Texture data must be a (point or rect or quad) and a cache key: {{x0,y0}, {x1,y1}, {x2,y2}, {x3,y3}, key}"

  def verify( data ) do
    try do
      {quad,_,_} = normalize(data)
      case Math.Quad.classification(quad) == :convex do
        true  -> {:ok, data}
        false -> :invalid_data
      end
    rescue
      _ -> :invalid_data
    end
  end
  def verify( _ ), do: :invalid_data


  #--------------------------------------------------------
  def normalize({{x0, y0},w,h,key}) do
    quad = { {x0, y0}, {x0+w, y0}, {x0+w, y0+h}, {x0, y0+h} }
    normalize({quad,key})
  end
  def normalize({{{x0, y0},w,h},key}),    do: normalize({{x0, y0},w,h,key})
  def normalize({quad,key}),              do: normalize({quad,{{0,0},{1,0},{1,1},{0,1}},key})
  def normalize( {{{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}, {{s0, t0}, {s1, t1}, {s2, t2}, {s3, t3}}, key} = data )
  when is_bitstring(key) and
  is_number(x0) and is_number(y0) and
  is_number(x1) and is_number(y1) and
  is_number(x2) and is_number(y2) and
  is_number(x3) and is_number(y3) and
  is_number(s0) and is_number(t0) and
  is_number(s1) and is_number(t1) and
  is_number(s2) and is_number(t2) and
  is_number(s3) and is_number(t3), do: data

  #============================================================================
  def valid_styles(), do: @styles

  #--------------------------------------------------------
  def default_pin( data ) do
    {quad,_,_} = normalize(data)
    Quad.default_pin( quad )
  end

  #------------------------------------
  def expand(data, width) do
    {quad,tx_quad,key} = normalize(data)
    quad = Quad.expand( quad )
    {quad,tx_quad,key}
  end

  #--------------------------------------------------------
  def contains_point?( data, px ) do
    {quad,_,_} = normalize(data)
    Quad.contains_point?(quad, px)
  end


end








