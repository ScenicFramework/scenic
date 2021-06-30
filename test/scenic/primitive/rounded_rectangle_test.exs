#
#  Created by Boyd Multerer on 2017-05-08.
#  Re-written on 11/01/17
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.RoundedRectangleTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.RoundedRectangle

  alias Scenic.Primitive
  alias Scenic.Primitive.RoundedRectangle

  @data {40, 80, 10}
  @data_neg_w {-40, 80, 10}
  @data_neg_h {40, -80, 10}

  # ============================================================================
  # build / add

  test "build works" do
    p = RoundedRectangle.build(@data)
    assert p.module == RoundedRectangle
    assert Primitive.get(p) == @data
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert RoundedRectangle.validate(@data) == {:ok, @data}
    assert RoundedRectangle.validate(@data_neg_w) == {:ok, @data_neg_w}
    assert RoundedRectangle.validate(@data_neg_h) == {:ok, @data_neg_h}
  end

  test "validate rejects bad data" do
    {:error, msg} = RoundedRectangle.validate({40, "80"})
    assert msg =~ "Invalid Rounded Rectangle"

    {:error, msg} = RoundedRectangle.validate( :banana )
    assert msg =~ "Invalid Rounded Rectangle"
  end



  # ============================================================================
  # styles

  test "valid_styles works" do
    assert RoundedRectangle.valid_styles() == [:hidden, :fill, :stroke_width, :stroke_fill]
  end

  # ============================================================================
  # compile

  test "compile works" do
    p = RoundedRectangle.build(@data )
    assert RoundedRectangle.compile(p, %{stroke_fill: :blue}) ==
      [{:draw_rrect, {40, 80, 10, :stroke}}]
  end



  # ============================================================================
  # transform helpers

  test "default_pin returns the center of the rect" do
    assert RoundedRectangle.default_pin(@data) == {20, 40}
  end

  test "centroid returns the center of the rect" do
    assert RoundedRectangle.centroid(@data) == {20, 40}
  end

  # ============================================================================
  # point containment
  test "contains_point? returns true if it contains the point" do
    # center
    assert RoundedRectangle.contains_point?(@data, {20, 40}) == true

    # center bottom
    assert RoundedRectangle.contains_point?(@data, {20, 0}) == true
    # center top
    assert RoundedRectangle.contains_point?(@data, {20, 80}) == true
    # center left
    assert RoundedRectangle.contains_point?(@data, {0, 40}) == true
    # center right
    assert RoundedRectangle.contains_point?(@data, {40, 40}) == true
  end

  test "contains_point? returns false if the point is outside the primary rectangle" do
    assert RoundedRectangle.contains_point?(@data, {-1, 40}) == false
    assert RoundedRectangle.contains_point?(@data, {41, 40}) == false

    assert RoundedRectangle.contains_point?(@data, {20, -1}) == false
    assert RoundedRectangle.contains_point?(@data, {20, 81}) == false
  end

  test "contains_point? returns false if the point is outside the rounded corners but in the primary rect" do
    assert RoundedRectangle.contains_point?(@data, {1, 1}) == false
    assert RoundedRectangle.contains_point?(@data, {39, 1}) == false

    assert RoundedRectangle.contains_point?(@data, {39, 79}) == false
    assert RoundedRectangle.contains_point?(@data, {1, 79}) == false
  end

  # ------------------------
  # negative width

  test "contains_point? returns true if it contains the point - negative width" do
    assert RoundedRectangle.contains_point?(@data_neg_w, {-20, 40}) == true
  end

  test "contains_point? returns false if the point is outside the primary rectangle - negative width" do
    assert RoundedRectangle.contains_point?(@data_neg_w, {1, 40}) == false
    assert RoundedRectangle.contains_point?(@data_neg_w, {-41, 40}) == false
  end

  test "contains_point? returns false if the point is outside the rounded corners but in the primary rect - negative width" do
    assert RoundedRectangle.contains_point?(@data_neg_w, {-1, 1}) == false
    assert RoundedRectangle.contains_point?(@data_neg_w, {-39, 1}) == false

    assert RoundedRectangle.contains_point?(@data_neg_w, {-39, 79}) == false
    assert RoundedRectangle.contains_point?(@data_neg_w, {-1, 79}) == false
  end

  # ------------------------
  # negative height

  test "contains_point? returns true if it contains the point - negative height" do
    assert RoundedRectangle.contains_point?(@data_neg_h, {20, -40}) == true
  end

  test "contains_point? returns false if the point is outside the primary rectangle - negative height" do
    assert RoundedRectangle.contains_point?(@data_neg_h, {20, 1}) == false
    assert RoundedRectangle.contains_point?(@data_neg_h, {20, -81}) == false
  end

  test "contains_point? returns false if the point is outside the rounded corners but in the primary rect - negative height" do
    assert RoundedRectangle.contains_point?(@data_neg_h, {1, -1}) == false
    assert RoundedRectangle.contains_point?(@data_neg_h, {39, -1}) == false

    assert RoundedRectangle.contains_point?(@data_neg_h, {39, -79}) == false
    assert RoundedRectangle.contains_point?(@data_neg_h, {1, -79}) == false
  end
end
