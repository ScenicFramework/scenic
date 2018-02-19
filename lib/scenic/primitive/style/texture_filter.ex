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
    "{:min, :nearest}, or {:mag, :linear}\r\n" <>
    "Or both axes at the same time like this\r\n" <>
    "[{:min, :nearest}, {:mag, :linear}]\r\n"
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
  def normalize( nil ), do: [min: :linear, mag: :linear]
  def normalize( filter ) when is_atom(filter), do: normalize([min: filter, mag: filter])
  def normalize( {:min, filter} ) when is_atom(filter), do: normalize([min: filter, mag: :linear])
  def normalize( {:mag, filter} ) when is_atom(filter), do: normalize([min: :linear, mag: filter])
  
  def normalize( filter ) when is_list(filter) do
    min = case filter[:min] do
      :nearest -> :nearest
      :linear -> :linear
      nil -> :linear
    end
    mag = case filter[:mag] do
      :nearest -> :nearest
      :linear -> :linear
      nil -> :linear
    end
    [min: min, mag: mag]
  end
  
end