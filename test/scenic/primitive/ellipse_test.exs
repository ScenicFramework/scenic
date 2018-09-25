#
#  Created by Boyd Multerer on June 29, 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.EllipseTest do
  use ExUnit.Case, async: true
  doctest Scenic

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
  # verify

  test "info works" do
    assert Ellipse.info(:test_data) =~ ":test_data"
  end

  test "verify passes valid data" do
    assert Ellipse.verify(@data) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Ellipse.verify({:atom, 0.0, 1.4}) == :invalid_data
    assert Ellipse.verify(:banana) == :invalid_data
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Ellipse.valid_styles() == [:hidden, :fill, :stroke]
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
