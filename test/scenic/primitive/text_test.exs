#
#  Created by Boyd Multerer on April 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.TextTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Text


  @data     {{10,12}, "test text"}


  #============================================================================
  # build / add

  test "build works" do
    p = Text.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Text
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Text.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Text.verify( {{10,12}, :text_text} )       == :invalid_data
    assert Text.verify( {{10,:banana}, "test text"} ) == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Text.valid_styles() == [:hidden, :font, :color, :text_height]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the origin of the text" do
    assert Text.default_pin(@data) == {10,12}
  end

  #============================================================================
  # put

  test "put can update position and string" do
    p = Text.build( @data )
    |> Text.put( {{100, 200}, "new text"} )
    assert Primitive.get(p) == {{100,200}, "new text"}
  end

  test "put can set a string without affecting the position" do
    p = Text.build( @data )
    |> Text.put( "new text" )
    assert Primitive.get(p) == {{10,12}, "new text"}
  end

end

