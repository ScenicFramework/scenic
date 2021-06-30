#
#  Created by Boyd Multerer on 2018-06-29.
#  Copyright © 2018 - 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.CircleTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Circle

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

  test "validate accepts valid data" do
    assert Circle.validate(40) == {:ok, 40}
    assert Circle.validate(40.5) == {:ok, 40.5}
  end

  test "validate rejects bad data" do
    {:error, msg} = Circle.validate("40.5")
    assert msg =~ "Invalid Circle"

    {:error, msg} = Circle.validate(:banana)
    assert msg =~ "Invalid Circle"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Circle.valid_styles() == [:hidden, :fill, :stroke_width, :stroke_fill]
  end

  # ============================================================================
  # compile

  test "compile works" do
    p = Circle.build(@data)
    assert Circle.compile(p, %{stroke_fill: :blue}) == [{:draw_circle, {100, :stroke}}]
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
