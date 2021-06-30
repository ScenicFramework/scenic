#
#  Created by Boyd Multerer on 2018-06-29.
#  Copyright © 2018 - 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.ArcTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Arc

  alias Scenic.Primitive
  alias Scenic.Primitive.Arc

  @data {100, 1.4}

  # ============================================================================
  # build / add

  test "build works" do
    p = Arc.build(@data)
    assert p.module == Arc
    assert Primitive.get(p) == @data
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert Arc.validate({100, 1.4}) == {:ok, {100, 1.4}}
  end

  test "validate rejects the old format - with help" do
    {:error, msg} = Arc.validate({100, 1.4, 6})
    assert msg =~ "Arc has changed"
  end

  test "validate rejects bad data" do
    {:error, msg} = Arc.validate({100, "1.4"})
    assert msg =~ "Invalid Arc"

    {:error, msg} = Arc.validate(:banana)
    assert msg =~ "Invalid Arc"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Arc.valid_styles() == [:hidden, :fill, :stroke_width, :stroke_fill, :cap]
  end

  # ============================================================================
  # compile

  test "compile works" do
    p = Arc.build(@data)
    assert Arc.compile(p, %{stroke_fill: :blue}) == [{:draw_arc, {100, 1.4, :stroke}}]
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
