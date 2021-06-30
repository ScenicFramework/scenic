#
#  Created by Boyd Multerer on 2018-06-29.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.SectorTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Sector

  alias Scenic.Primitive
  alias Scenic.Primitive.Sector

  @data {100, 1.4}

  # ============================================================================
  # build / add

  test "build works" do
    p = Sector.build(@data)
    assert p.module == Sector
    assert Primitive.get(p) == @data
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert Sector.validate(@data) == {:ok, @data}
  end

  test "validate rejects the old format - with help" do
    {:error, msg} = Sector.validate({100, 1.4, 6})
    assert msg =~ "Sector has changed"
  end

  test "validate rejects bad data" do
    {:error, msg} = Sector.validate({100, "1.4"})
    assert msg =~ "Invalid Sector"

    {:error, msg} = Sector.validate(:banana)
    assert msg =~ "Invalid Sector"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Sector.valid_styles() == [
             :hidden,
             :fill,
             :stroke_width,
             :stroke_fill,
             :join,
             :miter_limit
           ]
  end

  # ============================================================================
  # compile

  test "compile works" do
    p = Sector.build(@data)
    assert Sector.compile(p, %{stroke_fill: :blue}) == [{:draw_sector, {100, 1.4, :stroke}}]
  end

  # ============================================================================
  # transform helpers

  test "default_pin returns the center of the arc" do
    assert Sector.default_pin(@data) == {0, 0}
  end

  # ============================================================================
  # point containment
  test "contains_point? works (clockwise)" do
    assert Sector.contains_point?(@data, {20, 32}) == true
    assert Sector.contains_point?(@data, {-20, 32}) == false
    assert Sector.contains_point?(@data, {30, 60}) == true
    assert Sector.contains_point?(@data, {130, 280}) == false
  end

  test "contains_point? works (counter-clockwise)" do
    data = {100, -1.4}
    assert Sector.contains_point?(data, {20, -32}) == true
    assert Sector.contains_point?(data, {-20, -32}) == false
    assert Sector.contains_point?(data, {30, -60}) == true
    assert Sector.contains_point?(data, {130, -280}) == false
  end

  test "contains_point? straight up and down" do
    # make it big enough to catch the straight down case
    data = {100, 2}
    # straight up or down is a degenerate case
    assert Sector.contains_point?(data, {0, -10}) == false
    assert Sector.contains_point?(data, {0, 10}) == true

    assert Sector.contains_point?(data, {0, -101}) == false
    assert Sector.contains_point?(data, {0, 101}) == false
  end

  test "contains_point? straight side to side" do
    # prob not denerate, but might as well check
    assert Sector.contains_point?(@data, {-10, 0}) == false
    assert Sector.contains_point?(@data, {10, 0}) == true

    assert Sector.contains_point?(@data, {-101, 0}) == false
    assert Sector.contains_point?(@data, {101, 0}) == false
  end
end
