#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Stroke do
  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Paint

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Style :stroke must be a width and color/pattern.\r\n" <>
    "This is very similar to the :fill style. except that there\r\n" <>
    "is an added width in the front\r\n" <>
    "{12, :red}\r\n" <>
    "{12, {0x64, 0x95, 0xED, 0xFF}}\r\n"
  end

  #--------------------------------------------------------
  # named color

  def verify( stroke ) do
    try do
      normalize( stroke )
      true
    rescue
      _ -> false
    end    
  end

  #--------------------------------------------------------

  def normalize( {width, paint} ) when is_number(width) and width >= 0 do
    { width, Paint.normalize(paint) }
  end

end