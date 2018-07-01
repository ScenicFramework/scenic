#
#  Created by Boyd Multerer on 5/8/17. Re-written on 11/01/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.RoundedRectangleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.RoundedRectangle

  @data           {40, 80, 10}
  @data_neg_w     {-40, 80, 10}
  @data_neg_h     {40, -80, 10}

  #============================================================================
  # build / add

  test "build works" do
    p = RoundedRectangle.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == RoundedRectangle
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert RoundedRectangle.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert RoundedRectangle.verify( {10, 40, :banana} ) == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert RoundedRectangle.valid_styles() == [:hidden, :fill, :stroke]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the center of the rect" do
    assert RoundedRectangle.default_pin(@data) == {20, 40}
  end

  test "centroid returns the center of the rect" do
    assert RoundedRectangle.centroid(@data) == {20, 40}
  end

  #============================================================================
  # point containment
  test "contains_point? returns true if it contains the point" do
    assert RoundedRectangle.contains_point?(@data, {20, 40}) == true

    assert RoundedRectangle.contains_point?(@data, {20,0}) == true
    assert RoundedRectangle.contains_point?(@data, {20,80}) == true
    assert RoundedRectangle.contains_point?(@data, {0,40}) == true
    assert RoundedRectangle.contains_point?(@data, {40,40}) == true
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

  #------------------------
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

  #------------------------
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

