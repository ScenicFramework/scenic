#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.LineStipple do
  use Scenic.Primitive.Style
#  alias Scenic.Primitive.Style

#  @dflag            Style.dflag()
#  @type_code        0x0020



  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Style :line_stipple must be a named stipple or a tuple of {factor, pattern}\r\n" <>
    "see: https://www.khronos.org/registry/OpenGL-Refpages/gl2.1/xhtml/glLineStipple.xml\r\n" <>
    "also: http://www.glprogramming.com/red/chapter02.html"
  end

  #--------------------------------------------------------
  def verify( stipple ) do
    try do
      normalize( stipple )
      true
    rescue
      _ -> false
    end
  end

  #--------------------------------------------------------
  # normalize named stipples
  def normalize( name ) when is_atom(name),  do: normalize( {1, name} )
  def normalize( {factor, name} ) when is_integer(factor) and is_atom(name) and
  factor > 0 and factor < 256 do
    {factor, to_pattern(name)}
  end
  def normalize( {factor, pattern} ) when is_integer(factor) and is_integer(pattern) and
  factor > 0 and factor < 256 do
    {factor, pattern}
  end

  #--------------------------------------------------------
  # resolve named stipples

  defp to_pattern( :dot ),              do: 0xAAAA
  defp to_pattern( :dash ),             do: 0x0FFF
  defp to_pattern( :dash_dot ),         do: 0x1C47

end