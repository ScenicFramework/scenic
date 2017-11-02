#
#  Created by Boyd Multerer on 5/8/17. Re-written on 11/01/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.QuadTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Quad


  @convex       {{100,300},{300,180},{400,310},{300,520}}
  @concave      {{100,300},{300,180},{400,310},{300,200}}
  @degenerate   {{100,300},{400,100},{400,300},{100,100}}


  #============================================================================
  # build / add

  test "build works" do
    p = Quad.build( @convex )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Quad
    assert Primitive.get(p) == @convex
  end


  #============================================================================
  # verify

  test "verify passes valid convex" do
    assert Quad.verify( @convex )     == true
    assert Quad.verify( @concave )    == true
    assert Quad.verify( @degenerate ) == true
  end

  test "verify fails invalid convex" do
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
    assert Quad.default_pin(@convex) == {275, 328}
  end

#  test "centroid returns the center of the rect" do
#    assert Quad.centroid(@convex) == {30, 52}
#  end

  test "expand expands the convex" do
    {{x0,y0},{x1,y1},{x2,y2},{x3,y3}} = Quad.expand(@convex, 10)
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
    assert Quad.contains_point?(@convex, {101, 300})  == true
    assert Quad.contains_point?(@convex, {300,181})   == true
    assert Quad.contains_point?(@convex, {399,310})   == true
    assert Quad.contains_point?(@convex, {300,519})   == true
  end

  test "contains_point? returns false if the point is outside" do
    assert Quad.contains_point?(@convex, {100, 180}) == false
    assert Quad.contains_point?(@convex, {400, 180}) == false
    assert Quad.contains_point?(@convex, {400, 520}) == false
    assert Quad.contains_point?(@convex, {100, 520}) == false
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
    assert Quad.serialize(@convex)           == {:ok, native}
    assert Quad.serialize(@convex, :native)  == {:ok, native}
  end

  test "serialize big works" do
    assert Quad.serialize(@convex, :big) == {:ok, <<
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
    assert assert Quad.deserialize(bin)          == {:ok, @convex, ""}
    assert assert Quad.deserialize(bin, :native) == {:ok, @convex, ""}
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
    assert assert Quad.deserialize(bin, :big) == {:ok, @convex, ""}
  end

end

