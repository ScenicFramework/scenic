#
#  Created by Boyd Multerer on 2019-03-07.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Static.TextureTest do
  use ExUnit.Case, async: true
  # doctest Scenic.Cache.Static.Texture
  alias Scenic.Cache.Base
  alias Scenic.Cache.Support
  alias Scenic.Cache.Static.Texture

  @parrot_path "test/artifacts/scenic_parrot.png"
  @parrot_hash Support.Hash.file!(@parrot_path, :sha)

  setup do
    GenServer.call(Texture, :reset)
  end

  # ============================================================================
  # core inherited functions are mapped in

  test "get is mapped in" do
    Base.put(Texture, "hash", :data)
    assert Texture.get("hash") == :data
    assert Texture.get("missing") == nil
    assert Texture.get("missing", :default) == :default
  end

  test "get! is mapped in" do
    Base.put(Texture, "hash", :data)
    assert Texture.get!("hash") == :data
    assert_raise Base.Error, fn -> Texture.get!("missing") end
  end

  test "fetch is mapped in" do
    Base.put(Texture, "hash", :data)
    assert Texture.fetch("hash") == {:ok, :data}
    assert Texture.fetch("missing") == {:error, :not_found}
  end

  # test "put is NOT mapped in" do
  #   # static caches only get put_new...
  #   assert_raise UndefinedFunctionError, fn -> Texture.put("hash", :data) end
  # end

  test "put_new is mapped in" do
    assert Texture.put_new("hash", :data) == {:ok, "hash"}
    assert Texture.get("hash") == :data
  end

  test "claim is mapped in" do
    Base.put(Texture, "hash", :data)
    assert Texture.claim("hash", :global) == :ok
    assert Base.claimed?(Texture, "hash", :global)
  end

  test "release is mapped in" do
    Base.put(Texture, "hash", :data)
    assert Base.fetch(Texture, "hash") == {:ok, :data}
    assert Texture.release("hash", delay: 0) == :ok
    Process.sleep(8)
    assert Base.fetch(Texture, "hash") == {:error, :not_found}
  end

  test "status is mapped in" do
    Base.put(Texture, "hash", :data)
    assert Texture.status("hash") == {:ok, self()}
    assert Texture.status("hash", :global) == {:error, :not_claimed}
  end

  test "keys is mapped in" do
    Base.put(Texture, "hash", :data)
    assert Texture.keys() == ["hash"]
    assert Texture.keys(:global) == []
  end

  test "member? is mapped in" do
    Base.put(Texture, "hash", :data)
    assert Texture.member?("hash")
    refute Texture.member?("missing")
  end

  test "claimed? is mapped in" do
    Base.put(Texture, "hash", :data)
    assert Texture.claimed?("hash")
    refute Texture.claimed?("hash", :global)
  end

  test "subscribe is mapped in" do
    Texture.subscribe(:all, :all)
    Base.put(Texture, "hash", "data")
    assert_receive {:"$gen_cast", {Texture, :put, "hash"}}
  end

  test "unsubscribe is mapped in" do
    Texture.subscribe(:all, :all)
    Texture.unsubscribe(:all, :all)
    Base.put(Texture, "hash", "data")
    refute_receive {:"$gen_cast", {Texture, :put, "hash"}}
  end

  # ============================================================================
  # loaders

  test "load static texture works" do
    assert Texture.load(@parrot_path, @parrot_hash) == {:ok, @parrot_hash}
    # twice to exercise the already-loaded path
    assert Texture.load(@parrot_path, @parrot_hash) == {:ok, @parrot_hash}
  end

  test "load passes through errors" do
    assert Texture.load("wrong/path", @parrot_hash, []) ==
             {:error, :enoent}

    assert Texture.load(@parrot_path, "bad_hash", []) ==
             {:error, :hash_failure}
  end

  # ============================================================================
  # loaders!

  test "load! static texture works" do
    assert Texture.load!(@parrot_path, @parrot_hash) == @parrot_hash
    # twice to exercise the already-loaded path
    assert Texture.load!(@parrot_path, @parrot_hash) == @parrot_hash
  end

  test "load! raises errors" do
    assert_raise File.Error, fn ->
      Texture.load!("wrong/path", @parrot_hash, [])
    end

    assert_raise Support.Hash.Error, fn ->
      Texture.load!(@parrot_path, "bad_hash", [])
    end
  end
end
