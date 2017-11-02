#
#  Created by Boyd Multerer on 5/7817.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.GroupTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Group

  @data    [1,2,3,4]


  #============================================================================
  # build / add
  test "build works" do
    p = Group.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Group
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # child management
  test "insert_at works" do
    group = Group.build()
    assert Primitive.get(group) == []

    g = Group.insert_at(group, -1, 1234)
    assert Primitive.get(g) == [1234]

    g = Group.insert_at(group, -1, 1234)
      |> Group.insert_at(-1, 12345)
    assert Primitive.get(g) == [1234, 12345]

    g = Group.insert_at(group, -1, 1234)
      |> Group.insert_at(0, 12345)
    assert Primitive.get(g) == [12345, 1234]
  end

  test "delete works" do
    g = Group.build()
      |> Group.insert_at( -1, 1234)
      |> Group.insert_at(-1, 12345)
    assert Group.get(g) == [1234, 12345]

    g = Group.delete(g, 1234)
    assert Group.get(g) == [12345]
  end

  test "increment_data adds a constant to the child ids" do
    g = Group.build()
      |> Group.insert_at( -1, 1234)
      |> Group.insert_at(-1, 12345)
    assert Group.get(g) == [1234, 12345]

    g = Group.increment(g, 10)
    assert Group.get(g) == [1244, 12355]
  end



end



































