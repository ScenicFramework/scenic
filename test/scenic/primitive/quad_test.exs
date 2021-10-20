#
#  Created by Boyd Multerer on 2017-05-17.
#  Re-written on 11/01/17
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.QuadTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Quad

  alias Scenic.Primitive
  alias Scenic.Primitive.Quad

  @convex {{100, 300}, {300, 180}, {400, 310}, {300, 520}}

  # @concave      {{100,300},{300,180},{400,310},{300,200}}
  # @complex      {{100,300},{400,100},{400,300},{100,100}}

  @reverse {{300, 520}, {400, 310}, {300, 180}, {100, 300}}

  # ============================================================================
  # build / add

  test "build works" do
    p = Quad.build(@convex)
    assert p.module == Quad
    assert Primitive.get(p) == @convex
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert Quad.validate(@convex) == {:ok, @convex}
    assert Quad.validate(@reverse) == {:ok, @reverse}
  end

  test "validate rejects bad data" do
    {:error, msg} = Quad.validate({{100, 300}, {300, 180}, {"400", 310}, {300, 520}})
    assert msg =~ "Invalid Quad"

    {:error, msg} = Quad.validate(:banana)
    assert msg =~ "Invalid Quad"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Quad.valid_styles() == [
             :hidden,
             :scissor,
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
    p = Quad.build(@convex)

    assert Quad.compile(p, %{stroke_fill: :blue}) ==
             [{:draw_quad, {100, 300, 300, 180, 400, 310, 300, 520, :stroke}}]
  end

  # ============================================================================
  # transform helpers

  test "default_pin returns the averaged center of the rect" do
    assert Quad.default_pin(@convex) == {275.0, 327.5}
  end

  # ============================================================================
  # point containment
  test "contains_point? returns true if it contains the point" do
    assert Quad.contains_point?(@convex, {101, 300}) == true
    assert Quad.contains_point?(@convex, {300, 181}) == true
    assert Quad.contains_point?(@convex, {399, 310}) == true
    assert Quad.contains_point?(@convex, {300, 519}) == true
  end

  test "contains_point? returns true if it contains the point when counter wound" do
    assert Quad.contains_point?(@reverse, {101, 300}) == true
    assert Quad.contains_point?(@reverse, {300, 181}) == true
    assert Quad.contains_point?(@reverse, {399, 310}) == true
    assert Quad.contains_point?(@reverse, {300, 519}) == true
  end

  test "contains_point? returns false if the point is outside" do
    assert Quad.contains_point?(@convex, {100, 180}) == false
    assert Quad.contains_point?(@convex, {400, 180}) == false
    assert Quad.contains_point?(@convex, {400, 520}) == false
    assert Quad.contains_point?(@convex, {100, 520}) == false
  end
end
