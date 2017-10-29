#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.RoundedRectangleTest do
  use ExUnit.Case, async: true
  doctest Exui

  alias Scenic.Primitive
  alias Scenic.Primitive.RoundedRectangle
  alias Scenic.Primitive.Style
  

  #============================================================================
  test "type_code" do
    assert RoundedRectangle.type_code() == <<5 :: unsigned-integer-size(16)-native>>
  end

  #============================================================================
  # build / add

  test "build works" do
    p = RoundedRectangle.build( {{10,11}, 40, 80, 4} )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == RoundedRectangle
    assert Primitive.get_data(p) == <<
      10 :: unsigned-integer-size(16)-native,
      11 :: unsigned-integer-size(16)-native,
      40 :: unsigned-integer-size(16)-native,
      80 :: unsigned-integer-size(16)-native,
      4  :: unsigned-integer-size(16)-native
    >>
  end


  #============================================================================
  # get / put

  test "get works" do
    rrect = RoundedRectangle.build( {{10,11}, 40, 80, 4} )
    assert RoundedRectangle.get(rrect) == { {10,11}, 40, 80, 4 }
  end

  test "put works" do
    rrect = RoundedRectangle.build( {{10,11}, 40, 80, 4} )
      |> RoundedRectangle.put( {110,111}, 100, 30, 5 )
    assert RoundedRectangle.get(rrect) == { {110,111}, 100, 30, 5 }
  end


  #============================================================================
  # styles

  test "put_style accepts Hidden" do
    p = RoundedRectangle.build( {{10,11}, 40, 80, 4} )
      |> Primitive.put_style( Style.Hidden.build(true) )
    assert Primitive.get_style(p, Style.Hidden)  ==  Style.Hidden.build(true)
  end

  test "put_style accepts Color" do
    rrect = RoundedRectangle.build( {{10,11}, 40, 80, 4} )
      |> RoundedRectangle.put_style( Style.Color.build(:red) )
    assert Primitive.get_style(rrect, Style.Color)  ==  Style.Color.build(:red)
  end

  test "put_style accepts Color4" do
    rrect = RoundedRectangle.build( {{10,11}, 40, 80, 4} )
      |> RoundedRectangle.put_style( Style.Color4.build(:red, :green, :burly_wood, :cornsilk) )
    assert Primitive.get_style(rrect, Style.Color4) ==  Style.Color4.build(:red, :green, :burly_wood, :cornsilk)
  end

  test "put_style is exclusive between Color and Color4" do
    rrect = RoundedRectangle.build( {{10,11}, 40, 80, 4} )
      |> RoundedRectangle.put_style( Style.Color.build(:green) )
    assert Primitive.get_style(rrect, Style.Color)  ==  Style.Color.build(:green)
    assert Primitive.get_style(rrect, Style.Color4)  ==  nil

    rrect = RoundedRectangle.put_style( rrect, Style.Color4.build(:red, :green, :burly_wood, :cornsilk) )
    assert Primitive.get_style(rrect, Style.Color)  ==  nil
    assert Primitive.get_style(rrect, Style.Color4) ==  Style.Color4.build(:red, :green, :burly_wood, :cornsilk)
    
    rrect = RoundedRectangle.put_style( rrect, Style.Color.build(:cornsilk) )
    assert Primitive.get_style(rrect, Style.Color)  ==  Style.Color.build(:cornsilk)
    assert Primitive.get_style(rrect, Style.Color4) ==  nil
  end


end



































