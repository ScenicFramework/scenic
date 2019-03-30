#
#  Created by Boyd Multerer on 2018-08-28.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# putting read and load in separate modules (both in this file)
# because load needs the cache to be set up and read doesn't.

defmodule Scenic.Cache.Support.FileTest do
  use ExUnit.Case, async: true
  doctest Scenic.Cache.Support.File

  alias Scenic.Cache.Support

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
    {:ok, data} = Support.File.read(@sample_path, :insecure)
    "sample_file" <> _ = data
  end

  test "read(path, :insecure) blindly reads a compressed file" do
    {:ok, data} = Support.File.read(@sample_gzip_path, :insecure, decompress: true)
    "sample_file" <> _ = data
  end

  test "read(path, hash) reads raw with a :sha hash by default" do
    {:ok, data} = Support.File.read(@sample_path, @sample_sha)
    "sample_file" <> _ = data
  end

  test "read(path, hash) reads raw with a :sha256 hash" do
    {:ok, data} = Support.File.read(@sample_path, @sample_sha256, hash: :sha256)
    "sample_file" <> _ = data
  end

  test "read(path, hash) reads gzip with a :sha hash by default" do
    {:ok, data} = Support.File.read(@sample_gzip_path, @sample_gzip_sha, decompress: true)
    "sample_file" <> _ = data
  end

  test "read(path, hash) reads gzip with a :sha256 hash" do
    {:ok, data} =
      Support.File.read(
        @sample_gzip_path,
        @sample_gzip_sha256,
        hash: :sha256,
        decompress: true
      )

    "sample_file" <> _ = data
  end

  test "read(path, hash) FAILS with invalid :sha hash" do
    assert Support.File.read(@sample_path, @invalid_sha) == {:error, :hash_failure}
  end

  test "read(path, hash) FAILS with invalid :sha256 hash" do
    assert Support.File.read(@sample_path, @invalid_sha256, hash: :sha256) ==
             {:error, :hash_failure}
  end

  test "read(path, hash) gzip FAILS with invalid :sha hash" do
    assert Support.File.read(@sample_gzip_path, @invalid_sha, decompress: true) ==
             {:error, :hash_failure}
  end

  test "read(path, hash) gzip FAILS with invalid :sha256 hash" do
    assert Support.File.read(
             @sample_gzip_path,
             @invalid_sha256,
             hash: :sha256,
             decompress: true
           ) == {:error, :hash_failure}
  end

  test "read passes through errors" do
    # missing term file
    assert Support.File.read(
             "not/valid/path",
             @invalid_sha256,
             hash: :sha256
           ) == {:error, :enoent}
  end

  test "read handles unzip errors" do
    assert Support.File.read(@sample_path, @sample_sha, decompress: true) ==
             {:error, :decompress}
  end

  # ============================================================================
  # read!

  test "read!(path, :insecure) blindly read!s a raw file" do
    data = Support.File.read!(@sample_path, :insecure)
    "sample_file" <> _ = data
  end

  test "read!(path, :insecure) blindly read!s a compressed file" do
    data = Support.File.read!(@sample_gzip_path, :insecure, decompress: true)
    "sample_file" <> _ = data
  end

  test "read!(path, hash) read!s raw with a :sha hash by default" do
    data = Support.File.read!(@sample_path, @sample_sha)
    "sample_file" <> _ = data
  end

  test "read!(path, hash) read!s raw with a :sha256 hash" do
    data = Support.File.read!(@sample_path, @sample_sha256, hash: :sha256)
    "sample_file" <> _ = data
  end

  test "read!(path, hash) read!s gzip with a :sha hash by default" do
    data = Support.File.read!(@sample_gzip_path, @sample_gzip_sha, decompress: true)
    "sample_file" <> _ = data
  end

  test "read!(path, hash) read!s gzip with a :sha256 hash" do
    data =
      Support.File.read!(
        @sample_gzip_path,
        @sample_gzip_sha256,
        hash: :sha256,
        decompress: true
      )

    "sample_file" <> _ = data
  end

  test "read!(path, hash) FAILS with invalid :sha hash" do
    assert_raise Scenic.Cache.Support.Hash.Error, fn ->
      Support.File.read!(@sample_path, @invalid_sha)
    end
  end

  test "read!(path, hash) FAILS with invalid :sha256 hash" do
    assert_raise Scenic.Cache.Support.Hash.Error, fn ->
      Support.File.read!(@sample_path, @invalid_sha256, hash: :sha256)
    end
  end

  test "read!(path, hash) gzip FAILS with invalid :sha hash" do
    assert_raise Scenic.Cache.Support.Hash.Error, fn ->
      Support.File.read!(@sample_gzip_path, @invalid_sha, decompress: true)
    end
  end

  test "read!(path, hash) gzip FAILS with invalid :sha256 hash" do
    assert_raise Scenic.Cache.Support.Hash.Error, fn ->
      Support.File.read!(
        @sample_gzip_path,
        @invalid_sha256,
        hash: :sha256,
        decompress: true
      )
    end
  end

  test "read! passes through file rrors" do
    assert_raise File.Error, fn ->
      Support.File.read!(
        "not/valid/path",
        @invalid_sha256,
        hash: :sha256
      )
    end
  end

  test "read! passes through unzip errors" do
    assert_raise ErlangError, fn ->
      Support.File.read!(@sample_path, @sample_sha, decompress: true)
    end
  end
end
