#
#  Created by Boyd Multerer on April 2018
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.TextTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Text

  alias Scenic.Primitive
  alias Scenic.Primitive.Text

  @data "test text"

  # ============================================================================
  # build / add

  test "build works" do
    p = Text.build(@data)
    assert p.module == Text
    assert Primitive.get(p) == @data
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert Text.validate(@data) == {:ok, @data}
  end

  test "validate rejects bad data" do
    {:error, msg} = Text.validate({100, "1.4"})
    assert msg =~ "Invalid Text"

    {:error, msg} = Text.validate( :banana )
    assert msg =~ "Invalid Text"
  end


  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Text.valid_styles() == [
             :hidden, :font, :font_size, :line_height,
             :text_align, :text_base, :line_height
           ]
  end


  # ============================================================================
  # compile

  test "compile raises - it is a special case" do
    p = Text.build( @data )
    assert_raise RuntimeError, fn -> Text.compile(p, %{}) end
  end



  # ============================================================================
  # transform helpers

  test "default_pin returns the origin of the text" do
    assert Text.default_pin(@data) == {0, 0}
  end
end
