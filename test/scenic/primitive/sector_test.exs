#
#  Created by Boyd Multerer on June 29, 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.SectorTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Sector



  @data     {{10, 20}, 100, 0.0, 1.4}

  #============================================================================
  # build / add

  test "build works" do
    p = Sector.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Sector
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Sector.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Sector.verify( {{10, 20}, :atom, 0.0, 1.4} ) == :invalid_data
    assert Sector.verify( :banana ) == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Sector.valid_styles() == [:hidden, :fill, :stroke]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the center of the arc" do
    assert Sector.default_pin(@data) == {10, 20}
  end

  #============================================================================
  # point containment
  test "contains_point? always returns false" do
    assert Sector.contains_point?(@data, {30, 52})  == true
    assert Sector.contains_point?(@data, {-30, 52}) == false
    assert Sector.contains_point?(@data, {40, 80})  == true
    assert Sector.contains_point?(@data, {140, 300})  == false

    # straight up or down is a degenerate case
    assert Sector.contains_point?(@data, {10, 10})  == false
    assert Sector.contains_point?(@data, {10, 30})  == false
  end


end

