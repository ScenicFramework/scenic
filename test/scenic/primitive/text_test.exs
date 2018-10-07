#
#  Created by Boyd Multerer on April 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.TextTest do
  use ExUnit.Case, async: true
  doctest Scenic

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
  # verify

  test "info works" do
    assert Text.info(:test_data) =~ ":test_data"
  end

  test "verify passes valid data" do
    assert Text.verify(@data) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Text.verify(:text_text) == :invalid_data
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Text.valid_styles() == [
             :hidden,
             :fill,
             :font,
             :font_size,
             :font_blur,
             :text_align,
             :text_height
           ]
  end

  # ============================================================================
  # transform helpers

  test "default_pin returns the origin of the text" do
    assert Text.default_pin(@data) == {0, 0}
  end

  # ============================================================================
  # put

  test "put can update position and string" do
    p =
      Text.build(@data)
      |> Text.put("new text")

    assert Primitive.get(p) == "new text"
  end
end
