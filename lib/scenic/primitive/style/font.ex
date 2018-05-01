#
#  Re-Created by Boyd Multerer on November 30, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Font do
  use Scenic.Primitive.Style

# import IEx

  @default_point_size     14


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Style :font must be in the form {key_or_name, point_size}\r\n" <>
    "Example: {:roboto, 14}"
  end

  #--------------------------------------------------------
  def verify( font ) do
    try do
      normalize( font )
      true
    rescue
      _ -> false
    end
  end

  #--------------------------------------------------------
  def normalize( name ) when is_atom(name),     do: normalize( {name, @default_point_size} )
  def normalize( key ) when is_bitstring(key),  do: normalize( {key, @default_point_size} )
  def normalize( {name, point_size} ) when is_integer(point_size) and
  point_size >=2 do # and point_size <= 80
    {name, point_size}
  end
end