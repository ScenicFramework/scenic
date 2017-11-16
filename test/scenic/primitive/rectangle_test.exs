#
#  Created by Boyd Multerer on 5/8/17. Re-written on 11/01/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.RectangleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Rectangle


  @data     {{10,12}, 40, 80}


  #============================================================================
  # build / add

  test "build works" do
    p = Rectangle.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Rectangle
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Rectangle.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Rectangle.verify( {{10,11}, 40, 80, 666} )   == :invalid_data
    assert Rectangle.verify( {10, 40, 80} )             == :invalid_data
    assert Rectangle.verify( {{10,11,12}, 40, 80} )     == :invalid_data
    assert Rectangle.verify( {{10,11}, 40, :banana} )   == :invalid_data
    assert Rectangle.verify( {{10,:banana}, 40, 80} )   == :invalid_data
    assert Rectangle.verify( :banana )                  == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Rectangle.valid_styles() == [:hidden, :color, :border_color, :border_width]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the center of the rect" do
    assert Rectangle.default_pin(@data) == {30, 52}
  end

  test "centroid returns the center of the rect" do
    assert Rectangle.centroid(@data) == {30, 52}
  end

  test "expand expands the data" do
    assert Rectangle.expand(@data, 10) == {{0,2}, 60, 100}
  end

  #============================================================================
  # point containment
  test "contains_point? returns true if it contains the point" do
    assert Rectangle.contains_point?(@data, {30, 52}) == true
    assert Rectangle.contains_point?(@data, {10,12}) == true
    assert Rectangle.contains_point?(@data, {50,92}) == true
  end

  test "contains_point? returns false if the point is outside" do
    assert Rectangle.contains_point?(@data, {9, 52}) == false
    assert Rectangle.contains_point?(@data, {51, 52}) == false

    assert Rectangle.contains_point?(@data, {30, 11}) == false
    assert Rectangle.contains_point?(@data, {30, 93}) == false
  end

  #============================================================================
  # serialization

  test "serialize native works" do
    native = <<
      10  :: integer-size(16)-native,
      12  :: integer-size(16)-native,
      40  :: integer-size(16)-native,
      80  :: integer-size(16)-native,
    >>
    assert Rectangle.serialize(@data)           == {:ok, native}
    assert Rectangle.serialize(@data, :native)  == {:ok, native}
  end

  test "serialize big works" do
    assert Rectangle.serialize(@data, :big) == {:ok, <<
      10  :: integer-size(16)-big,
      12  :: integer-size(16)-big,
      40  :: integer-size(16)-big,
      80  :: integer-size(16)-big,
    >>}
  end

  test "deserialize native works" do
    bin = <<
      10  :: integer-size(16)-native,
      12  :: integer-size(16)-native,
      40  :: integer-size(16)-native,
      80  :: integer-size(16)-native,
    >>
    assert assert Rectangle.deserialize(bin)          == {:ok, @data, ""}
    assert assert Rectangle.deserialize(bin, :native) == {:ok, @data, ""}
  end

  test "deserialize big works" do
    bin = <<
      10  :: integer-size(16)-big,
      12  :: integer-size(16)-big,
      40  :: integer-size(16)-big,
      80  :: integer-size(16)-big,
    >>
    assert assert Rectangle.deserialize(bin, :big) == {:ok, @data, ""}
  end

end

