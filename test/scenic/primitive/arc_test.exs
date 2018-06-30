#
#  Created by Boyd Multerer on June 29, 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.ArcTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Arc

  @data     {{10, 20}, 100, 0.0, 1.4}

  #============================================================================
  # build / add

  test "build works" do
    p = Arc.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Arc
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Arc.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Arc.verify( {{10, 20}, :atom, 0.0, 1.4} ) == :invalid_data
    assert Arc.verify( :banana )                   == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Arc.valid_styles() == [:hidden, :fill, :stroke]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the center of the arc" do
    assert Arc.default_pin(@data) == {10, 20}
  end

 test "expand makes the radius larger" do
   assert Arc.expand(@data, 10) == {{10, 20}, 110, 0.0, 1.4}
 end

  #============================================================================
  # point containment
  test "contains_point? always returns false" do
    assert Arc.contains_point?(@data, {30, 52})  == false
    assert Arc.contains_point?(@data, {10,12})   == false
    assert Arc.contains_point?(@data, {40, 80})  == false
  end


end

