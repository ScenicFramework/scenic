#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.TextTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Text
  alias Scenic.Primitive.Style

  @test_text        "Some text to test"

  @font_folder_path Mix.Project.build_path
    |> String.split( "/" )
    |> Enum.drop( -2 )
    |> List.insert_at(-1, "fonts")
    |> Enum.join( "/" )

  @font_one         @font_folder_path <> "/test/font_one.ttf"

  #============================================================================
  test "type_code" do
    assert Text.type_code() == <<4 :: unsigned-integer-size(16)-native>>
  end

  #============================================================================
  # build / add

  test "build works" do
    p = Text.build( {{10,11}, @test_text} )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Text
    assert Primitive.get_data(p) == <<
      10 :: unsigned-integer-size(16)-native,
      11 :: unsigned-integer-size(16)-native,
      byte_size(@test_text) :: unsigned-integer-size(16)-native,
      @test_text :: bitstring
    >>
  end


  #============================================================================
  # get / put

  test "get works" do
    text = Text.build( {{10,11}, @test_text} )
    assert Text.get(text) == { {10,11}, @test_text }
  end

  test "put works" do
    updated_text = "This is a totally different string"
    text = Text.build( {{10,11}, @test_text} )
      |> Text.put( {110,111}, updated_text )
    assert Text.get(text) == { {110,111}, updated_text }
  end

  test "put works with only text - keeps pos unchanged" do
    updated_text = "This is a totally different string"
    text = Text.build( {{10,11}, @test_text} )
      |> Text.put( updated_text )
    assert Text.get(text) == { {10,11}, updated_text }
  end

  #============================================================================
  # styles

  test "put_style accepts Hidden" do
    p = Text.build( {{10,11}, @test_text} )
      |> Primitive.put_style( Style.Hidden.build(true) )
    assert Primitive.get_style(p, Style.Hidden)  ==  Style.Hidden.build(true)
  end

  test "put_style accepts Color" do
    text = Text.build( {{10,11}, @test_text} )
      |> Text.put_style( Style.Color.build(:azure) )
    assert Primitive.get_style(text, Style.Color) ==
      Style.Color.build(:azure)
  end

  test "put_style accepts Font" do
    text = Text.build( {{10,11}, @test_text} )
      |> Text.put_style( Style.Font.build(16, @font_one) )
    assert Primitive.get_style(text, Style.Font) ==
      Style.Font.build(16, @font_one)
  end

end

