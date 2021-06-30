#
#  Created by Boyd Multerer on 2012-04-12
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.StreamTest do
  use ExUnit.Case, async: true
  doctest Scenic.Assets.Stream

  alias Scenic.Assets.Stream

  @stream_put   {Stream, :put}
  @stream_del   {Stream, :delete}

  # --------------------------------------------------------
  setup do
    {:ok, svc} = Stream.start_link(nil)
    on_exit(fn ->
      Process.exit(svc, :normal)
      Process.sleep(4)
    end)
    %{svc: svc}
  end

  #============================================================================
  # basic client API

  test "exists? returns true if key is found" do
    tex = Stream.Texture.from_file(10, 10, "test_data")
    assert Stream.put( "abc", tex ) == :ok
    assert  Stream.exists?("abc") == true
  end
  test "exists? returns false if key is not found" do
    assert  Stream.exists?("missing") == false
  end

  test "exists! returns :ok if key is found" do
    tex = Stream.Texture.from_file(10, 10, "test_data")
    assert Stream.put( "abc", tex ) == :ok
    assert  Stream.exists!("abc") == :ok
  end

  test "exists! raises for invalid content" do
    assert_raise Stream.Error, fn ->
      Stream.exists!( "missing" )
    end
  end

  test "fetch returns error if key is not found" do
    assert Stream.fetch("missing") == {:error, :not_found}
  end

  test "can put, exists?, fetch, put, and delete streams" do
    refute Stream.exists?("abc")
    tex = Stream.Texture.from_file(10, 10, "test_data")
    assert Stream.put( "abc", tex ) == :ok
    assert Stream.exists?("abc")
    assert Stream.fetch("abc") == {:ok, {:texture, {10,10,:file}, "test_data"}}

    tex = Stream.Texture.from_file(11, 11, "updated_data")
    assert Stream.put( "abc", tex ) == :ok
    assert Stream.exists?("abc")
    assert Stream.fetch("abc") == {:ok, {:texture, {11,11,:file}, "updated_data"}}

    assert Stream.subscribe( "abc" ) == :ok
    assert Stream.delete("abc") == :ok
    assert_receive({@stream_del, :texture, "abc"}, 100)
    refute Stream.exists?("abc")
    assert Stream.fetch("abc") == {:error, :not_found}
  end

  test "put rejects invalid raw image data" do
    assert Stream.fetch("abc") == {:error, :not_found}
    assert Stream.put( "abc", {:texture, {5,5,:file}, nil} ) == {:error, :invalid}
    assert Stream.put( "abc", {:texture, {5,5,:g}, "invalid"} ) == {:error, :invalid}
    assert Stream.put( "abc", {:texture, {5,5,:ga}, "invalid"} ) == {:error, :invalid}
    assert Stream.put( "abc", {:texture, {5,5,:rgb}, "invalid"} ) == {:error, :invalid}
    assert Stream.put( "abc", {:texture, {5,5,:rgba}, "invalid"} ) == {:error, :invalid}
    assert Stream.fetch("abc") == {:error, :not_found}
  end

  test "put accepts valid raw image data" do
    refute Stream.exists?("one")
    assert Stream.put( "abc", {:texture, {5,5,:file}, "anything"} ) == :ok
    assert Stream.put( "one", {:texture, {2,2,:g}, "abcd"} ) == :ok
    assert Stream.put( "two", {:texture, {2,2,:ga}, "abcdabcd"} ) == :ok
    assert Stream.put( "three", {:texture, {2,2,:rgb}, "abcdabcdabcd"} ) == :ok
    assert Stream.put( "four", {:texture, {2,2,:rgba}, "abcdabcdabcdabcd"} ) == :ok
    assert Stream.exists?("abc")
    assert Stream.exists?("one")
    assert Stream.exists?("two")
    assert Stream.exists?("three")
    assert Stream.exists?("four")
  end

  test "put validates raw image data" do
    assert Stream.put( "abc", {:texture, {2,2,:g}, "abcd"} ) == :ok
    assert Stream.fetch("abc") == {:ok, {:texture, {2,2,:g}, "abcd"} }

    assert Stream.put( "abc", {:texture, {2,2,:g}, "efgh"} ) == :ok
    assert Stream.fetch("abc") == {:ok, {:texture, {2,2,:g}, "efgh"} }

    assert Stream.put( "abc", {:texture, {2,2,:g}, "invalid"} ) == {:error, :invalid}
    assert Stream.fetch("abc") == {:ok, {:texture, {2,2,:g}, "efgh"}}
  end

  #============================================================================
  # subscription API

  test "Subscribers get messages when an item is updated and deleted" do
    assert Stream.put( "abc", {:texture, {2,2,:g}, "abcd"} ) == :ok
    assert Stream.subscribe( "abc" ) == :ok
    refute_receive(_, 40)

    # prove doing an update creates a message
    assert Stream.put( "abc", {:texture, {2,2,:g}, "efgh"} ) == :ok
    assert_receive({@stream_put, :texture, "abc"}, 100)

    # clean up
    assert Stream.delete("abc") == :ok
    assert_receive({@stream_del, :texture, "abc"}, 100)
  end

  test "Can subscribe before an item is created" do
    assert Stream.subscribe( "abc" ) == :ok
    refute_receive(_, 40)

    assert Stream.put( "abc", {:texture, {2,2,:g}, "abcd"} ) == :ok
    assert_receive({@stream_put, :texture, "abc"}, 100)
  end

  test "unsubscribe stops update messages" do
    assert Stream.put( "abc", {:texture, {2,2,:g}, "abcd"} ) == :ok
    assert Stream.subscribe( "abc" ) == :ok
    assert Stream.put( "abc", {:texture, {2,2,:g}, "efgh"} ) == :ok

    assert_receive({@stream_put, :texture, "abc"}, 100)

    assert Stream.unsubscribe( "abc" ) == :ok
    assert Stream.put( "abc", {:texture, {2,2,:g}, "ijkl"} ) == :ok
    refute_receive(_, 40)
  end

end













