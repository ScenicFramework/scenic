#
#  Created by Boyd Multerer on 2018-06-29.
#  Copyright © 2018 - 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.EllipseTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Ellipse

  alias Scenic.Primitive
  alias Scenic.Primitive.Ellipse

  @data {100, 200}

  # ============================================================================
  # build / add

  test "build works" do
    p = Ellipse.build(@data)
    assert p.module == Ellipse
    assert Primitive.get(p) == @data
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert Ellipse.validate({100, 200}) == {:ok, {100, 200}}
    assert Ellipse.validate({100.5, 200}) == {:ok, {100.5, 200}}
  end

  test "validate rejects bad data" do
    {:error, msg} = Ellipse.validate({100, "1.4"})
    assert msg =~ "Invalid Ellipse"

    {:error, msg} = Ellipse.validate(:banana)
    assert msg =~ "Invalid Ellipse"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Ellipse.valid_styles() == [:hidden, :scissor, :fill, :stroke_width, :stroke_fill]
  end

  # ============================================================================
  # compile

  test "compile works" do
    p = Ellipse.build(@data)
    assert Ellipse.compile(p, %{stroke_fill: :blue}) == [{:draw_ellipse, {100, 200, :stroke}}]
  end

  # ============================================================================
  # transform helpers

  test "default_pin returns the center of the arc" do
    assert Ellipse.default_pin(@data) == {0, 0}
  end

  # ============================================================================
  # point containment
  test "contains_point? works" do
    assert Ellipse.contains_point?(@data, {10, 32}) == true
    assert Ellipse.contains_point?(@data, {99, 0}) == true
    assert Ellipse.contains_point?(@data, {100, 0}) == true
    assert Ellipse.contains_point?(@data, {101, 0}) == false
    assert Ellipse.contains_point?(@data, {0, 199}) == true
    assert Ellipse.contains_point?(@data, {0, 200}) == true
    assert Ellipse.contains_point?(@data, {0, 201}) == false
  end
end
