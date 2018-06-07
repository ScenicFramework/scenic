#
#  Re-Created by Boyd Multerer on November 30, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontSize do
  use Scenic.Primitive.Style

# import IEx

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Style :font_size must be a number >= 26\r\n" <>
    "Many different sizes, or large sizes consume more memory.\r\n" <>
    "The default size is usually 14."
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
  def normalize( point_size ) when is_number(point_size) and point_size >= 6 do
    point_size
  end
end