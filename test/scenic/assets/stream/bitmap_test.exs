#
#  Created by Boyd Multerer on 2021-04-19
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Stream.BitmapTest do
  use ExUnit.Case, async: true
  doctest Scenic.Assets.Stream.Bitmap

  alias Scenic.Color
  alias Scenic.Assets.Stream.Bitmap

  @width 11
  @height 13

  @bitmap Bitmap
  @mutable :mutable_bitmap

  # --------------------------------------------------------
  test "build :g works" do
    {@mutable, {w, h, :g}, p} = Bitmap.build(:g, @width, @height)
    assert w == @width
    assert h == @height
    assert byte_size(p) == @width * @height
  end

  test "build :ga works" do
    {@mutable, {w, h, :ga}, p} = Bitmap.build(:ga, @width, @height)
    assert w == @width
    assert h == @height
    assert byte_size(p) == @width * @height * 2
  end

  test "build :rgb works" do
    {@mutable, {w, h, :rgb}, p} = Bitmap.build(:rgb, @width, @height)
    assert w == @width
    assert h == @height
    assert byte_size(p) == @width * @height * 3
  end

  test "build :rgba works" do
    {@mutable, {w, h, :rgba}, p} = Bitmap.build(:rgba, @width, @height)
    assert w == @width
    assert h == @height
    assert byte_size(p) == @width * @height * 4
  end

  test "build honors the commit option" do
    {@bitmap, _, _} = Bitmap.build(:rgb, @width, @height, commit: true)
  end

  test "build honors the clear option" do
    color = Color.to_rgb({1, 2, 3})
    t = Bitmap.build(:rgb, @width, @height, clear: color)
    assert Bitmap.get(t, 2, 3) == color
  end

  # --------------------------------------------------------
  test "commit changes a mutable Bitmap to a committed one" do
    mut = Bitmap.build(:g, @width, @height)
    {@mutable, m_meta, m_pixels} = mut

    {@bitmap, c_meta, c_pixels} = Bitmap.commit(mut)
    assert c_meta == m_meta
    assert c_pixels == m_pixels
  end

  # --------------------------------------------------------
  test "mutable copies the pixels into a new mutable bin" do
    tex = Bitmap.build(:g, @width, @height, commit: true)
    {@bitmap, c_meta, c_pixels} = tex

    mut = Bitmap.mutable(tex)
    {@mutable, m_meta, m_pixels} = mut
    assert c_meta == m_meta
    assert c_pixels == m_pixels

    # we can confirm the pixels were copied by mutating the mutable one
    # and checking that the change is not also present in the tex version
    assert Bitmap.get(mut, 2, 2) == {:color_g, 0}

    assert Bitmap.get(tex, 2, 2) == {:color_g, 0}

    mut = Bitmap.put(mut, 2, 2, 5)

    assert Bitmap.get(mut, 2, 2) == {:color_g, 5}
    assert Bitmap.get(tex, 2, 2) == {:color_g, 0}
  end

  # --------------------------------------------------------
  test "get :g works" do
    color = Color.to_g(5)

    tex = Bitmap.build(:g, @width, @height, clear: color, commit: true)
    assert Bitmap.get(tex, 2, 2) == color
    assert Bitmap.get(tex, 2, 3) == color
    assert Bitmap.get(tex, 2, 4) == color

    mut = Bitmap.build(:g, @width, @height, clear: color, commit: false)
    assert Bitmap.get(mut, 2, 2) == color
    assert Bitmap.get(mut, 2, 3) == color
    assert Bitmap.get(mut, 2, 4) == color
  end

  test "get :ga works" do
    color = Color.to_ga({5, 100})

    tex = Bitmap.build(:ga, @width, @height, clear: color, commit: true)
    assert Bitmap.get(tex, 2, 2) == color
    assert Bitmap.get(tex, 2, 3) == color
    assert Bitmap.get(tex, 2, 4) == color

    mut = Bitmap.build(:ga, @width, @height, clear: color, commit: false)
    assert Bitmap.get(mut, 2, 2) == color
    assert Bitmap.get(mut, 2, 3) == color
    assert Bitmap.get(mut, 2, 4) == color
  end

  test "get :rgb works" do
    color = Color.to_rgb({1, 2, 3})

    tex = Bitmap.build(:rgb, @width, @height, clear: color, commit: true)
    assert Bitmap.get(tex, 2, 2) == color
    assert Bitmap.get(tex, 2, 3) == color
    assert Bitmap.get(tex, 2, 4) == color

    mut = Bitmap.build(:rgb, @width, @height, clear: color, commit: false)
    assert Bitmap.get(mut, 2, 2) == color
    assert Bitmap.get(mut, 2, 3) == color
    assert Bitmap.get(mut, 2, 4) == color
  end

  test "get :rgba works" do
    color = Color.to_rgba({1, 2, 3, 100})

    tex = Bitmap.build(:rgba, @width, @height, clear: color, commit: true)
    assert Bitmap.get(tex, 2, 2) == color
    assert Bitmap.get(tex, 2, 3) == color
    assert Bitmap.get(tex, 2, 4) == color

    mut = Bitmap.build(:rgba, @width, @height, clear: color, commit: false)
    assert Bitmap.get(mut, 2, 2) == color
    assert Bitmap.get(mut, 2, 3) == color
    assert Bitmap.get(mut, 2, 4) == color
  end

  # --------------------------------------------------------
  test "put :g works" do
    color = Color.to_g(5)

    mut = Bitmap.build(:g, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_g, 0}
    mut = Bitmap.put(mut, 2, 2, color)
    assert Bitmap.get(mut, 2, 2) == color
  end

  test "put :ga works" do
    color = Color.to_ga({5, 100})

    mut = Bitmap.build(:ga, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_ga, {0, 0}}
    mut = Bitmap.put(mut, 2, 2, color)
    assert Bitmap.get(mut, 2, 2) == color
  end

  test "put :rgb works" do
    color = Color.to_rgb({1, 2, 3})

    mut = Bitmap.build(:rgb, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_rgb, {0, 0, 0}}
    mut = Bitmap.put(mut, 2, 2, color)
    assert Bitmap.get(mut, 2, 2) == color
  end

  test "put :rgba works" do
    color = Color.to_rgba({1, 2, 3, 100})

    mut = Bitmap.build(:rgba, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_rgba, {0, 0, 0, 0}}
    mut = Bitmap.put(mut, 2, 2, color)
    assert Bitmap.get(mut, 2, 2) == color
  end

  # --------------------------------------------------------
  test "put_offset :g works" do
    color = Color.to_g(5)

    mut = Bitmap.build(:g, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_g, 0}
    mut = Bitmap.put_offset(mut, @width * 2 + 2, color)
    assert Bitmap.get(mut, 2, 2) == color
  end

  test "put_offset :ga works" do
    color = Color.to_ga({5, 100})

    mut = Bitmap.build(:ga, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_ga, {0, 0}}
    mut = Bitmap.put_offset(mut, @width * 2 + 2, color)
    assert Bitmap.get(mut, 2, 2) == color
  end

  test "put_offset :rgb works" do
    color = Color.to_rgb({1, 2, 3})

    mut = Bitmap.build(:rgb, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_rgb, {0, 0, 0}}
    mut = Bitmap.put_offset(mut, @width * 2 + 2, color)
    assert Bitmap.get(mut, 2, 2) == color
  end

  test "put_offset :rgba works" do
    color = Color.to_rgba({1, 2, 3, 100})

    mut = Bitmap.build(:rgba, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_rgba, {0, 0, 0, 0}}
    mut = Bitmap.put_offset(mut, @width * 2 + 2, color)
    assert Bitmap.get(mut, 2, 2) == color
  end

  # --------------------------------------------------------
  test "clear :g works" do
    color = Color.to_g(5)

    mut = Bitmap.build(:g, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_g, 0}

    mut = Bitmap.clear(mut, color)
    assert Bitmap.get(mut, 2, 2) == color
    assert Bitmap.get(mut, 2, 3) == color
    assert Bitmap.get(mut, 2, 4) == color
  end

  test "clear :ga works" do
    color = Color.to_ga({5, 100})

    mut = Bitmap.build(:ga, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_ga, {0, 0}}

    mut = Bitmap.put(mut, 2, 2, color)
    assert Bitmap.get(mut, 2, 2) == color
  end

  test "clear :rgb works" do
    color = Color.to_rgb({1, 2, 3})

    mut = Bitmap.build(:rgb, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_rgb, {0, 0, 0}}

    mut = Bitmap.clear(mut, color)
    assert Bitmap.get(mut, 2, 2) == color
    assert Bitmap.get(mut, 2, 3) == color
    assert Bitmap.get(mut, 2, 4) == color
  end

  test "clear :rgba works" do
    color = Color.to_rgba({1, 2, 3, 100})

    mut = Bitmap.build(:rgba, @width, @height)
    assert Bitmap.get(mut, 2, 2) == {:color_rgba, {0, 0, 0, 0}}

    mut = Bitmap.clear(mut, color)
    assert Bitmap.get(mut, 2, 2) == color
    assert Bitmap.get(mut, 2, 3) == color
    assert Bitmap.get(mut, 2, 4) == color
  end
end
