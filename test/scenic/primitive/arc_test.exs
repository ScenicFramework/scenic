#
#  Created by Boyd Multerer on 2018-06-29.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.ArcTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Arc

  @data {100, 0.0, 1.4}

  # ============================================================================
  # build / add

  test "build works" do
    p = Arc.build(@data)
    assert p.module == Arc
    assert Primitive.get(p) == @data
  end

  # ============================================================================
  # verify

  test "info works" do
    assert Arc.info(:test_data) =~ ":test_data"
  end

  test "verify passes valid data" do
    assert Arc.verify(@data) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Arc.verify({:atom, 0.0, 1.4}) == :invalid_data
    assert Arc.verify(:banana) == :invalid_data
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Arc.valid_styles() == [:hidden, :fill, :stroke]
  end

  # ============================================================================
  # transform helpers

  test "default_pin returns the center of the arc" do
    assert Arc.default_pin(@data) == {0, 0}
  end

  # ============================================================================
  # point containment
  test "contains_point? works" do
    # in the sector, but not the arc
    assert Arc.contains_point?(@data, {46, 45}) == false
    # in the arc
    assert Arc.contains_point?(@data, {65, 61}) == true
    # beyond the sector and the arc
    assert Arc.contains_point?(@data, {89, 90}) == false
  end
end
