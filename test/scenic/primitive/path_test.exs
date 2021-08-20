#
#  Created by Boyd Multerer on 2018-06-29.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.PathTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Path

  alias Scenic.Primitive
  alias Scenic.Primitive.Path

  @data [
    {:move_to, 10, 20},
    {:line_to, 30, 40},
    {:bezier_to, 10, 11, 20, 21, 30, 40},
    {:quadratic_to, 10, 11, 50, 60},
    {:arc_to, 70, 80, 90, 100, 20},
    :close_path
  ]

  # ============================================================================
  # build / add

  test "build works - inserts a :begin at the start" do
    cmds = [{:move_to, 10, 20}]
    expected = [:begin, {:move_to, 10, 20}]

    p = Path.build(cmds)
    assert p.module == Path
    assert Primitive.get(p) == expected
  end

  test "build works - doesn't add :begin if it already starts with one" do
    cmds = [
      :begin,
      {:move_to, 10, 20}
    ]

    p = Path.build(cmds)
    assert p.module == Path
    assert Primitive.get(p) == cmds
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert Path.validate(@data) == {:ok, [:begin | @data]}
  end

  test "rejects :solid as deprecated" do
    {:error, msg} = Path.validate([:solid])
    assert msg =~ ":solid command is deprecated"
  end

  test "rejects :hole as deprecated" do
    {:error, msg} = Path.validate([:hole])
    assert msg =~ ":hole command is deprecated"
  end

  test "rejects malformed move_to" do
    {:error, msg} = Path.validate([{:move_to, "10", 20}])
    assert msg =~ "operation is invalid"
  end

  test "rejects malformed line_to" do
    {:error, msg} = Path.validate([{:line_to, "10", 20}])
    assert msg =~ "operation is invalid"
  end

  test "rejects malformed bezier_to" do
    {:error, msg} = Path.validate([{:bezier_to, 10, "11", 20, 21, 30, 40}])
    assert msg =~ "operation is invalid"
  end

  test "rejects malformed quadratic_to" do
    {:error, msg} = Path.validate([{:quadratic_to, 10, 11, "50", 60}])
    assert msg =~ "operation is invalid"
  end

  test "rejects malformed arc_to" do
    {:error, msg} = Path.validate([{:arc_to, 70, 80, 90, "100", 20}])
    assert msg =~ "operation is invalid"
  end

  test "rejects totally wrong commands" do
    {:error, msg} = Path.validate(["Not even close"])
    assert msg =~ "operation is invalid"
  end

  test "validate rejects bad data" do
    {:error, msg} = Path.validate(:banana)
    assert msg =~ "Invalid Path"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Path.valid_styles() == [
             :hidden,
             :scissor,
             :fill,
             :stroke_width,
             :stroke_fill,
             :cap,
             :join,
             :miter_limit
           ]
  end

  # ============================================================================
  # compile

  # NOTE: The compiled script is backwards. This is an inline script, which means
  # Script.finish() is called on it later as part of the graph compile process.
  test "compile works" do
    p = Path.build(@data)

    assert Path.compile(p, %{stroke_fill: :blue}) ==
             [
               :stroke_path,
               :close_path,
               {:arc_to, {70, 80, 90, 100, 20}},
               {:quadratic_to, {10, 11, 50, 60}},
               {:bezier_to, {10, 11, 20, 21, 30, 40}},
               {:line_to, {30, 40}},
               {:move_to, {10, 20}},
               :begin_path
             ]
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
