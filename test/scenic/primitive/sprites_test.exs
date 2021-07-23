#
#  Created by Boyd Multerer on 2021-06-24
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.SpritesTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Sprites

  alias Scenic.Primitive
  alias Scenic.Primitive.Sprites

  @id "images/parrot.png"
  @cmds [
    {{0, 1}, {10, 11}, {2, 3}, {12, 13}},
    {{2, 3}, {10, 11}, {4, 5}, {12, 13}}
  ]

  # ============================================================================
  # build / add

  test "build works" do
    p = Sprites.build({@id, @cmds})
    assert p.module == Sprites
    assert Primitive.get(p) == {@id, @cmds}
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert Sprites.validate({@id, @cmds}) == {:ok, {@id, @cmds}}
  end

  test "validate rejects bad data" do
    {:error, msg} = Sprites.validate({@id, "cmds"})
    assert msg =~ "Invalid Sprites"

    {:error, msg} = Sprites.validate(:banana)
    assert msg =~ "Invalid Sprites"
  end

  test "validate rejects unknown image files" do
    {:error, msg} = Sprites.validate({"images/missing.jpg", @cmds})
    assert msg =~ "Invalid Sprites"
  end

  test "validate rejects fonts" do
    {:error, msg} = Sprites.validate({"fonts/roboto.ttf", @cmds})
    assert msg =~ "is a font"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Sprites.valid_styles() == [:hidden, :scissor]
  end

  # ============================================================================
  # compile

  test "compile works" do
    p = Sprites.build({@id, @cmds})
    assert Sprites.compile(p, %{stroke_fill: :blue}) == [{:draw_sprites, {@id, @cmds}}]
  end
end
