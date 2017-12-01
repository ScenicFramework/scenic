#
#  Re-Created by Boyd Multerer on November 30, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Font do
  use Scenic.Primitive.Style
  alias Scenic.Cache
#  alias Scenic.Primitive.Style

 import IEx

  @default_point_size     12


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
  def normalize( {name, size} ) when is_atom(name) do
    {:ok, key} = Cache.Font.system_font_key(name)
    normalize( {key, size} )
  end

  def normalize( {key, point_size} ) when is_bitstring(key) and
  is_integer(point_size) and point_size >=2 and point_size <= 80 do
    if byte_size(key) > 255 do
      raise ArgumentError
    end
    {key, point_size}
  end

end