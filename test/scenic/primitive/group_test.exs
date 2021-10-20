#
#  Created by Boyd Multerer on 5/7817.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.GroupTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Group

  alias Scenic.Primitive
  alias Scenic.Primitive.Group

  @data [1, 2, 3, 4]

  # ============================================================================
  # build / add
  test "build works" do
    p = Group.build([])
    assert Primitive.get(p) == []

    p = Group.build(@data)
    assert p.module == Group
    assert Primitive.get(p) == @data
  end

  # ============================================================================
  # child management
  test "insert_at works" do
    group = Group.build([])
    assert Primitive.get(group) == []

    g = Group.insert_at(group, -1, 1234)
    assert Primitive.get(g) == [1234]

    g =
      group
      |> Group.insert_at(-1, 1234)
      |> Group.insert_at(-1, 12_345)

    assert Primitive.get(g) == [1234, 12_345]

    g =
      group
      |> Group.insert_at(-1, 1234)
      |> Group.insert_at(0, 12_345)

    assert Primitive.get(g) == [12_345, 1234]
  end

  test "delete works" do
    g =
      Group.build([])
      |> Group.insert_at(-1, 1234)
      |> Group.insert_at(-1, 12_345)

    assert Primitive.get(g) == [1234, 12_345]

    g = Group.delete(g, 1234)
    assert Primitive.get(g) == [12_345]
  end

  test "increment_data adds a constant to the child ids" do
    g =
      Group.build([])
      |> Group.insert_at(-1, 1234)
      |> Group.insert_at(-1, 12_345)

    assert Primitive.get(g) == [1234, 12_345]

    g = Group.increment(g, 10)
    assert Primitive.get(g) == [1244, 12_355]
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert Group.validate(@data) == {:ok, @data}
  end

  test "validate rejects bad data" do
    {:error, msg} = Group.validate([1, -2, 3])
    assert msg =~ "Invalid Group"

    {:error, msg} = Group.validate([1, :banana, 3])
    assert msg =~ "Invalid Group"

    {:error, msg} = Group.validate(:banana)
    assert msg =~ "Invalid Group"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Group.valid_styles() == [:hidden, :scissor]
  end

  # ============================================================================
  # compile

  test "compile raises - it is a special case" do
    p = Group.build([1, 2, 3])
    assert_raise RuntimeError, fn -> Group.compile(p, %{}) end
  end

  # ============================================================================
  # transforms

  test "default pin simply returns {0,0}" do
    assert Group.default_pin(@data) == {0, 0}
  end
end
