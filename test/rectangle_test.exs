#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.RectangleTest do
  use ExUnit.Case
  doctest Scenic.Math

  @xy {10, 20}
  @rect {10, 20, 100, 200}
  @rect_empty {0, 0, 0, 0}
  @rect_contained {20, 30, 40, 40}
  @rect_overlapped {20, 30, 100, 200}
  @rect_no_overlap {400, 410, 100, 200}

  @rect_flipped {100, 200, -40, -50}
  @rect_normalized {60, 150, 40, 50}

  # ----------------------------------------------------------------------------
  # build a new rectangle
  test "build with width and height" do
    assert Scenic.Math.Rectangle.build(
             x: 10,
             width: 100,
             y: 20,
             height: 200
           ) == {10, 20, 100, 200}
  end

  test "build with left top right bottom" do
    assert Scenic.Math.Rectangle.build(
             left: 10,
             top: 20,
             right: 100,
             bottom: 200
           ) == {10, 20, 90, 180}
  end

  # ----------------------------------------------------------------------------
  test "location returns and {x,y} vector" do
    assert Scenic.Math.Rectangle.location(@rect) == @xy
  end

  # ----------------------------------------------------------------------------
  test "center returns an {x,y} vector at the center of the rect" do
    assert Scenic.Math.Rectangle.center(@rect) == {60.0, 120.0}
  end

  # ----------------------------------------------------------------------------
  test "is_empty? returns false if the rect has size" do
    assert Scenic.Math.Rectangle.is_empty?(@rect) == false
    assert Scenic.Math.Rectangle.is_empty?({0, 0, 10, 20}) == false
  end

  test "is_empty? returns true if the rect is zeroed out" do
    assert Scenic.Math.Rectangle.is_empty?({0, 0, 0, 0}) == true
    assert Scenic.Math.Rectangle.is_empty?({0.0, 0.0, 0.0, 0.0}) == true
  end

  test "is_empty? returns true if the rect is zero width and height, but has x and y" do
    assert Scenic.Math.Rectangle.is_empty?({10, 20, 0, 0}) == true
    assert Scenic.Math.Rectangle.is_empty?({10, 20, 0.0, 0.0}) == true
  end

  # ----------------------------------------------------------------------------
  test "contains? is true if it contains a vector 2" do
    assert Scenic.Math.Rectangle.contains?(@rect, {{15, 25}, {5, 10}}) == true
  end

  test "contains? is false if it doesn't conatain a vector" do
    assert Scenic.Math.Rectangle.contains?(@rect, {{15, 25}, {500, 10}}) == false
    assert Scenic.Math.Rectangle.contains?(@rect, {{5, 25}, {20, 10}}) == false
  end

  # ----------------------------------------------------------------------------
  test "contains? is true if it contains a rect" do
    assert Scenic.Math.Rectangle.contains?(@rect, @rect_contained) == true
    assert Scenic.Math.Rectangle.contains?(@rect, {15, 25, 10, 10}) == true
  end

  test "contains? is false if it doesn't conatain a rect" do
    assert Scenic.Math.Rectangle.contains?(@rect, {15, 25, 50, 500}) == false
    assert Scenic.Math.Rectangle.contains?(@rect, {5, 25, 20, 20}) == false
  end

  # ----------------------------------------------------------------------------
  test "intersects? is true if it intersects a vector" do
    assert Scenic.Math.Rectangle.intersects?(@rect, {{15, 25}, {500, 10}}) == true
    assert Scenic.Math.Rectangle.intersects?(@rect, {{5, 25}, {20, 10}}) == true
  end

  test "intersects? is true if it contains a vector 2" do
    assert Scenic.Math.Rectangle.intersects?(@rect, {{15, 25}, {5, 10}}) == true
  end

  test "intersects? is false if it doesn't intersect a vector" do
    assert Scenic.Math.Rectangle.intersects?(@rect, {{1, 1}, {500, 2}}) == false
  end

  # ----------------------------------------------------------------------------
  test "intersects? is true if it intersects a rect" do
    assert Scenic.Math.Rectangle.intersects?(@rect, @rect_overlapped) == true
    assert Scenic.Math.Rectangle.intersects?(@rect, {15, 25, 50, 500}) == true
    assert Scenic.Math.Rectangle.intersects?(@rect, {5, 25, 20, 20}) == true
  end

  test "intersects? is true if it contains a rect" do
    assert Scenic.Math.Rectangle.intersects?(@rect, {15, 25, 10, 10}) == true
  end

  test "intersects? is false if it doesn't intersect a rect" do
    assert Scenic.Math.Rectangle.intersects?(@rect, @rect_no_overlap) == false
    assert Scenic.Math.Rectangle.intersects?(@rect, {1, 1, 500, 2}) == false
  end

  # ----------------------------------------------------------------------------
  test "normalize does nothing to an already normal rectangle" do
    assert Scenic.Math.Rectangle.normalize(@rect) == @rect
    assert Scenic.Math.Rectangle.normalize(@rect_normalized) == @rect_normalized
  end

  test "normalize flips coordates of a backwards rectangle" do
    assert Scenic.Math.Rectangle.normalize(@rect_flipped) == @rect_normalized
  end

  # ----------------------------------------------------------------------------
  test "inflate makes a rect bigger" do
    assert Scenic.Math.Rectangle.inflate(@rect, 5, 6) == {5, 14, 105, 206}
  end

  test "inflate makes a rect smaller too" do
    assert Scenic.Math.Rectangle.inflate(@rect, -5, -6) == {15, 26, 95, 194}
  end

  # ----------------------------------------------------------------------------
  test "offset translates a rect, but doesn't change it's size" do
    assert Scenic.Math.Rectangle.offset(@rect, 5, 6) == {15, 26, 100, 200}
    assert Scenic.Math.Rectangle.offset(@rect, -5, -6) == {5, 14, 100, 200}
  end

  # ----------------------------------------------------------------------------
  test "intersect finds the insection between two overlapping rects" do
    assert Scenic.Math.Rectangle.intersect(@rect, @rect_overlapped) == {20, 30, 90, 190}
    assert Scenic.Math.Rectangle.intersect(@rect_overlapped, @rect) == {20, 30, 90, 190}
  end

  test "intersect finds the smaller of two concentric rects" do
    assert Scenic.Math.Rectangle.intersect(@rect, @rect_contained) == @rect_contained
    assert Scenic.Math.Rectangle.intersect(@rect_contained, @rect) == @rect_contained
  end

  test "intersect returns empty if no intersection" do
    assert Scenic.Math.Rectangle.intersect(@rect, @rect_no_overlap) == @rect_empty
    assert Scenic.Math.Rectangle.intersect(@rect_no_overlap, @rect) == @rect_empty
  end

  # ----------------------------------------------------------------------------
  test "union finds the union of two overlapping rects" do
    assert Scenic.Math.Rectangle.union(@rect, @rect_overlapped) == {10, 20, 110, 210}
    assert Scenic.Math.Rectangle.union(@rect_overlapped, @rect) == {10, 20, 110, 210}
  end

  test "union finds the larger of two concentric rects" do
    assert Scenic.Math.Rectangle.union(@rect, @rect_contained) == @rect
    assert Scenic.Math.Rectangle.union(@rect_contained, @rect) == @rect
  end

  test "union returns the bounding frame of two non-overlapping rects" do
    assert Scenic.Math.Rectangle.union(@rect, @rect_no_overlap) == {10, 20, 490, 590}
    assert Scenic.Math.Rectangle.union(@rect_no_overlap, @rect) == {10, 20, 490, 590}
  end

  # ============================================================================
  # helper functions
  test "to_ltrb works" do
    assert Scenic.Math.Rectangle.to_ltrb(@rect) == {10, 20, 110, 220}
  end

  test "from_ltrb works" do
    assert Scenic.Math.Rectangle.from_ltrb({10, 20, 110, 220}) == @rect
  end
end
