#
#  Created by Boyd Multerer on 10/25/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.ClearColor do
  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Color


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Style :clear_color only honored on the root node of a graph.\n" <>
    "It must be qualified single color. Please see documentation for color.\n" <>
    "Any single color can be specified\ by name, such as :red, :green, or :cornflower_blue.\n" <>
    "All standard html colors should work.\n" <>
    "Specify the RGB channels in a tuple, like this: {1, 2, 3}. Channels range from 0 to 255.\n" <>
    "You can add an alpha channel like this: {:orange, 128} or {1, 2, 3, 4}.\n"
  end

  #--------------------------------------------------------
  # named color

  def verify( color ) do
    try do
      normalize( color )
      true
    rescue
      _ -> false
    end    
  end

  #--------------------------------------------------------

  def normalize( color )   when is_atom(color),  do: {Color.to_rgba( color )}
  def normalize( {color} ) when is_atom(color),  do: {Color.to_rgba( color )}

  def normalize( {color, alpha} )  when is_atom(color) and is_integer(alpha), do: normalize( {{color, alpha}} )
  def normalize( {{color, alpha}} ), do: {Color.to_rgba( {color, alpha} )}

  def normalize( {r,g,b} ) when is_integer(r) and is_integer(g) and is_integer(b), do: normalize( {{r,g,b}} )
  def normalize( {{r,g,b}} ), do: {Color.to_rgba( {r,g,b} )}

  def normalize( {r,g,b,a} ) when is_integer(r) and is_integer(g) and is_integer(b) and is_integer(a), do:
    normalize( {{r,g,b,a}} )
  def normalize( {{r,g,b,a}} ), do: {Color.to_rgba( {r,g,b,a} )}


  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( color, _ ) do
    {{r,g,b,a}} = normalize( color )
    <<
      1 :: size(8),
      r ::  unsigned-integer-size(8),
      g ::  unsigned-integer-size(8),
      b ::  unsigned-integer-size(8),
      a ::  unsigned-integer-size(8)
    >>    
  end

  #--------------------------------------------------------
  # note: deserialize only works on a single color at a time
  # the caller needs to call repeatedly for a multi-color

  def deserialize( binary_data, order \\ :native )
  def deserialize( <<
      1 :: size(8),
      r0 :: size(8), g0 :: size(8), b0 :: size(8), a0 :: size(8),
      bin :: binary
    >>, _ ) do
    {:ok, {{r0,g0,b0,a0}}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


end