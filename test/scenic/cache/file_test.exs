#
#  Created by Boyd Multerer on 2018-08-28.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# putting read and load in seperate modules (both in this file)
# becuase load needs the cache to be set up and read doesn't.

defmodule Scenic.Cache.FileReadTest do
  use ExUnit.Case, async: true
  doctest Scenic.Cache.File

  alias Scenic.Cache

  @sample_path "test/artifacts/sample_file"
  @sample_gzip_path "test/artifacts/sample_file_gzip"

  @sample_sha "2PGNXGkoTc4stYncIe-qCdZFuw0"
  @sample_sha256 "d2xdTK8tBpWhJEvP_AspsM5RUl6JzVh4dWMfgAnpVIE"

  @sample_gzip_sha "QSl8wNoP4faYGHW2dKiQGgEqj0Y"
  @sample_gzip_sha256 "gcr-YPuqPx54bvrIT40N7Ly-_l1sXer-62_Q7xnrzoE"

  @invalid_sha "not_a_valid_hash_abcdefghij"
  @invalid_sha256 "not_a_valid_hash_abcdefghijhijklmnopqrstuvw"

  # ============================================================================
  # read

  test "read(path, :insecure) blindly reads a raw file" do
    {:ok, data} = Cache.File.read(@sample_path, :insecure)
    "sample_file" <> _ = data
  end

  test "read(path, :insecure) blindly reads a compressed file" do
    {:ok, data} = Cache.File.read(@sample_gzip_path, :insecure, decompress: true)
    "sample_file" <> _ = data
  end

  test "read(path, hash) reads raw with a :sha hash by default" do
    {:ok, data} = Cache.File.read(@sample_path, @sample_sha)
    "sample_file" <> _ = data
  end

  test "read(path, hash) reads raw with a :sha256 hash" do
    {:ok, data} = Cache.File.read(@sample_path, @sample_sha256, hash: :sha256)
    "sample_file" <> _ = data
  end

  test "read(path, hash) reads gzip with a :sha hash by default" do
    {:ok, data} = Cache.File.read(@sample_gzip_path, @sample_gzip_sha, decompress: true)
    "sample_file" <> _ = data
  end

  test "read(path, hash) reads gzip with a :sha256 hash" do
    {:ok, data} =
      Cache.File.read(
        @sample_gzip_path,
        @sample_gzip_sha256,
        hash: :sha256,
        decompress: true
      )

    "sample_file" <> _ = data
  end

  test "read(path, hash) FAILS with invalid :sha hash" do
    assert Cache.File.read(@sample_path, @invalid_sha) == {:error, :hash_failure}
  end

  test "read(path, hash) FAILS with invalid :sha256 hash" do
    assert Cache.File.read(@sample_path, @invalid_sha256, hash: :sha256) ==
             {:error, :hash_failure}
  end

  test "read(path, hash) gzip FAILS with invalid :sha hash" do
    assert Cache.File.read(@sample_gzip_path, @invalid_sha, decompress: true) ==
             {:error, :hash_failure}
  end

  test "read(path, hash) gzip FAILS with invalid :sha256 hash" do
    assert Cache.File.read(
             @sample_gzip_path,
             @invalid_sha256,
             hash: :sha256,
             decompress: true
           ) == {:error, :hash_failure}
  end

  test "read passes through errors" do
    # missing term file
    assert Cache.File.read(
             "not/valid/path",
             @invalid_sha256,
             hash: :sha256
           ) == {:error, :enoent}
  end


  test "read uses a passed in parser" do
    # missing term file
    assert Cache.File.read(@sample_path, :insecure, parser: fn(_) ->
      :parsed_data
    end) == :parsed_data
  end
end

defmodule Scenic.Cache.FileLoadTest do
  use ExUnit.Case, async: false

  alias Scenic.Cache

  @sample_path "test/artifacts/sample_file"
  @sample_gzip_path "test/artifacts/sample_file_gzip"

  @sample_sha "2PGNXGkoTc4stYncIe-qCdZFuw0"
  @sample_sha256 "d2xdTK8tBpWhJEvP_AspsM5RUl6JzVh4dWMfgAnpVIE"

  @sample_gzip_sha "QSl8wNoP4faYGHW2dKiQGgEqj0Y"
  @sample_gzip_sha256 "gcr-YPuqPx54bvrIT40N7Ly-_l1sXer-62_Q7xnrzoE"

  @invalid_sha "not_a_valid_hash_abcdefghij"
  @invalid_sha256 "not_a_valid_hash_abcdefghijhijklmnopqrstuvw"

  @cache_table :scenic_cache_key_table
  @scope_table :scenic_cache_scope_table

  # --------------------------------------------------------
  setup do
    assert :ets.info(@cache_table) == :undefined
    assert :ets.info(@scope_table) == :undefined
    :ets.new(@cache_table, [:set, :public, :named_table])
    :ets.new(@scope_table, [:bag, :public, :named_table])
    {:ok, data} = Cache.File.read(@sample_path, @sample_sha)

    %{data: data}
  end

  # ============================================================================
  # load

  test "load(path, :insecure) blindly loads a raw file", %{data: data} do
    {:ok, key} = Cache.File.load(@sample_path, :insecure)
    assert Cache.get(key) == data
  end

  test "load(path, :insecure) blindly loads a compressed file", %{data: data} do
    {:ok, key} = Cache.File.load(@sample_gzip_path, :insecure, decompress: true)
    assert Cache.get(key) == data
  end

  test "load(path, hash) loads raw with a :sha hash by default", %{data: data} do
    {:ok, key} = Cache.File.load(@sample_path, @sample_sha)
    assert key == @sample_sha
    assert Cache.get(@sample_sha) == data
  end

  test "load(path, hash) loads raw with a :sha256 hash", %{data: data} do
    {:ok, key} = Cache.File.load(@sample_path, @sample_sha256, hash: :sha256)
    assert key == @sample_sha256
    assert Cache.get(@sample_sha256) == data
  end

  test "load(path, hash) loads gzip with a :sha hash by default", %{data: data} do
    {:ok, key} = Cache.File.load(@sample_gzip_path, @sample_gzip_sha, decompress: true)
    assert key == @sample_gzip_sha
    assert Cache.get(@sample_gzip_sha) == data
  end

  test "load(path, hash) loads gzip with a :sha256 hash" do
    {:ok, key} =
      Cache.File.load(
        @sample_gzip_path,
        @sample_gzip_sha256,
        hash: :sha256,
        decompress: true
      )

    assert key == @sample_gzip_sha256
    "sample_file" <> _ = Cache.get(@sample_gzip_sha256)
  end

  test "load(path, hash) FAILS with invalid :sha hash" do
    assert Cache.File.load(@sample_path, @invalid_sha) == {:error, :hash_failure}
  end

  test "load(path, hash) FAILS with invalid :sha256 hash" do
    assert Cache.File.load(@sample_path, @invalid_sha256, hash: :sha256) ==
             {:error, :hash_failure}
  end

  test "load(path, hash) gzip FAILS with invalid :sha hash" do
    assert Cache.File.load(@sample_gzip_path, @invalid_sha, decompress: true) ==
             {:error, :hash_failure}
  end

  test "load(path, hash) gzip FAILS with invalid :sha256 hash" do
    assert Cache.File.load(
             @sample_gzip_path,
             @invalid_sha256,
             hash: :sha256,
             decompress: true
           ) == {:error, :hash_failure}
  end

  test "load passes through errors" do
    # missing term file
    assert Cache.File.load(
             "not/valid/path",
             @invalid_sha256,
             hash: :sha256
           ) == {:error, :enoent}
  end
end
