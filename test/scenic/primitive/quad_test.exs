#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.QuadTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Quad
  alias Scenic.Primitive.Style


  #============================================================================
  test "type_code" do
    assert Quad.type_code() == <<3 :: unsigned-integer-size(16)-native>>
  end

  #============================================================================
  # build / add

  test "build works" do
    p = Quad.build( {{10,11}, {20,21}, {30,31}, {40,41}} )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Quad
    assert Primitive.get_data(p) == <<
      10 :: unsigned-integer-size(16)-native,
      11 :: unsigned-integer-size(16)-native,
      20 :: unsigned-integer-size(16)-native,
      21 :: unsigned-integer-size(16)-native,
      30 :: unsigned-integer-size(16)-native,
      31 :: unsigned-integer-size(16)-native,
      40 :: unsigned-integer-size(16)-native,
      41 :: unsigned-integer-size(16)-native
    >>
  end


  #============================================================================
  # get / put

  test "get works" do
    quad = Quad.build( {{10,11}, {20,21}, {30,31}, {40,41}} )
    assert Quad.get(quad) == { {10,11}, {20,21}, {30,31}, {40,41} }
  end

  test "put works" do
    quad = Quad.build( {{10,11}, {20,21}, {30,31}, {40,41}} )
      |> Quad.put( {110,111}, {120,121}, {130,131}, {140,141} )
    assert Quad.get(quad) == { {110,111}, {120,121}, {130,131}, {140,141} }
  end


  #============================================================================
  # styles

  test "put_style accepts Hidden" do
    p = Quad.build( {{10,11}, {20,21}, {30,31}, {40,41}} )
      |> Primitive.put_style( Style.Hidden.build(true) )
    assert Primitive.get_style(p, Style.Hidden)  ==  Style.Hidden.build(true)
  end

  test "put_style accepts Color" do
    quad = Quad.build( {{10,11}, {20,21}, {30,31}, {40,41}} )
      |> Quad.put_style( Style.Color.build(:red) )
    assert Primitive.get_style(quad, Style.Color)  ==  Style.Color.build(:red)
  end

  test "put_style accepts Color4" do
    quad = Quad.build( {{10,11}, {20,21}, {30,31}, {40,41}} )
      |> Quad.put_style( Style.Color4.build(:red, :green, :burly_wood, :cornsilk) )
    assert Primitive.get_style(quad, Style.Color4) ==  Style.Color4.build(:red, :green, :burly_wood, :cornsilk)
  end

  test "put_style is exclusive between Color and Color4" do
    quad = Quad.build( {{10,11}, {20,21}, {30,31}, {40,41}} )
      |> Quad.put_style( Style.Color.build(:green) )
    assert Primitive.get_style(quad, Style.Color)  ==  Style.Color.build(:green)
    assert Primitive.get_style(quad, Style.Color4)  ==  nil

    quad = Quad.put_style( quad, Style.Color4.build(:red, :green, :burly_wood, :cornsilk) )
    assert Primitive.get_style(quad, Style.Color)  ==  nil
    assert Primitive.get_style(quad, Style.Color4) ==  Style.Color4.build(:red, :green, :burly_wood, :cornsilk)
    
    quad = Quad.put_style( quad, Style.Color.build(:cornsilk) )
    assert Primitive.get_style(quad, Style.Color)  ==  Style.Color.build(:cornsilk)
    assert Primitive.get_style(quad, Style.Color4) ==  nil
  end

end


































