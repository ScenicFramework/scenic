#
#  Created by Boyd Multerer on 2/18/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextureFilter do
  use Scenic.Primitive.Style
#  alias Scenic.Primitive.Style

#  @dflag            Style.dflag()
#  @type_code        0x0020


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Style :texture_filter must be one of the following values\r\n" <>
    ":nearest\r\n" <>
    ":linear\r\n" <>
    "The default if :texture_filter is not specified is the same as :linear\r\n" <>
    "You can specify wrapping for either the horizontal or vertical axis like this\r\n" <>
    "{:h, :nearest}, or {:v, :linear}\r\n" <>
    "Or both axes at the same time like this\r\n" <>
    "[{:h, :nearest}, {:v, :linear}]\r\n"
  end

  #--------------------------------------------------------
  def verify( texture_filter ) do
    try do
      normalize( texture_filter )
      true
    rescue
      _ -> false
    end
  end

  #--------------------------------------------------------
  def normalize( texture_filter )
  def normalize( nil ), do: [h: :linear, v: :linear]
  def normalize( filter ) when is_atom(filter), do: normalize([h: filter, v: filter])
  def normalize( {:h, filter} ) when is_atom(filter), do: normalize([h: filter, v: :linear])
  def normalize( {:v, filter} ) when is_atom(filter), do: normalize([h: :linear, v: filter])
  
  def normalize( filter ) when is_list(filter) do
    h = case filter[:h] do
      :nearest -> :nearest
      :linear -> :linear
    end
    v = case filter[:v] do
      :nearest -> :nearest
      :linear -> :linear
    end
    [h: h, v: v]
  end



end