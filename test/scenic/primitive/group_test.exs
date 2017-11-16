#
#  Created by Boyd Multerer on 5/7817.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.GroupTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Group

  @data    [1,2,3,4]


  #============================================================================
  # build / add
  test "build works" do
    p = Group.build()
    assert Primitive.get(p) == []

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
    assert Primitive.get(g) == [1234, 12345]

    g = Group.delete(g, 1234)
    assert Primitive.get(g) == [12345]
  end

  test "increment_data adds a constant to the child ids" do
    g = Group.build()
      |> Group.insert_at( -1, 1234)
      |> Group.insert_at(-1, 12345)
    assert Primitive.get(g) == [1234, 12345]

    g = Group.increment(g, 10)
    assert Primitive.get(g) == [1244, 12355]
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Group.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Group.verify( 12 )                       == :invalid_data
    assert Group.verify( [1, 2, 3, :banana] )       == :invalid_data
    assert Group.verify( :banana )                  == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Group.valid_styles() == [:all]
  end

  test "filter_styles passes all the style, whether or not they are standard ones" do
    styles = %{
      color: :red,
      banana: :yellow
    }
    assert Group.filter_styles( styles ) == styles
  end

  #============================================================================
  # transforms

  test "default pin simply returns {0,0}" do
    assert Group.default_pin(@data) == {0,0}
  end








end



































