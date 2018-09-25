#
#  Created by Boyd Multerer on 5/8/17. Re-written on 11/01/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.RectangleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Rectangle

  @data {40, 80}
  @data_neg_w {-40, 80}
  @data_neg_h {40, -80}

  # ============================================================================
  # build / add

  test "build works" do
    p = Rectangle.build(@data)
    assert p.module == Rectangle
    assert Primitive.get(p) == @data
  end

  # ============================================================================
  # verify
  
  test "info works" do
    assert Rectangle.info(:test_data) =~ ":test_data"
  end

  test "verify passes valid data" do
    assert Rectangle.verify(@data) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Rectangle.verify({10, 40, 80}) == :invalid_data
    assert Rectangle.verify({40, :banana}) == :invalid_data
    assert Rectangle.verify(:banana) == :invalid_data
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Rectangle.valid_styles() == [:hidden, :fill, :stroke]
  end

  # ============================================================================
  # transform helpers

  test "default_pin returns the center of the rect" do
    assert Rectangle.default_pin(@data) == {20, 40}
  end

  test "centroid returns the center of the rect" do
    assert Rectangle.centroid(@data) == {20, 40}
  end

  # ============================================================================
  # point containment
  test "contains_point? returns true if it contains the point" do
    assert Rectangle.contains_point?(@data, {20, 30}) == true
    assert Rectangle.contains_point?(@data, {0, 0}) == true
    assert Rectangle.contains_point?(@data, {30, 80}) == true
  end

  test "contains_point? returns false if the point is outside" do
    assert Rectangle.contains_point?(@data, {-1, -1}) == false
    assert Rectangle.contains_point?(@data, {41, 81}) == false
  end

  # ------------------------
  # negative width
  test "contains_point? returns true if it contains the point - negative width" do
    assert Rectangle.contains_point?(@data_neg_w, {-10, 10}) == true
  end

  test "contains_point? returns false if the point is outside - negative width" do
    assert Rectangle.contains_point?(@data_neg_w, {1, 10}) == false
    assert Rectangle.contains_point?(@data_neg_w, {-41, 10}) == false
  end

  # ------------------------
  # negative height
  test "contains_point? returns true if it contains the point - negative height" do
    assert Rectangle.contains_point?(@data_neg_h, {10, -10}) == true
  end

  test "contains_point? returns false if the point is outside - negative height" do
    assert Rectangle.contains_point?(@data_neg_h, {10, 1}) == false
    assert Rectangle.contains_point?(@data_neg_h, {10, -81}) == false
  end
end
