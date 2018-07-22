#
#  Created by Boyd Multerer on 5/8/17. Re-written on 11/02/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.TriangleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Triangle 


  @data     {{20, 300}, {400, 300}, {400, 0}}


  #============================================================================
  # build / add

  test "build works" do
    p = Triangle.build( @data )
    assert p.module == Triangle
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Triangle.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Triangle.verify( {{20, 300}, {400, 300}, 400, 0} )         == :invalid_data
    assert Triangle.verify( {{20, 300}, {400, 300}, {400, :banana}} ) == :invalid_data
    assert Triangle.verify( :banana )                                 == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Triangle.valid_styles() == [:hidden, :fill, :stroke]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the center of the rect" do
    {px,py} = Triangle.default_pin(@data)
    assert {round(px),round(py)} == {273, 200}
  end

  test "centroid returns the centroid of the rect" do
    {px,py} = Triangle.centroid(@data)
    assert {round(px),round(py)} == {273, 200}
  end

  #============================================================================
  # point containment
  test "contains_point? returns true if it contains the point" do
    assert Triangle.contains_point?(@data, {273, 200})  == true
    assert Triangle.contains_point?(@data, {30, 299})   == true
    assert Triangle.contains_point?(@data, {399, 299})  == true
    assert Triangle.contains_point?(@data, {399, 10})   == true
  end

  test "contains_point? returns false if the point is outside" do
    # first, outside the triangle, but inside the bounding rect
    assert Triangle.contains_point?(@data, {30, 100})   == false
    # clearly outside
    assert Triangle.contains_point?(@data, {19, 200})   == false
    assert Triangle.contains_point?(@data, {401, 200})  == false
    assert Triangle.contains_point?(@data, {273, -1})   == false
    assert Triangle.contains_point?(@data, {273, 301})  == false
  end


  test "contains_point? can handle degenerate triangles - is really a line" do
    assert Triangle.contains_point?(
      {{0,0}, {10,0}, {-10,0}},
      {30, 100}
    ) == false
  end


end

