#
#  Created by Boyd Multerer on 2018-06-29.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.PathTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Path

  @data [
    :begin,
    {:move_to, 10, 20},
    {:line_to, 30, 40},
    {:bezier_to, 10, 11, 20, 21, 30, 40},
    {:quadratic_to, 10, 11, 50, 60},
    {:arc_to, 70, 80, 90, 100, 20},
    :close_path,
    :solid,
    :hole
  ]

  # ============================================================================
  # build / add

  test "build works" do
    p = Path.build(@data)
    assert p.module == Path
    assert Primitive.get(p) == @data
  end

  # ============================================================================
  # verify

  test "info works" do
    assert Path.info(:test_data) =~ ":test_data"
  end

  test "verify passes valid data" do
    assert Path.verify(@data) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Path.verify(:banana) == :invalid_data
  end

  test "verify fails unknown action" do
    assert Path.verify([:banana]) == :invalid_data
  end

  test "verify fails invalid move_to" do
    assert Path.verify([{:move_to, 10}]) == :invalid_data
    assert Path.verify([{:move_to, 10, 20, 30}]) == :invalid_data
  end

  test "verify fails invalid line_to" do
    assert Path.verify([{:line_to, 10}]) == :invalid_data
    assert Path.verify([{:line_to, 10, 20, 30}]) == :invalid_data
  end

  test "verify fails invalid bezier_to" do
    assert Path.verify([{:bezier_to, 10, 20, 30}]) == :invalid_data
  end

  test "verify fails invalid quadratic_to" do
    assert Path.verify([{:quadratic_to, 10, 20, 30}]) == :invalid_data
  end

  test "verify fails invalid arc_to" do
    assert Path.verify([{:arc_to, 10, 20, 30}]) == :invalid_data
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Path.valid_styles() == [:hidden, :fill, :stroke]
  end

  # ============================================================================
  # transform helpers

  test "default_pin returns {0,0}" do
    assert Path.default_pin(@data) == {0, 0}
  end

  # ============================================================================
  # point containment
  test "contains_point? always returns false" do
    assert Path.contains_point?(@data, {56, 65}) == false
    assert Path.contains_point?(@data, {75, 81}) == false
    assert Path.contains_point?(@data, {99, 90}) == false
  end
end
