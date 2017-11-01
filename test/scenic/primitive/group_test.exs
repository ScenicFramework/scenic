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

  @end_id_ref_marker    <<0xff, 0xff, 0xff, 0xff>>

  #============================================================================
  test "type_code 1" do
    assert Group.type_code() == <<0 :: unsigned-integer-size(16)-native>>
  end


  #============================================================================
  # build / add
  test "build works" do
    group =  Group.build()
    assert Primitive.get_module(group) == Group
    assert Primitive.get_data(group) == @end_id_ref_marker
  end


  #============================================================================
  # child management
  test "insert_at works" do
    group = Group.build()
    assert Group.get(group) == []

    g = Group.insert_at(group, -1, 1234)
    assert Group.get(g) == [1234]

    g = Group.insert_at(group, -1, 1234)
      |> Group.insert_at(-1, 12345)
    assert Group.get(g) == [1234, 12345]

    g = Group.insert_at(group, -1, 1234)
      |> Group.insert_at(0, 12345)
    assert Group.get(g) == [12345, 1234]
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


  #============================================================================
  # basic data management

  test "get works" do
    g = Group.build()
      |> Group.insert_at( -1, 1234)
      |> Group.insert_at(-1, 12345)
    assert Group.get(g) == [1234, 12345]
  end

  test "put works" do
    group = Group.build()
      |> Group.put( [1234] )
    assert Primitive.get_data(group) == <<
      1234 :: unsigned-integer-size(32)-native,
      @end_id_ref_marker
    >>
  end


  #============================================================================
  # styles
  # group is special in that you can set any style to it

  test "put_style accepts Hidden" do
    p = Group.build()
      |> Primitive.put_style( Style.Hidden.build(true) )
    assert Primitive.get_style(p, Style.Hidden)  ==  Style.Hidden.build(true)
  end


  test "put_style adds all the styles" do
    group = Group.build()
      |> Group.put_style( Style.Color.build({1,2,3,4}) )
      |> Group.put_style( Style.Color2.build({1,2,3,4},{11,12,13,14}) )
      |> Group.put_style( Style.Color3.build({1,2,3,4},{11,12,13,14},{21,22,23,24}) )
      |> Group.put_style( Style.Color4.build({1,2,3,4},{11,12,13,14},{21,22,23,24}, {31,32,33,34}) )

    assert Primitive.get_style(group, Style.Color)  ==  Style.Color.build({1,2,3,4})
    assert Primitive.get_style(group, Style.Color2) ==  Style.Color2.build({1,2,3,4},{11,12,13,14})
    assert Primitive.get_style(group, Style.Color3) ==  Style.Color3.build({1,2,3,4},{11,12,13,14},{21,22,23,24})
    assert Primitive.get_style(group, Style.Color4) ==  Style.Color4.build({1,2,3,4},{11,12,13,14},{21,22,23,24}, {31,32,33,34})
  end

end



































