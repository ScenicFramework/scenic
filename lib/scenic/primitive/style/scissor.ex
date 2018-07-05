#
#  Created by Boyd Multerer on June 6, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Scissor do
  use Scenic.Primitive.Style

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Scissor data should be: {width, height}\r\n" <>
    "The scissor region will be positioned by the transform stack"
  end

  #--------------------------------------------------------
  # named color

  def verify( data ) do
    try do
      normalize( data )
      true
    rescue
      _ -> false
    end    
  end

  #--------------------------------------------------------

  def normalize( {w, h} ) when is_number(w) and is_number(h) do
    {w, h}
  end

end