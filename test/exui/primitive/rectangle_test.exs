#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.RectangleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Rectangle
  alias Scenic.Primitive.Style


  #============================================================================
  test "type_code" do
    assert Rectangle.type_code() == <<6 :: unsigned-integer-size(16)-native>>
  end

  #============================================================================
  # build / add

  test "build works" do
    p = Rectangle.build( {{10,11}, 40, 80} )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Rectangle
    assert Primitive.get_data(p) == <<
      10 :: unsigned-integer-size(16)-native,
      11 :: unsigned-integer-size(16)-native,
      40 :: unsigned-integer-size(16)-native,
      80 :: unsigned-integer-size(16)-native
    >>
  end


  #============================================================================
  # get / put

  test "get works" do
    rect = Rectangle.build( {{10,11}, 40, 80} )
    assert Rectangle.get(rect) == { {10,11}, 40, 80 }
  end

  test "put works" do
    rect = Rectangle.build( {{10,11}, 40, 80} )
      |> Rectangle.put( {110,111}, 100, 30 )
    assert Rectangle.get(rect) == { {110,111}, 100, 30 }
  end

  #============================================================================
  # styles

  test "put_style accepts Hidden" do
    rect = Rectangle.build( {{10,11}, 40, 80} )
      |> Rectangle.put_style( Style.Hidden.build(true) )
    assert Primitive.get_style(rect, Style.Hidden)  ==  Style.Hidden.build(true)
  end

  test "put_style accepts Color" do
    rect = Rectangle.build( {{10,11}, 40, 80} )
      |> Rectangle.put_style( Style.Color.build(:red) )
    assert Primitive.get_style(rect, Style.Color)  ==  Style.Color.build(:red)
  end

  test "put_style accepts Color4" do
    rect = Rectangle.build( {{10,11}, 40, 80} )
      |> Rectangle.put_style( Style.Color4.build(:red, :green, :burly_wood, :cornsilk) )
    assert Primitive.get_style(rect, Style.Color4) ==  Style.Color4.build(:red, :green, :burly_wood, :cornsilk)
  end

  test "put_style is exclusive between Color and Color4" do
    rect = Rectangle.build( {{10,11}, 40, 80} )
      |> Rectangle.put_style( Style.Color.build(:green) )
    assert Primitive.get_style(rect, Style.Color)  ==  Style.Color.build(:green)
    assert Primitive.get_style(rect, Style.Color4)  ==  nil

    rect = Rectangle.put_style( rect, Style.Color4.build(:red, :green, :burly_wood, :cornsilk) )
    assert Primitive.get_style(rect, Style.Color)  ==  nil
    assert Primitive.get_style(rect, Style.Color4) ==  Style.Color4.build(:red, :green, :burly_wood, :cornsilk)
    
    rect = Rectangle.put_style( rect, Style.Color.build(:cornsilk) )
    assert Primitive.get_style(rect, Style.Color)  ==  Style.Color.build(:cornsilk)
    assert Primitive.get_style(rect, Style.Color4) ==  nil
  end

end

