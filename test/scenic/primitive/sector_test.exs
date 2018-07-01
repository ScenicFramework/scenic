#
#  Created by Boyd Multerer on June 29, 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.SectorTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Sector



  # @data     {{10, 20}, 100, 0.0, 1.4}
  @data     {100, 0.0, 1.4}

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
    assert Sector.verify( {:atom, 0.0, 1.4} ) == :invalid_data
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
    assert Sector.default_pin(@data) == {0, 0}
  end

  #============================================================================
  # point containment
  test "contains_point? always returns false" do
    assert Sector.contains_point?(@data, {20, 32})  == true
    assert Sector.contains_point?(@data, {-20, 32}) == false
    assert Sector.contains_point?(@data, {30, 60})  == true
    assert Sector.contains_point?(@data, {130, 280})  == false
  end

  test "contains_point? straight up and down" do
    # make it big enough to catch the straight down case
    data = {100, 0.0, 2}
    # straight up or down is a degenerate case
    assert Sector.contains_point?(data, {0, -10})  == false
    assert Sector.contains_point?(data, {0, 10})  == true

    assert Sector.contains_point?(data, {0, -101})  == false
    assert Sector.contains_point?(data, {0, 101})  == false
  end

  test "contains_point? straight side to side" do
    # prob not denerate, but might as well check
    assert Sector.contains_point?(@data, {-10, 0})  == false
    assert Sector.contains_point?(@data, {10, 0})  == true

    assert Sector.contains_point?(@data, {-101, 0})  == false
    assert Sector.contains_point?(@data, {101, 0})  == false
  end


end

