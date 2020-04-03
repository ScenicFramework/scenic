#
#  Created by Boyd Multerer on 2018-06-29.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.CircleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Circle

  @data 100

  # ============================================================================
  # build / add

  test "build works" do
    p = Circle.build(@data)
    assert p.module == Circle
    assert Primitive.get(p) == @data
  end

  # ============================================================================
  # verify

  test "info works" do
    assert Circle.info(:test_data) =~ ":test_data"
  end

  test "verify passes valid data" do
    assert Circle.verify(@data) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Circle.verify({{10, 20}, :atom}) == :invalid_data
    assert Circle.verify(:banana) == :invalid_data
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Circle.valid_styles() == [:hidden, :fill, :stroke]
  end

  # ============================================================================
  # transform helpers

  test "default_pin returns the center of the arc" do
    assert Circle.default_pin(@data) == {0, 0}
  end

  # ============================================================================
  # point containment
  test "contains_point? works" do
    assert Circle.contains_point?(@data, {0, 0}) == true
    assert Circle.contains_point?(@data, {0, 100}) == true
    assert Circle.contains_point?(@data, {0, 101}) == false
    assert Circle.contains_point?(@data, {100, 0}) == true
    assert Circle.contains_point?(@data, {101, 0}) == false
  end
end
