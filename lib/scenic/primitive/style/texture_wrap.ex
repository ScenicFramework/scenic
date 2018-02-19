#
#  Created by Boyd Multerer on 2/18/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextureWrap do
  use Scenic.Primitive.Style
#  alias Scenic.Primitive.Style

#  @dflag            Style.dflag()
#  @type_code        0x0020


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Style :texture_wrap must be one of the following values\r\n" <>
    ":repeat\r\n" <>
    ":mirrored_repeat\r\n" <>
    ":clamp_to_edge\r\n" <>
    ":clamp_to_border\r\n" <>
    "The default if :texture_wrap is not specified is the same as :repeat\r\n" <>
    "You can specify wrapping for either the horizontal or vertical axis like this\r\n" <>
    "{:h, :repeat}, or {:v, :mirrored_repeat}\r\n" <>
    "Or both axes at the same time like this\r\n" <>
    "[{:h, :repeat}, {:v, :clamp_to_border}]\r\n"
  end

  #--------------------------------------------------------
  def verify( texture_wrap ) do
    try do
      normalize( texture_wrap )
      true
    rescue
      _ -> false
    end
  end

  #--------------------------------------------------------
  def normalize( texture_wrap )
  def normalize( wrap ) when is_atom(wrap), do: normalize([h: wrap, v: wrap])
  def normalize( {:h, wrap} ) when is_atom(wrap), do: normalize([h: wrap, v: :repeat])
  def normalize( {:v, wrap} ) when is_atom(wrap), do: normalize([h: :repeat, v: wrap])
  
  def normalize( wraps ) when is_list(wraps) do
    h = case wraps[:h] do
      :repeat -> :repeat
      :mirrored_repeat -> :mirrored_repeat
      :clamp_to_edge -> :clamp_to_edge
      :clamp_to_border -> :clamp_to_border
      nil -> :repeat
    end
    v = case wraps[:v] do
      :repeat -> :repeat
      :mirrored_repeat -> :mirrored_repeat
      :clamp_to_edge -> :clamp_to_edge
      :clamp_to_border -> :clamp_to_border
      nil -> :repeat
    end
    [h: h, v: v]
  end

end