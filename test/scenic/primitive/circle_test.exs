#
#  Created by Boyd Multerer on June 29, 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.CircleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Circle

  @data     {{10, 20}, 100}

  #============================================================================
  # build / add

  test "build works" do
    p = Circle.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Circle
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Circle.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Circle.verify( {{10, 20}, :atom} ) == :invalid_data
    assert Circle.verify( :banana )                   == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Circle.valid_styles() == [:hidden, :fill, :stroke]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the center of the arc" do
    assert Circle.default_pin(@data) == {10, 20}
  end

  #============================================================================
  # point containment
  test "contains_point? works" do
    assert Circle.contains_point?(@data, {10, 20})  == true
    assert Circle.contains_point?(@data, {10, 120})  == true
    assert Circle.contains_point?(@data, {10, 121})  == false
    assert Circle.contains_point?(@data, {110, 20})  == true
    assert Circle.contains_point?(@data, {111, 20})  == false
  end


end

