#
#  Re-Created by Boyd Multerer on November 30, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Font do
  use Scenic.Primitive.Style

# import IEx

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info( data ), do: """
    #{IO.ANSI.red()}#{__MODULE__} data must be a cache key or an atom
    #{IO.ANSI.yellow()}Received: #{inspect(data)}

    "Examples:
    :roboto             # system font
    \"w29afwkj23ry8\"   # key of font in the cache

    #{IO.ANSI.default_color()}
  """

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
  def normalize( name ) when is_atom(name),     do: name
  def normalize( key ) when is_bitstring(key),  do: key
end