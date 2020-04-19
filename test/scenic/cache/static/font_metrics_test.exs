#
#  Created by Boyd Multerer on 2019-03-07.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Static.FontMetricsTest do
  use ExUnit.Case, async: true
  # doctest Scenic.Cache.Static.Static.FontMetrics
  alias Scenic.Cache.Base
  alias Scenic.Cache.Static
  alias Scenic.Cache.Support
  import ExUnit.CaptureLog

  @base_path :code.priv_dir(:scenic)
             |> Path.join("static/font_metrics")

  @roboto_path Path.join(@base_path, "Roboto-Regular.ttf.metrics")
  @roboto_hash Support.Hash.file!(@roboto_path, :sha)

  setup do
    GenServer.call(Static.FontMetrics, :reset)
  end

  # ============================================================================
  # core inherited functions are mapped in

  test "get is mapped in" do
    Base.put(Static.FontMetrics, "hash", :data)
    assert Static.FontMetrics.get("hash") == :data
    assert Static.FontMetrics.get("missing", nil) == nil
  end

  test "get! is mapped in" do
    Base.put(Static.FontMetrics, "hash", :data)
    assert Static.FontMetrics.get!("hash") == :data
    assert_raise Base.Error, fn -> Static.FontMetrics.get!("missing") end
  end

  test "fetch is mapped in" do
    Base.put(Static.FontMetrics, "hash", :data)
    assert Static.FontMetrics.fetch("hash") == {:ok, :data}
    assert Static.FontMetrics.fetch("missing") == {:error, :not_found}
  end

  # test "put is NOT mapped in" do
  #   # static caches only get put_new...
  #   assert_raise UndefinedFunctionError, fn -> Static.FontMetrics.put("hash", :data) end
  # end

  test "put_new is mapped in" do
    assert Static.FontMetrics.put_new("hash", :data) == {:ok, "hash"}
    assert Static.FontMetrics.get("hash") == :data
  end

  test "claim is mapped in" do
    Base.put(Static.FontMetrics, "hash", :data)
    assert Static.FontMetrics.claim("hash", :global) == :ok
    assert Base.claimed?(Static.FontMetrics, "hash", :global)
  end

  test "release is mapped in" do
    Base.put(Static.FontMetrics, "hash", :data)
    assert Base.fetch(Static.FontMetrics, "hash") == {:ok, :data}
    assert Static.FontMetrics.release("hash", delay: 0) == :ok
    Process.sleep(8)
    assert Base.fetch(Static.FontMetrics, "hash") == {:error, :not_found}
  end

  test "status is mapped in" do
    Base.put(Static.FontMetrics, "hash", :data)
    assert Static.FontMetrics.status("hash") == {:ok, self()}
    assert Static.FontMetrics.status("hash", :global) == {:error, :not_claimed}
  end

  test "keys is mapped in" do
    Base.put(Static.FontMetrics, "hash", :data)
    assert Static.FontMetrics.keys() == ["hash"]
    assert Static.FontMetrics.keys(:global) == []
  end

  test "member? is mapped in" do
    Base.put(Static.FontMetrics, "hash", :data)
    assert Static.FontMetrics.member?("hash")
    refute Static.FontMetrics.member?("missing")
  end

  test "claimed? is mapped in" do
    Base.put(Static.FontMetrics, "hash", :data)
    assert Static.FontMetrics.claimed?("hash")
    refute Static.FontMetrics.claimed?("hash", :global)
  end

  test "subscribe is mapped in" do
    Static.FontMetrics.subscribe(:all, :all)
    Base.put(Static.FontMetrics, "hash", "data")
    assert_receive {:"$gen_cast", {Static.FontMetrics, :put, "hash"}}
  end

  test "unsubscribe is mapped in" do
    Static.FontMetrics.subscribe(:all, :all)
    Static.FontMetrics.unsubscribe(:all, :all)
    Base.put(Static.FontMetrics, "hash", "data")
    refute_receive {:"$gen_cast", {Static.FontMetrics, :put, "hash"}}
  end

  # ============================================================================
  # loaders

  test "load works" do
    assert Static.FontMetrics.load(@roboto_path, @roboto_hash) == {:ok, @roboto_hash}
    # twice to exercise already loaded path
    assert Static.FontMetrics.load(@roboto_path, @roboto_hash) == {:ok, @roboto_hash}
  end

  test "load passes through errors" do
    assert capture_log(fn ->
             assert Static.FontMetrics.load("wrong/path", @roboto_hash) ==
                      {:error, :enoent}
           end) =~ "Could not load font metrics at"

    assert capture_log(fn ->
             assert Static.FontMetrics.load(@roboto_path, "bad_hash") ==
                      {:error, :hash_failure}
           end) =~ "Could not load font metrics at"
  end

  # ============================================================================
  # loaders!

  test "load! works" do
    assert Static.FontMetrics.load!(@roboto_path, @roboto_hash) == @roboto_hash
    # twice to exercise already loaded path
    assert Static.FontMetrics.load!(@roboto_path, @roboto_hash) == @roboto_hash
  end

  test "load! raises errors" do
    assert_raise File.Error, fn ->
      Static.FontMetrics.load!("wrong/path", @roboto_hash)
    end

    assert_raise Support.Hash.Error, fn ->
      Static.FontMetrics.load!(@roboto_path, "bad_hash")
    end
  end

  # ============================================================================
  # overridden inherited functions

  test "get( :roboto ) works" do
    %FontMetrics{} = fm = Static.FontMetrics.get(:roboto)
    assert fm.max_box == {-1509, -555, 2352, 2163}
  end

  test "get( :roboto_mono ) works" do
    %FontMetrics{} = fm = Static.FontMetrics.get(:roboto_mono)
    assert fm.max_box == {-1019, -555, 1945, 2163}
  end

  test "get!( :roboto ) works" do
    %FontMetrics{} = fm = Static.FontMetrics.get!(:roboto)
    assert fm.max_box == {-1509, -555, 2352, 2163}
  end

  test "get!( :roboto_mono ) works" do
    %FontMetrics{} = fm = Static.FontMetrics.get!(:roboto_mono)
    assert fm.max_box == {-1019, -555, 1945, 2163}
  end

  test "fetch( :roboto ) works" do
    {:ok, %FontMetrics{} = fm} = Static.FontMetrics.fetch(:roboto)
    assert fm.max_box == {-1509, -555, 2352, 2163}
  end

  test "fetch( :roboto_mono ) works" do
    {:ok, %FontMetrics{} = fm} = Static.FontMetrics.fetch(:roboto_mono)
    assert fm.max_box == {-1019, -555, 1945, 2163}
  end
end
