#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.LineTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Line
  alias Scenic.Primitive.Style


  #============================================================================
  test "type_code" do
    assert Line.type_code() == <<1 :: unsigned-integer-size(16)-native>>
  end

  #============================================================================
  # build / add
  test "build works" do
    p = Line.build( {{10,11}, {20,21}} )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Line
    assert Primitive.get_data(p) == <<
      10 :: unsigned-integer-size(16)-native,
      11 :: unsigned-integer-size(16)-native,
      20 :: unsigned-integer-size(16)-native,
      21 :: unsigned-integer-size(16)-native
    >>
  end


  #============================================================================
  # get / put

  test "get works" do
    line = Line.build( {{10,11}, {20,21}} )
    assert Line.get(line) == { {10,11}, {20,21} }
  end

  test "put works" do
    line = Line.build( {{10,11}, {20,21}} )
      |> Line.put( {30,31}, {40,41} )
    assert Line.get(line) == { {30,31}, {40,41} }
  end


  #============================================================================
  # styles

  test "put_style accepts Hidden" do
    p = Line.build( {{10,11}, {20,21}} )
      |> Primitive.put_style( Style.Hidden.build(true) )
    assert Primitive.get_style(p, Style.Hidden)  ==  Style.Hidden.build(true)
  end

  test "put_style accepts LineWidth" do
    line = Line.build( {{10,11}, {20,21}} )
      |> Line.put_style( Style.LineWidth.build( 3 ) )
    assert Primitive.get_style(line, Style.LineWidth) == Style.LineWidth.build( 3 )
  end

  test "put_style accepts Color" do
    line = Line.build( {{10,11}, {20,21}} )
      |> Line.put_style( Style.Color.build(:red) )
    assert Primitive.get_style(line, Style.Color) == Style.Color.build(:red)
  end

  test "put_style accepts Color2" do
    line = Line.build( {{10,11}, {20,21}} )
      |> Line.put_style( Style.Color2.build(:red,:green) )
    assert Primitive.get_style(line, Style.Color2) == Style.Color2.build(:red,:green)
  end

  test "put_style is exclusive between Color and Color2" do
    line = Line.build( {{10,11}, {20,21}} )
      |> Line.put_style( Style.Color.build(:magenta) )
    assert Primitive.get_style(line, Style.Color) == Style.Color.build(:magenta)
    assert Primitive.get_style(line, Style.Color2) == nil

    line = Line.put_style( line, Style.Color2.build(:cornflower_blue,:azure) )
    assert Primitive.get_style(line, Style.Color) == nil
    assert Primitive.get_style(line, Style.Color2) == Style.Color2.build(:cornflower_blue,:azure)
    
    line = Line.put_style( line, Style.Color.build(:honey_dew) )
    assert Primitive.get_style(line, Style.Color) == Style.Color.build(:honey_dew)
    assert Primitive.get_style(line, Style.Color2) == nil
  end

end



































