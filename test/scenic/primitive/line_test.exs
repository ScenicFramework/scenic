#
#  Created by Boyd Multerer on 2017-05-08. 
#  Re-written on 11/01/17
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.LineTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Line

  alias Scenic.Primitive
  alias Scenic.Primitive.Line

  @data {{10, 12}, {40, 80}}

  # ============================================================================
  # build / add

  test "build works" do
    p = Line.build(@data)
    assert p.module == Line
    assert Primitive.get(p) == @data
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert Line.validate({{10, 12}, {40, 80}}) == {:ok, {{10, 12}, {40, 80}}}
    assert Line.validate({{10.5, 12}, {40, 80}}) == {:ok, {{10.5, 12}, {40, 80}}}
  end

  test "validate rejects bad data" do
    {:error, msg} = Line.validate({{"10.5", 12}, {40, 80}})
    assert msg =~ "Invalid Line"

    {:error, msg} = Line.validate( :banana )
    assert msg =~ "Invalid Line"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Line.valid_styles() == [:hidden, :stroke_width, :stroke_fill, :cap]
  end

  # ============================================================================
  # compile

  test "compile works" do
    p = Line.build(@data )
    assert Line.compile(p, %{stroke_fill: :blue}) == [{:draw_line, {10, 12, 40, 80, :stroke}}]
  end


  # ============================================================================
  # transform helpers

  test "default_pin returns the center of the line" do
    assert Line.default_pin(@data) == {25, 46}
  end

  test "centroid returns the center of the line" do
    assert Line.centroid(@data) == {25, 46}
  end

  #  test "expand makes the line longer" do
  #    assert Line.expand({{100,100},{200,100}}, 10) == {{90,100},{220,100}}
  #    assert Line.expand({{100,100},{100,200}}, 10) == {{100,90},{100,210}}
  #  end

  # ============================================================================
  # point containment
  test "contains_point? always returns false" do
    assert Line.contains_point?(@data, {30, 52}) == false
    assert Line.contains_point?(@data, {10, 12}) == false
    assert Line.contains_point?(@data, {40, 80}) == false
  end
end
