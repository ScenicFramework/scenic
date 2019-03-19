#
#  Created by Boyd Multerer on 2017-05-07.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Utilities.TextureTest do
  use ExUnit.Case, async: true
  doctest Scenic.Utilities.Texture

  alias Scenic.Utilities.Texture

  @width 11
  @height 13

  # ============================================================================
  # build

  test "build creates a g texture" do
    {:g, @width, @height, pixels} = Texture.build(:g, @width, @height, 3)
    assert byte_size(pixels) == @width * @height

    <<
      3::size(8),
      3::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a ga texture" do
    {:ga, @width, @height, pixels} = Texture.build(:ga, @width, @height, {3, 7})
    assert byte_size(pixels) == @width * @height * 2

    <<
      3::size(8),
      7::size(8),
      3::size(8),
      7::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a rgb texture" do
    {:rgb, @width, @height, pixels} = Texture.build(:rgb, @width, @height, {3, 7, 11})
    assert byte_size(pixels) == @width * @height * 3

    <<
      3::size(8),
      7::size(8),
      11::size(8),
      3::size(8),
      7::size(8),
      11::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a rgba texture" do
    {:rgba, @width, @height, pixels} = Texture.build(:rgba, @width, @height, {3, 7, 11, 17})
    assert byte_size(pixels) == @width * @height * 4

    <<
      3::size(8),
      7::size(8),
      11::size(8),
      17::size(8),
      3::size(8),
      7::size(8),
      11::size(8),
      17::size(8),
      _::binary
    >> = pixels
  end

  # ============================================================================
  # get and put!

  test "get and put work with g textures" do
    tex = Texture.build(:g, @width, @height, 3)
    assert Texture.get(tex, 1, 1) == 3
    assert Texture.get(tex, 1, 2) == 3

    {:g, @width, @height, _} = tex = Texture.put!(tex, 1, 2, 4)
    assert Texture.get(tex, 1, 1) == 3
    assert Texture.get(tex, 1, 2) == 4
  end

  test "get and put work with ga textures" do
    tex = Texture.build(:ga, @width, @height, {3, 7})
    assert Texture.get(tex, 1, 1) == {3, 7}
    assert Texture.get(tex, 1, 2) == {3, 7}

    {:ga, @width, @height, _} = tex = Texture.put!(tex, 1, 2, {4, 8})
    assert Texture.get(tex, 1, 1) == {3, 7}
    assert Texture.get(tex, 1, 2) == {4, 8}
  end

  test "get and put work with rgb textures" do
    tex = Texture.build(:rgb, @width, @height, {3, 7, 11})
    assert Texture.get(tex, 1, 1) == {3, 7, 11}
    assert Texture.get(tex, 1, 2) == {3, 7, 11}

    {:rgb, @width, @height, _} = tex = Texture.put!(tex, 1, 2, {4, 8, 12})
    assert Texture.get(tex, 1, 1) == {3, 7, 11}
    assert Texture.get(tex, 1, 2) == {4, 8, 12}
  end

  test "get and put work with rgba textures" do
    tex = Texture.build(:rgba, @width, @height, {3, 7, 11, 13})
    assert Texture.get(tex, 1, 1) == {3, 7, 11, 13}
    assert Texture.get(tex, 1, 2) == {3, 7, 11, 13}

    {:rgba, @width, @height, _} = tex = Texture.put!(tex, 1, 2, {4, 8, 12, 14})
    assert Texture.get(tex, 1, 1) == {3, 7, 11, 13}
    assert Texture.get(tex, 1, 2) == {4, 8, 12, 14}
  end

  # ============================================================================
  # clear!

  test "clear! works with g textures" do
    tex = Texture.build(:g, @width, @height, 3)
    assert Texture.get(tex, 1, 1) == 3
    assert Texture.get(tex, 1, 2) == 3

    tex = Texture.clear!(tex, 4)
    assert Texture.get(tex, 1, 1) == 4
    assert Texture.get(tex, 1, 2) == 4
  end

  test "clear! work with ga textures" do
    tex = Texture.build(:ga, @width, @height, {3, 7})
    assert Texture.get(tex, 1, 1) == {3, 7}
    assert Texture.get(tex, 1, 2) == {3, 7}

    tex = Texture.clear!(tex, {4, 8})
    assert Texture.get(tex, 1, 1) == {4, 8}
    assert Texture.get(tex, 1, 2) == {4, 8}
  end

  test "clear! work with rgb textures" do
    tex = Texture.build(:rgb, @width, @height, {3, 7, 11})
    assert Texture.get(tex, 1, 1) == {3, 7, 11}
    assert Texture.get(tex, 1, 2) == {3, 7, 11}

    tex = Texture.clear!(tex, {4, 8, 12})
    assert Texture.get(tex, 1, 1) == {4, 8, 12}
    assert Texture.get(tex, 1, 2) == {4, 8, 12}
  end

  test "clear! work with rgba textures" do
    tex = Texture.build(:rgba, @width, @height, {3, 7, 11, 13})
    assert Texture.get(tex, 1, 1) == {3, 7, 11, 13}
    assert Texture.get(tex, 1, 2) == {3, 7, 11, 13}

    tex = Texture.clear!(tex, {4, 8, 12, 14})
    assert Texture.get(tex, 1, 1) == {4, 8, 12, 14}
    assert Texture.get(tex, 1, 2) == {4, 8, 12, 14}
  end

  # ============================================================================
  # to_rgba

  test "to_rgba works with g textures" do
    tex = Texture.build(:g, @width, @height, 3)
    tex2 = Texture.to_rgba(tex)
    {:rgba, @width, @height, p} = tex2
    assert byte_size(p) == @width * @height * 4
    assert Texture.get(tex2, 1, 1) == {3, 3, 3, 0xFF}
    assert Texture.get(tex2, 1, 2) == {3, 3, 3, 0xFF}
  end

  test "to_rgba works with ga textures" do
    tex = Texture.build(:ga, @width, @height, {3, 7})
    tex2 = Texture.to_rgba(tex)
    {:rgba, @width, @height, p} = tex2
    assert byte_size(p) == @width * @height * 4
    assert Texture.get(tex2, 1, 1) == {3, 3, 3, 7}
    assert Texture.get(tex2, 1, 2) == {3, 3, 3, 7}
  end

  test "to_rgba works with rgb textures" do
    tex = Texture.build(:rgb, @width, @height, {3, 7, 11})
    tex2 = Texture.to_rgba(tex)
    {:rgba, @width, @height, p} = tex2
    assert byte_size(p) == @width * @height * 4
    assert Texture.get(tex2, 1, 1) == {3, 7, 11, 0xFF}
    assert Texture.get(tex2, 1, 2) == {3, 7, 11, 0xFF}
  end

  test "to_rgba does nothing with rgba textures" do
    tex = Texture.build(:rgba, @width, @height, {3, 7, 11, 13})
    tex2 = Texture.to_rgba(tex)
    assert tex === tex2
  end
end
