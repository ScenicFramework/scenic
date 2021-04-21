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

  test "build creates a g texture with black as default clear" do
    {:ok, {:g, @width, @height, pixels, []}} = Texture.build(:g, @width, @height)
    assert byte_size(pixels) == @width * @height

    <<
      0::size(8),
      0::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a g texture" do
    {:ok, {:g, @width, @height, pixels, [clear: 3]}} =
      Texture.build(:g, @width, @height, clear: 3)

    assert byte_size(pixels) == @width * @height

    <<
      3::size(8),
      3::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a g texture with a named color" do
    {:ok, {:g, @width, @height, pixels, [clear: 236]}} =
      Texture.build(:g, @width, @height, clear: :beige)

    assert byte_size(pixels) == @width * @height

    <<
      236::size(8),
      236::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a ga texture with black as default clear" do
    {:ok, {:ga, @width, @height, pixels, []}} = Texture.build(:ga, @width, @height)
    assert byte_size(pixels) == @width * @height * 2

    <<
      0::size(8),
      0xFF::size(8),
      0::size(8),
      0xFF::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a ga texture" do
    {:ok, {:ga, @width, @height, pixels, [clear: {3, 7}]}} =
      Texture.build(:ga, @width, @height, clear: {3, 7})

    assert byte_size(pixels) == @width * @height * 2

    <<
      3::size(8),
      7::size(8),
      3::size(8),
      7::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a ga texture from a named clear color" do
    {:ok, {:ga, @width, @height, pixels, [clear: {250, 255}]}} =
      Texture.build(:ga, @width, @height, clear: :azure)

    assert byte_size(pixels) == @width * @height * 2

    <<
      250::size(8),
      255::size(8),
      250::size(8),
      255::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a rgb texture with black as default clear" do
    {:ok, {:rgb, @width, @height, pixels, []}} = Texture.build(:rgb, @width, @height)
    assert byte_size(pixels) == @width * @height * 3

    <<
      0::size(8),
      0::size(8),
      0::size(8),
      0::size(8),
      0::size(8),
      0::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a rgb texture" do
    {:ok, {:rgb, @width, @height, pixels, [clear: {3, 7, 11}]}} =
      Texture.build(:rgb, @width, @height, clear: {3, 7, 11})

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

  test "build creates a rgb texture with a named clear color" do
    {:ok, {:rgb, @width, @height, pixels, [clear: {189, 183, 107}]}} =
      Texture.build(:rgb, @width, @height, clear: :dark_khaki)

    assert byte_size(pixels) == @width * @height * 3

    <<
      189::size(8),
      183::size(8),
      107::size(8),
      189::size(8),
      183::size(8),
      107::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a rgba texture with black as default clear " do
    {:ok, {:rgba, @width, @height, pixels, []}} = Texture.build(:rgba, @width, @height)
    assert byte_size(pixels) == @width * @height * 4

    <<
      0::size(8),
      0::size(8),
      0::size(8),
      0xFF::size(8),
      0::size(8),
      0::size(8),
      0::size(8),
      0xFF::size(8),
      _::binary
    >> = pixels
  end

  test "build creates a rgba texture" do
    {:ok, {:rgba, @width, @height, pixels, [clear: {3, 7, 11, 17}]}} =
      Texture.build(:rgba, @width, @height, clear: {3, 7, 11, 17})

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

  test "build creates a rgba texture with a named clear color" do
    {:ok, {:rgba, @width, @height, pixels, [clear: {0xF5, 0xFF, 0xFA, 0xFF}]}} =
      Texture.build(:rgba, @width, @height, clear: :mint_cream)

    assert byte_size(pixels) == @width * @height * 4

    <<
      0xF5::size(8),
      0xFF::size(8),
      0xFA::size(8),
      0xFF::size(8),
      0xF5::size(8),
      0xFF::size(8),
      0xFA::size(8),
      0xFF::size(8),
      _::binary
    >> = pixels
  end

  # ============================================================================
  # get and put!

  test "get and put work with g textures" do
    {:ok, tex} = Texture.build(:g, @width, @height, clear: 3)
    assert Texture.get(tex, 1, 1) == 3
    assert Texture.get(tex, 1, 2) == 3

    {:g, @width, @height, _, [clear: 3]} = tex = Texture.put!(tex, 1, 2, 4)
    assert Texture.get(tex, 1, 1) == 3
    assert Texture.get(tex, 1, 2) == 4
  end

  test "get and put work with ga textures" do
    {:ok, tex} = Texture.build(:ga, @width, @height, clear: {3, 7})
    assert Texture.get(tex, 1, 1) == {3, 7}
    assert Texture.get(tex, 1, 2) == {3, 7}

    {:ga, @width, @height, _, [clear: {3, 7}]} = tex = Texture.put!(tex, 1, 2, {4, 8})
    assert Texture.get(tex, 1, 1) == {3, 7}
    assert Texture.get(tex, 1, 2) == {4, 8}
  end

  test "get and put work with rgb textures" do
    {:ok, tex} = Texture.build(:rgb, @width, @height, clear: {3, 7, 11})
    assert Texture.get(tex, 1, 1) == {3, 7, 11}
    assert Texture.get(tex, 1, 2) == {3, 7, 11}

    {:rgb, @width, @height, _, [clear: {3, 7, 11}]} = tex = Texture.put!(tex, 1, 2, {4, 8, 12})
    assert Texture.get(tex, 1, 1) == {3, 7, 11}
    assert Texture.get(tex, 1, 2) == {4, 8, 12}
  end

  test "get and put work with rgba textures" do
    {:ok, tex} = Texture.build(:rgba, @width, @height, clear: {3, 7, 11, 13})
    assert Texture.get(tex, 1, 1) == {3, 7, 11, 13}
    assert Texture.get(tex, 1, 2) == {3, 7, 11, 13}

    {:rgba, @width, @height, _, [clear: {3, 7, 11, 13}]} =
      tex = Texture.put!(tex, 1, 2, {4, 8, 12, 14})

    assert Texture.get(tex, 1, 1) == {3, 7, 11, 13}
    assert Texture.get(tex, 1, 2) == {4, 8, 12, 14}
  end

  # ============================================================================
  # clear!

  test "clear! works with g textures" do
    {:ok, tex} = Texture.build(:g, @width, @height, clear: 3)
    assert Texture.get(tex, 1, 1) == 3
    assert Texture.get(tex, 1, 2) == 3

    tex = Texture.clear!(tex, 4)
    assert Texture.get(tex, 1, 1) == 4
    assert Texture.get(tex, 1, 2) == 4
    assert Texture.get(tex, 10, 12) == 4
  end

  test "clear! works with g textures uses black by default" do
    tex =
      Texture.build!(:g, @width, @height)
      |> Texture.put!(1, 1, 7)
      |> Texture.put!(1, 2, 9)
      |> Texture.put!(10, 12, 11)

    assert Texture.get(tex, 1, 1) == 7
    assert Texture.get(tex, 1, 2) == 9
    assert Texture.get(tex, 10, 12) == 11
    assert Texture.get(tex, 1, 3) == 0

    tex = Texture.clear!(tex)
    assert Texture.get(tex, 1, 1) == 0
    assert Texture.get(tex, 1, 2) == 0
    assert Texture.get(tex, 10, 12) == 0
    assert Texture.get(tex, 1, 3) == 0
  end

  test "clear! works with g textures uses texture clear by default" do
    tex =
      Texture.build!(:g, @width, @height, clear: :dark_khaki)
      |> Texture.put!(1, 1, 7)
      |> Texture.put!(1, 2, 9)
      |> Texture.put!(10, 12, 11)

    assert Texture.get(tex, 1, 1) == 7
    assert Texture.get(tex, 1, 2) == 9
    assert Texture.get(tex, 10, 12) == 11
    assert Texture.get(tex, 1, 3) == 159

    tex = Texture.clear!(tex)
    assert Texture.get(tex, 1, 1) == 159
    assert Texture.get(tex, 1, 2) == 159
    assert Texture.get(tex, 10, 12) == 159
    assert Texture.get(tex, 1, 3) == 159
  end

  test "clear! works with ga textures" do
    {:ok, tex} = Texture.build(:ga, @width, @height, clear: {3, 7})
    assert Texture.get(tex, 1, 1) == {3, 7}
    assert Texture.get(tex, 1, 2) == {3, 7}
    assert Texture.get(tex, 10, 12) == {3, 7}

    tex = Texture.clear!(tex, {4, 8})
    assert Texture.get(tex, 1, 1) == {4, 8}
    assert Texture.get(tex, 1, 2) == {4, 8}
    assert Texture.get(tex, 10, 12) == {4, 8}
  end

  test "clear! works with ga textures uses black by default" do
    tex =
      Texture.build!(:ga, @width, @height)
      |> Texture.put!(1, 1, {3, 7})
      |> Texture.put!(1, 2, {4, 8})
      |> Texture.put!(10, 12, {6, 9})

    assert Texture.get(tex, 1, 1) == {3, 7}
    assert Texture.get(tex, 1, 2) == {4, 8}
    assert Texture.get(tex, 10, 12) == {6, 9}
    assert Texture.get(tex, 1, 3) == {0, 0xFF}

    tex = Texture.clear!(tex)
    assert Texture.get(tex, 1, 1) == {0, 0xFF}
    assert Texture.get(tex, 1, 2) == {0, 0xFF}
    assert Texture.get(tex, 10, 12) == {0, 0xFF}
  end

  test "clear! works with ga textures uses texture clear by default" do
    tex =
      Texture.build!(:ga, @width, @height, clear: :dark_khaki)
      |> Texture.put!(1, 1, {3, 7})
      |> Texture.put!(1, 2, {4, 8})
      |> Texture.put!(10, 12, {6, 9})

    assert Texture.get(tex, 1, 1) == {3, 7}
    assert Texture.get(tex, 1, 2) == {4, 8}
    assert Texture.get(tex, 10, 12) == {6, 9}
    assert Texture.get(tex, 1, 3) == {159, 0xFF}

    tex = Texture.clear!(tex)
    assert Texture.get(tex, 1, 1) == {159, 0xFF}
    assert Texture.get(tex, 1, 2) == {159, 0xFF}
    assert Texture.get(tex, 10, 12) == {159, 0xFF}
  end

  test "clear! works with rgb textures" do
    {:ok, tex} = Texture.build(:rgb, @width, @height, clear: {3, 7, 11})
    assert Texture.get(tex, 1, 1) == {3, 7, 11}
    assert Texture.get(tex, 1, 2) == {3, 7, 11}
    assert Texture.get(tex, 10, 12) == {3, 7, 11}

    tex = Texture.clear!(tex, {4, 8, 12})
    assert Texture.get(tex, 1, 1) == {4, 8, 12}
    assert Texture.get(tex, 1, 2) == {4, 8, 12}
    assert Texture.get(tex, 10, 12) == {4, 8, 12}
  end

  test "clear! works with rgb textures uses black by default" do
    tex =
      Texture.build!(:rgb, @width, @height)
      |> Texture.put!(1, 1, {3, 7, 11})
      |> Texture.put!(1, 2, {4, 8, 12})
      |> Texture.put!(10, 12, {6, 9, 11})

    assert Texture.get(tex, 1, 1) == {3, 7, 11}
    assert Texture.get(tex, 1, 2) == {4, 8, 12}
    assert Texture.get(tex, 10, 12) == {6, 9, 11}
    assert Texture.get(tex, 1, 3) == {0, 0, 0}

    tex = Texture.clear!(tex)
    assert Texture.get(tex, 1, 1) == {0, 0, 0}
    assert Texture.get(tex, 1, 2) == {0, 0, 0}
    assert Texture.get(tex, 10, 12) == {0, 0, 0}
    assert Texture.get(tex, 1, 3) == {0, 0, 0}
  end

  test "clear! works with rgb textures uses texture clear by default" do
    tex =
      Texture.build!(:rgb, @width, @height, clear: :dark_khaki)
      |> Texture.put!(1, 1, {3, 7, 11})
      |> Texture.put!(1, 2, {4, 8, 12})
      |> Texture.put!(10, 12, {6, 9, 11})

    assert Texture.get(tex, 1, 1) == {3, 7, 11}
    assert Texture.get(tex, 1, 2) == {4, 8, 12}
    assert Texture.get(tex, 10, 12) == {6, 9, 11}
    assert Texture.get(tex, 1, 3) == {189, 183, 107}

    tex = Texture.clear!(tex)
    assert Texture.get(tex, 1, 1) == {189, 183, 107}
    assert Texture.get(tex, 1, 2) == {189, 183, 107}
    assert Texture.get(tex, 10, 12) == {189, 183, 107}
    assert Texture.get(tex, 1, 3) == {189, 183, 107}
  end

  test "clear! works with rgba textures" do
    {:ok, tex} = Texture.build(:rgba, @width, @height, clear: {3, 7, 11, 13})
    assert Texture.get(tex, 1, 1) == {3, 7, 11, 13}
    assert Texture.get(tex, 1, 2) == {3, 7, 11, 13}
    assert Texture.get(tex, 10, 12) == {3, 7, 11, 13}

    tex = Texture.clear!(tex, {4, 8, 12, 14})
    assert Texture.get(tex, 1, 1) == {4, 8, 12, 14}
    assert Texture.get(tex, 1, 2) == {4, 8, 12, 14}
    assert Texture.get(tex, 10, 12) == {4, 8, 12, 14}
  end

  test "clear! works with rgba textures uses black by default" do
    tex =
      Texture.build!(:rgba, @width, @height)
      |> Texture.put!(1, 1, {3, 7, 11, 13})
      |> Texture.put!(1, 2, {4, 8, 12, 14})
      |> Texture.put!(10, 12, {6, 9, 11, 13})

    assert Texture.get(tex, 1, 1) == {3, 7, 11, 13}
    assert Texture.get(tex, 1, 2) == {4, 8, 12, 14}
    assert Texture.get(tex, 10, 12) == {6, 9, 11, 13}
    assert Texture.get(tex, 1, 3) == {0, 0, 0, 0xFF}

    tex = Texture.clear!(tex)
    assert Texture.get(tex, 1, 1) == {0, 0, 0, 0xFF}
    assert Texture.get(tex, 1, 2) == {0, 0, 0, 0xFF}
    assert Texture.get(tex, 10, 12) == {0, 0, 0, 0xFF}
    assert Texture.get(tex, 1, 3) == {0, 0, 0, 0xFF}
  end

  test "clear! works with rgba textures uses texture clear by default" do
    tex =
      Texture.build!(:rgba, @width, @height, clear: :dark_khaki)
      |> Texture.put!(1, 1, {3, 7, 11, 13})
      |> Texture.put!(1, 2, {4, 8, 12, 14})
      |> Texture.put!(10, 12, {6, 9, 11, 13})

    assert Texture.get(tex, 1, 1) == {3, 7, 11, 13}
    assert Texture.get(tex, 1, 2) == {4, 8, 12, 14}
    assert Texture.get(tex, 10, 12) == {6, 9, 11, 13}
    assert Texture.get(tex, 1, 3) == {189, 183, 107, 255}

    tex = Texture.clear!(tex)
    assert Texture.get(tex, 1, 1) == {189, 183, 107, 255}
    assert Texture.get(tex, 1, 2) == {189, 183, 107, 255}
    assert Texture.get(tex, 10, 12) == {189, 183, 107, 255}
    assert Texture.get(tex, 1, 3) == {189, 183, 107, 255}
  end

  # ============================================================================
  # to_rgba

  test "to_rgba works with g textures" do
    {:ok, tex} = Texture.build(:g, @width, @height, clear: 3)
    tex2 = Texture.to_rgba(tex)
    {:rgba, @width, @height, p, [clear: 3]} = tex2
    assert byte_size(p) == @width * @height * 4
    assert Texture.get(tex2, 1, 1) == {3, 3, 3, 0xFF}
    assert Texture.get(tex2, 1, 2) == {3, 3, 3, 0xFF}
  end

  test "to_rgba works with ga textures" do
    {:ok, tex} = Texture.build(:ga, @width, @height, clear: {3, 7})
    tex2 = Texture.to_rgba(tex)
    {:rgba, @width, @height, p, [clear: {3, 7}]} = tex2
    assert byte_size(p) == @width * @height * 4
    assert Texture.get(tex2, 1, 1) == {3, 3, 3, 7}
    assert Texture.get(tex2, 1, 2) == {3, 3, 3, 7}
  end

  test "to_rgba works with rgb textures" do
    {:ok, tex} = Texture.build(:rgb, @width, @height, clear: {3, 7, 11})
    tex2 = Texture.to_rgba(tex)
    {:rgba, @width, @height, p, [clear: {3, 7, 11}]} = tex2
    assert byte_size(p) == @width * @height * 4
    assert Texture.get(tex2, 1, 1) == {3, 7, 11, 0xFF}
    assert Texture.get(tex2, 1, 2) == {3, 7, 11, 0xFF}
  end

  test "to_rgba does nothing with rgba textures" do
    {:ok, tex} = Texture.build(:rgba, @width, @height, clear: {3, 7, 11, 13})
    tex2 = Texture.to_rgba(tex)
    assert tex === tex2
  end
end
