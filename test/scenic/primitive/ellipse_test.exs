#
#  Created by Boyd Multerer on June 29, 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.EllipseTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Ellipse

  @data     {{10, 20}, 100, 200}

  #============================================================================
  # build / add

  test "build works" do
    p = Ellipse.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Ellipse
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Ellipse.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Ellipse.verify( {{10, 20}, :atom, 0.0, 1.4} ) == :invalid_data
    assert Ellipse.verify( :banana )                   == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Ellipse.valid_styles() == [:hidden, :fill, :stroke]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the center of the arc" do
    assert Ellipse.default_pin(@data) == {10, 20}
  end

  #============================================================================
  # point containment
  test "contains_point? works" do
    assert Ellipse.contains_point?(@data, {30, 52})  == true
    assert Ellipse.contains_point?(@data, {109,20})   == true
    assert Ellipse.contains_point?(@data, {110,20})   == true
    assert Ellipse.contains_point?(@data, {111,20})   == false
    assert Ellipse.contains_point?(@data, {10, 219})  == true
    assert Ellipse.contains_point?(@data, {10, 220})  == true
    assert Ellipse.contains_point?(@data, {10, 221})  == false
  end


end


