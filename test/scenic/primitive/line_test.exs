#
#  Created by Boyd Multerer on 5/8/17. Re-written on 11/01/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.LineTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Line


  @data     {{10,12}, {40, 80}}


  #============================================================================
  # build / add

  test "build works" do
    p = Line.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Line
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Line.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Line.verify( {{10,12}, 40, 80} )         == :invalid_data
    assert Line.verify( {10,12, 40, 80} )           == :invalid_data
    assert Line.verify( {10, 40, 80} )              == :invalid_data
    assert Line.verify( {{10,12}, {40, :banana}} )  == :invalid_data
    assert Line.verify( {{10,:banana}, {40, 80}} )  == :invalid_data
    assert Line.verify( :banana )                   == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Line.valid_styles() == [:hidden, :color, :line_width, :line_stipple]
  end

  #============================================================================
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

  #============================================================================
  # point containment
  test "contains_point? always returns false" do
    assert Line.contains_point?(@data, {30, 52})  == false
    assert Line.contains_point?(@data, {10,12})   == false
    assert Line.contains_point?(@data, {40, 80})  == false
  end

end

