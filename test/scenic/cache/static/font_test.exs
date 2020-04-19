#
#  Created by Boyd Multerer on 2019-03-07.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Static.FontTest do
  use ExUnit.Case, async: true
  # doctest Scenic.Cache.Static.Font
  alias Scenic.Cache.Base
  alias Scenic.Cache.Static.Font
  alias Scenic.Cache.Support
  import ExUnit.CaptureLog

  @folder File.cwd!()
          |> Path.join("test/artifacts")
          |> Path.expand()
  @hash Path.join(
          @folder,
          "sub_folder/file.gcr-YPuqPx54bvrIT40N7Ly-_l1sXer-62_Q7xnrzoE"
        )
        |> Support.Hash.file!(:sha256)

  setup do
    GenServer.call(Font, :reset)
  end

  # ============================================================================
  # core inherited functions are mapped in

  test "get is mapped in" do
    Base.put(Font, "hash", :data)
    assert Font.get("hash") == :data
    assert Font.get("missing") == nil
    assert Font.get("missing", :default) == :default
  end

  test "get! is mapped in" do
    Base.put(Font, "hash", :data)
    assert Font.get!("hash") == :data
    assert_raise Base.Error, fn -> Font.get!("missing") end
  end

  test "fetch is mapped in" do
    Base.put(Font, "hash", :data)
    assert Font.fetch("hash") == {:ok, :data}
    assert Font.fetch("missing") == {:error, :not_found}
  end

  # test "put is NOT mapped in" do
  #   # static caches only get put_new...
  #   assert_raise UndefinedFunctionError, fn -> Font.put("hash", :data) end
  # end

  test "put_new is mapped in" do
    assert Font.put_new("hash", :data) == {:ok, "hash"}
    assert Font.get("hash") == :data
  end

  test "claim is mapped in" do
    Base.put(Font, "hash", :data)
    assert Font.claim("hash", :global) == :ok
    assert Base.claimed?(Font, "hash", :global)
  end

  test "release is mapped in" do
    Base.put(Font, "hash", :data)
    assert Base.fetch(Font, "hash") == {:ok, :data}
    assert Font.release("hash", delay: 0) == :ok
    Process.sleep(8)
    assert Base.fetch(Font, "hash") == {:error, :not_found}
  end

  test "status is mapped in" do
    Base.put(Font, "hash", :data)
    assert Font.status("hash") == {:ok, self()}
    assert Font.status("hash", :global) == {:error, :not_claimed}
  end

  test "keys is mapped in" do
    Base.put(Font, "hash", :data)
    assert Font.keys() == ["hash"]
    assert Font.keys(:global) == []
  end

  test "member? is mapped in" do
    Base.put(Font, "hash", :data)
    assert Font.member?("hash")
    refute Font.member?("missing")
  end

  test "claimed? is mapped in" do
    Base.put(Font, "hash", :data)
    assert Font.claimed?("hash")
    refute Font.claimed?("hash", :global)
  end

  test "subscribe is mapped in" do
    Font.subscribe(:all, :all)
    Base.put(Font, "hash", "data")
    assert_receive {:"$gen_cast", {Font, :put, "hash"}}
  end

  test "unsubscribe is mapped in" do
    Font.subscribe(:all, :all)
    Font.unsubscribe(:all, :all)
    Base.put(Font, "hash", "data")
    refute_receive {:"$gen_cast", {Font, :put, "hash"}}
  end

  # ============================================================================
  # loaders

  test "load font works from the given directory" do
    assert Font.load(@folder, @hash) == {:ok, @hash}
    assert Font.load(@folder, {:true_type, @hash}) == {:ok, @hash}
  end

  test "load passes through errors" do
    assert capture_log(fn ->
             assert Font.load("wrong/path", @hash) ==
                      {:error, :not_found}
           end) =~ "Could not load font at"

    assert capture_log(fn ->
             assert Font.load(@folder, "bad_hash") ==
                      {:error, :hash_failure}
           end) =~ "Could not load font at"
  end

  # ============================================================================
  # loaders!

  test "load! font works" do
    assert Font.load!(@folder, @hash) == @hash
    assert Font.load!(@folder, {:true_type, @hash}) == @hash
  end

  test "load! raises errors" do
    assert_raise Scenic.Cache.Static.Font.Error, fn ->
      Font.load!("wrong/path", @hash, [])
    end

    assert_raise Support.Hash.Error, fn ->
      Font.load!(@folder, "bad_hash", [])
    end
  end
end
