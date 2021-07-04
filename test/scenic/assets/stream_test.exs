#
#  Created by Boyd Multerer on 2012-04-12
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.StreamTest do
  use ExUnit.Case, async: true
  doctest Scenic.Assets.Stream

  alias Scenic.Assets.Stream
  alias Scenic.Assets.Stream.Bitmap
  alias Scenic.Assets.Stream.Image

  @stream_put {Stream, :put}
  @stream_del {Stream, :delete}

  # --------------------------------------------------------
  setup do
    {:ok, svc} = Stream.start_link(nil)

    on_exit(fn ->
      Process.exit(svc, :normal)
      Process.sleep(4)
    end)

    %{svc: svc}
  end

  # ============================================================================
  # basic client API

  test "exists? returns true if key is found" do
    {:ok, bin} = Scenic.Assets.Static.load("images/parrot.png")
    {:ok, img} = Image.from_binary(bin)
    {Image, _, _} = img

    assert Stream.put("abc", img) == :ok
    assert Stream.exists?("abc") == true
  end

  test "exists? returns false if key is not found" do
    assert Stream.exists?("missing") == false
  end

  test "exists! returns :ok if key is found" do
    {:ok, bin} = Scenic.Assets.Static.load("images/parrot.png")
    {:ok, img} = Image.from_binary(bin)
    {Image, _, _} = img

    assert Stream.put("abc", img) == :ok
    assert Stream.exists!("abc") == :ok
  end

  test "exists! raises for invalid content" do
    assert_raise Stream.Error, fn ->
      Stream.exists!("missing")
    end
  end

  test "fetch returns error if key is not found" do
    assert Stream.fetch("missing") == {:error, :not_found}
  end

  test "can put, exists?, fetch, put, and delete images" do
    {:ok, bin} = Scenic.Assets.Static.load("images/parrot.png")
    {:ok, img} = Image.from_binary(bin)
    {Image, {_w, _h, m}, bin} = img

    refute Stream.exists?("abc")
    assert Stream.put("abc", img) == :ok
    assert Stream.exists?("abc")
    assert Stream.fetch("abc") == {:ok, img}

    assert Stream.put("abc", {Image, {11, 11, m}, bin}) == :ok
    assert Stream.exists?("abc")
    assert Stream.fetch("abc") == {:ok, {Image, {11, 11, m}, bin}}

    assert Stream.subscribe("abc") == :ok
    assert Stream.delete("abc") == :ok
    assert_receive({@stream_del, Image, "abc"}, 100)
    refute Stream.exists?("abc")
    assert Stream.fetch("abc") == {:error, :not_found}
  end

  test "can put, exists?, fetch, put, and delete bitmaps" do
    red = Bitmap.build(:rgb, 7, 11, clear: :red, commit: true)
    refute Stream.exists?("abc")
    assert Stream.put("abc", red) == :ok
    assert Stream.exists?("abc")
    assert Stream.fetch("abc") == {:ok, red}

    green = Bitmap.build(:rgb, 7, 11, clear: :green, commit: true)
    assert Stream.put("abc", green) == :ok
    assert Stream.exists?("abc")
    assert Stream.fetch("abc") == {:ok, green}

    assert Stream.subscribe("abc") == :ok
    assert Stream.delete("abc") == :ok
    assert_receive({@stream_del, Bitmap, "abc"}, 100)
    refute Stream.exists?("abc")
    assert Stream.fetch("abc") == {:error, :not_found}
  end

  test "once is created of a certain type, the type cannot be changed" do
    {:ok, bin} = Scenic.Assets.Static.load("images/parrot.png")
    {:ok, img} = Image.from_binary(bin)
    {Image, _, _} = img

    bmp = Bitmap.build(:rgb, 7, 11, clear: :red, commit: true)

    refute Stream.exists?("abc")
    assert Stream.put("abc", img) == :ok
    assert Stream.put("abc", bmp) == {:error, :invalid, Image}

    refute Stream.exists?("def")
    assert Stream.put("def", bmp) == :ok
    assert Stream.put("def", img) == {:error, :invalid, Bitmap}
  end

  test "put rejects invalid images" do
    assert Stream.put("abc", {Image, {2, 3, :invalid}, <<0>>}) == {:error, :invalid, Image}
  end

  test "put validates bitmaps" do
    assert Stream.put("abc", {Bitmap, {2, 3, :rgba}, <<0>>}) == {:error, :invalid, Bitmap}
  end

  # ============================================================================
  # subscription API

  test "Subscribers get messages when an item is updated and deleted" do
    assert Stream.put("abc", {Bitmap, {2, 2, :g}, "abcd"}) == :ok
    assert Stream.subscribe("abc") == :ok
    refute_receive(_, 40)

    # prove doing an update creates a message
    assert Stream.put("abc", {Bitmap, {2, 2, :g}, "efgh"}) == :ok
    assert_receive({@stream_put, Bitmap, "abc"}, 100)

    # clean up
    assert Stream.delete("abc") == :ok
    assert_receive({@stream_del, Bitmap, "abc"}, 100)
  end

  test "Can subscribe before an item is created" do
    assert Stream.subscribe("abc") == :ok
    refute_receive(_, 40)

    assert Stream.put("abc", {Bitmap, {2, 2, :g}, "abcd"}) == :ok
    assert_receive({@stream_put, Bitmap, "abc"}, 100)
  end

  test "unsubscribe stops update messages" do
    assert Stream.put("abc", {Bitmap, {2, 2, :g}, "abcd"}) == :ok
    assert Stream.subscribe("abc") == :ok
    assert Stream.put("abc", {Bitmap, {2, 2, :g}, "efgh"}) == :ok

    assert_receive({@stream_put, Bitmap, "abc"}, 100)

    assert Stream.unsubscribe("abc") == :ok
    assert Stream.put("abc", {Bitmap, {2, 2, :g}, "ijkl"}) == :ok
    refute_receive(_, 40)
  end
end
