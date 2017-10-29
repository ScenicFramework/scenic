#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.TriangleTest do
  use ExUnit.Case, async: true
  doctest Exui

  alias Scenic.Primitive
  alias Scenic.Primitive.Triangle
  alias Scenic.Primitive.Style


  #============================================================================
  test "type_code" do
    assert Triangle.type_code() == <<2 :: unsigned-integer-size(16)-native>>
  end

  #============================================================================
  # build / add

  test "build works" do
    p = Triangle.build( {{10,11}, {20,21}, {30,31}} )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Triangle
    assert Primitive.get_data(p) == <<
      10 :: unsigned-integer-size(16)-native,
      11 :: unsigned-integer-size(16)-native,
      20 :: unsigned-integer-size(16)-native,
      21 :: unsigned-integer-size(16)-native,
      30 :: unsigned-integer-size(16)-native,
      31 :: unsigned-integer-size(16)-native
    >>
  end


  #============================================================================
  # get / put

  test "get works" do
    line = Triangle.build( {{10,11}, {20,21}, {30,31}} )
    assert Triangle.get(line) == { {10,11}, {20,21}, {30,31} }
  end

  test "put works" do
    line = Triangle.build( {{10,11}, {20,21}, {30,31}} )
      |> Triangle.put( {110,111}, {120,121}, {230,231} )
    assert Triangle.get(line) == { {110,111}, {120,121}, {230,231} }
  end


  #============================================================================
  # styles
  
  test "put_style accepts Hidden" do
    p = Triangle.build( {{10,11}, {20,21}, {30,31}} )
      |> Primitive.put_style( Style.Hidden.build(true) )
    assert Primitive.get_style(p, Style.Hidden)  ==  Style.Hidden.build(true)
  end

  test "put_style accepts Color" do
    triangle = Triangle.build( {{10,11}, {20,21}, {30,31}} )
      |> Triangle.put_style( Style.Color.build(:red) )
    assert Primitive.get_style(triangle, Style.Color)  ==  Style.Color.build(:red)
  end

  test "put_style accepts Color3" do
    triangle = Triangle.build( {{10,11}, {20,21}, {30,31}} )
      |> Triangle.put_style( Style.Color3.build(:red, :green, :burly_wood) )
    assert Primitive.get_style(triangle, Style.Color3) ==  Style.Color3.build(:red, :green, :burly_wood)
  end

  test "put_style is exclusive between Color and Color3" do
    triangle = Triangle.build( {{10,11}, {20,21}, {30,31}} )
      |> Triangle.put_style( Style.Color.build(:green) )
    assert Primitive.get_style(triangle, Style.Color)  ==  Style.Color.build(:green)
    assert Primitive.get_style(triangle, Style.Color3)  ==  nil

    triangle = Triangle.put_style( triangle, Style.Color3.build(:red, :green, :burly_wood) )
    assert Primitive.get_style(triangle, Style.Color)  ==  nil
    assert Primitive.get_style(triangle, Style.Color3) ==  Style.Color3.build(:red, :green, :burly_wood)
    
    triangle = Triangle.put_style( triangle, Style.Color.build(:cornsilk) )
    assert Primitive.get_style(triangle, Style.Color)  ==  Style.Color.build(:cornsilk)
    assert Primitive.get_style(triangle, Style.Color3) ==  nil
  end

end

