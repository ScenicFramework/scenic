#
#  Created by Boyd Multerer on 5/8/17. Re-written on 11/01/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.RoundedRectangleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.RoundedRectangle


  @data     {{10,12}, 40, 80, 10}


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
    assert RoundedRectangle.verify( @data ) == true
  end

  test "verify fails invalid data" do
    assert RoundedRectangle.verify( {{10,11}, 40, 80, 666} )   == false
    assert RoundedRectangle.verify( {10, 40, 80} )             == false
    assert RoundedRectangle.verify( {{10,11,12}, 40, 80} )     == false
    assert RoundedRectangle.verify( {{10,11}, 40, :banana} )   == false
    assert RoundedRectangle.verify( {{10,:banana}, 40, 80} )   == false
    assert RoundedRectangle.verify( :banana )                  == false
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert RoundedRectangle.valid_styles() == [:hidden, :color, :border_color, :border_width]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the center of the rect" do
    assert RoundedRectangle.default_pin(@data) == {30, 52}
  end

  test "centroid returns the center of the rect" do
    assert RoundedRectangle.centroid(@data) == {30, 52}
  end

  test "expand expands the data" do
    assert RoundedRectangle.expand(@data, 10) == {{0,2}, 60, 100, 15}
  end

  #============================================================================
  # point containment
  test "contains_point? returns true if it contains the point" do
    assert RoundedRectangle.contains_point?(@data, {30, 52}) == true

    assert RoundedRectangle.contains_point?(@data, {30,12}) == true
    assert RoundedRectangle.contains_point?(@data, {30,92}) == true
    assert RoundedRectangle.contains_point?(@data, {10,52}) == true
    assert RoundedRectangle.contains_point?(@data, {50,52}) == true
  end

  test "contains_point? returns false if the point is outside the primary rectangle" do
    assert RoundedRectangle.contains_point?(@data, {9, 52}) == false
    assert RoundedRectangle.contains_point?(@data, {51, 52}) == false

    assert RoundedRectangle.contains_point?(@data, {30, 11}) == false
    assert RoundedRectangle.contains_point?(@data, {30, 93}) == false
  end

  test "contains_point? returns false if the point is outside the rounded corners but in the primary rect" do
    assert RoundedRectangle.contains_point?(@data, {11, 13}) == false
    assert RoundedRectangle.contains_point?(@data, {49, 13}) == false

    assert RoundedRectangle.contains_point?(@data, {49, 91}) == false
    assert RoundedRectangle.contains_point?(@data, {11, 91}) == false
  end

  #============================================================================
  # serialization

  test "serialize native works" do
    native = <<
      10  :: integer-size(16)-native,
      12  :: integer-size(16)-native,
      40  :: integer-size(16)-native,
      80  :: integer-size(16)-native,
      10  :: integer-size(16)-native,
    >>
    assert RoundedRectangle.serialize(@data)           == {:ok, native}
    assert RoundedRectangle.serialize(@data, :native)  == {:ok, native}
  end

  test "serialize big works" do
    assert RoundedRectangle.serialize(@data, :big) == {:ok, <<
      10  :: integer-size(16)-big,
      12  :: integer-size(16)-big,
      40  :: integer-size(16)-big,
      80  :: integer-size(16)-big,
      10  :: integer-size(16)-big,
    >>}
  end

  test "deserialize native works" do
    bin = <<
      10  :: integer-size(16)-native,
      12  :: integer-size(16)-native,
      40  :: integer-size(16)-native,
      80  :: integer-size(16)-native,
      10  :: integer-size(16)-native,
    >>
    assert assert RoundedRectangle.deserialize(bin)          == {:ok, @data, ""}
    assert assert RoundedRectangle.deserialize(bin, :native) == {:ok, @data, ""}
  end

  test "deserialize big works" do
    bin = <<
      10  :: integer-size(16)-big,
      12  :: integer-size(16)-big,
      40  :: integer-size(16)-big,
      80  :: integer-size(16)-big,
      10  :: integer-size(16)-big,
    >>
    assert assert RoundedRectangle.deserialize(bin, :big) == {:ok, @data, ""}
  end

end

