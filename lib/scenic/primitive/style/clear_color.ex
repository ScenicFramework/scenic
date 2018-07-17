#
#  Created by Boyd Multerer on 10/25/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.ClearColor do
  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Paint.Color


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
  def normalize( color ),  do: Color.to_rgba( color )

end