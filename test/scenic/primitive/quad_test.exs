#
#  Created by Boyd Multerer on 5/8/17. Re-written on 11/01/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.QuadTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Quad


  @data     {{100,300},{300,180},{400,310},{300,520}}


  #============================================================================
  # build / add

  test "build works" do
    p = Quad.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Quad
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Quad.verify( @data ) == true
  end

  test "verify fails invalid data" do
    assert Quad.verify( {{10,11}, 40, 80, 666} )   == false
    assert Quad.verify( {10, 40, 80} )             == false
    assert Quad.verify( {{10,11,12}, 40, 80} )     == false
    assert Quad.verify( {{10,11}, 40, :banana} )   == false
    assert Quad.verify( {{10,:banana}, 40, 80} )   == false
    assert Quad.verify( :banana )                  == false
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Quad.valid_styles() == [:hidden, :color, :border_color, :border_width]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the averaged center of the rect" do
    assert Quad.default_pin(@data) == {275, 328}
  end

#  test "centroid returns the center of the rect" do
#    assert Quad.centroid(@data) == {30, 52}
#  end

  test "expand expands the data" do
    {{x0,y0},{x1,y1},{x2,y2},{x3,y3}} = Quad.expand(@data, 10)
    # rounding to avoid floating-point errors from messing up the tests
    assert {
      {round(x0), round(y0)},
      {round(x1), round(y1)},
      {round(x2), round(y2)},
      {round(x3), round(y3)}
    } ==   {{84, 298}, {302, 167}, {412, 309}, {303, 538}}
  end

  #============================================================================
  # point containment
  test "contains_point? returns true if it contains the point" do
    assert Quad.contains_point?(@data, {101, 300})  == true
    assert Quad.contains_point?(@data, {300,181})   == true
    assert Quad.contains_point?(@data, {399,310})   == true
    assert Quad.contains_point?(@data, {300,519})   == true
  end

  test "contains_point? returns false if the point is outside" do
    assert Quad.contains_point?(@data, {100, 180}) == false
    assert Quad.contains_point?(@data, {400, 180}) == false
    assert Quad.contains_point?(@data, {400, 520}) == false
    assert Quad.contains_point?(@data, {100, 520}) == false
  end

  #============================================================================
  # serialization

  test "serialize native works" do
    native = <<
      100  :: integer-size(16)-native,
      300  :: integer-size(16)-native,
      300  :: integer-size(16)-native,
      180  :: integer-size(16)-native,
      400  :: integer-size(16)-native,
      310  :: integer-size(16)-native,
      300  :: integer-size(16)-native,
      520  :: integer-size(16)-native,
    >>
    assert Quad.serialize(@data)           == {:ok, native}
    assert Quad.serialize(@data, :native)  == {:ok, native}
  end

  test "serialize big works" do
    assert Quad.serialize(@data, :big) == {:ok, <<
      100  :: integer-size(16)-big,
      300  :: integer-size(16)-big,
      300  :: integer-size(16)-big,
      180  :: integer-size(16)-big,
      400  :: integer-size(16)-big,
      310  :: integer-size(16)-big,
      300  :: integer-size(16)-big,
      520  :: integer-size(16)-big,
    >>}
  end

  test "deserialize native works" do
    bin = <<
      100  :: integer-size(16)-native,
      300  :: integer-size(16)-native,
      300  :: integer-size(16)-native,
      180  :: integer-size(16)-native,
      400  :: integer-size(16)-native,
      310  :: integer-size(16)-native,
      300  :: integer-size(16)-native,
      520  :: integer-size(16)-native,
    >>
    assert assert Quad.deserialize(bin)          == {:ok, @data, ""}
    assert assert Quad.deserialize(bin, :native) == {:ok, @data, ""}
  end

  test "deserialize big works" do
    bin = <<
      100  :: integer-size(16)-big,
      300  :: integer-size(16)-big,
      300  :: integer-size(16)-big,
      180  :: integer-size(16)-big,
      400  :: integer-size(16)-big,
      310  :: integer-size(16)-big,
      300  :: integer-size(16)-big,
      520  :: integer-size(16)-big,
    >>
    assert assert Quad.deserialize(bin, :big) == {:ok, @data, ""}
  end

end

