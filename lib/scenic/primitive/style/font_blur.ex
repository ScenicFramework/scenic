#
#  Re-Created by Boyd Multerer on November 30, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontBlur do
  use Scenic.Primitive.Style

# import IEx

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Style :font_size must be a number\r\n"
  end

  #--------------------------------------------------------
  def verify( blur ) do
    try do
      normalize( blur )
      true
    rescue
      _ -> false
    end
  end

  #--------------------------------------------------------
  def normalize( blur ) when is_number(blur) do
    blur
  end
end