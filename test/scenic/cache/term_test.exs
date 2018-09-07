#
#  Created by Boyd Multerer on August 28, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# putting read and load in seperate modules (both in this file)
# becuase load needs the cache to be set up and read doesn't.

defmodule Scenic.Cache.TermReadTest do
  use ExUnit.Case, async: true
  doctest Scenic.Cache.File

  alias Scenic.Cache

  # safe_term is safe in the :erlang.binary_to_term sense. It contains
  # a known atom. The unsafe_term file contains an unknown atom.

  @safe_term {123, :abc, "Test Bin", %{0 => 123}, [1, 2, 3]}

  @safe_term_path "test/artifacts/safe_term"
  @unsafe_term_path "test/artifacts/unsafe_term"

  @safe_term_sha "2TCjAWe7kA7coRhyrcA1wOfaPaI"
  @safe_term_sha256 "rcoyVtTaX17tdmJ4GhPISJpx9YcGjieisQq0meHcVIw"

  @unsafe_term_sha "y3Wg71MAXFuklnz1H6XNEdO8w_E"

  @invalid_sha "not_a_valid_hash_abcdefghij"
  @invalid_sha256 "not_a_valid_hash_abcdefghijhijklmnopqrstuvw"

  @sample_path "test/artifacts/sample_file"
  @sample_sha "2PGNXGkoTc4stYncIe-qCdZFuw0"

  # ============================================================================
  # read

  test "read(path, :insecure) blindly reads a term file" do
    assert Cache.Term.read(@safe_term_path, :insecure) == {:ok, @safe_term}
  end

  test "read(path, hash) reads term with a :sha hash by default" do
    assert Cache.Term.read(@safe_term_path, @safe_term_sha) == {:ok, @safe_term}
  end

  test "read(path, hash) reads raw with a :sha256 hash" do
    assert Cache.Term.read(
             @safe_term_path,
             @safe_term_sha256,
             hash: :sha256
           ) == {:ok, @safe_term}
  end

  test "read(path, hash) FAILS with invalid :sha hash" do
    assert Cache.Term.read(@safe_term_path, @invalid_sha) == {:error, :hash_failure}
  end

  test "read(path, hash) FAILS with invalid :sha256 hash" do
    assert Cache.Term.read(
             @safe_term_path,
             @invalid_sha256,
             hash: :sha256
           ) == {:error, :hash_failure}
  end

  test "read unsafe term fails by default - even with correct hash" do
    assert Cache.Term.read(
             @unsafe_term_path,
             @unsafe_term_sha
           ) == {:error, :invalid_term}
  end

  test "read non-term fails by default - even with correct hash" do
    assert Cache.Term.read(
             @sample_path,
             @sample_sha
           ) == {:error, :invalid_term}
  end
end

defmodule Scenic.Cache.TermLoadTest do
  use ExUnit.Case, async: false

  alias Scenic.Cache

  @safe_term {123, :abc, "Test Bin", %{0 => 123}, [1, 2, 3]}

  @safe_term_path "test/artifacts/safe_term"
  @unsafe_term_path "test/artifacts/unsafe_term"

  @safe_term_sha "2TCjAWe7kA7coRhyrcA1wOfaPaI"
  @safe_term_sha256 "rcoyVtTaX17tdmJ4GhPISJpx9YcGjieisQq0meHcVIw"

  @unsafe_term_sha "y3Wg71MAXFuklnz1H6XNEdO8w_E"

  @invalid_sha "not_a_valid_hash_abcdefghij"
  @invalid_sha256 "not_a_valid_hash_abcdefghijhijklmnopqrstuvw"

  @sample_path "test/artifacts/sample_file"
  @sample_sha "2PGNXGkoTc4stYncIe-qCdZFuw0"

  @cache_table :scenic_cache_key_table
  @scope_table :scenic_cache_scope_table

  # --------------------------------------------------------
  setup do
    assert :ets.info(@cache_table) == :undefined
    assert :ets.info(@scope_table) == :undefined
    :ets.new(@cache_table, [:set, :public, :named_table])
    :ets.new(@scope_table, [:bag, :public, :named_table])
    :ok
  end

  # ============================================================================
  # load

  test "load(path, :insecure) blindly loads a term file" do
    {:ok, key} = Cache.Term.load(@safe_term_path, :insecure)
    assert Cache.get(key) == @safe_term
  end

  test "load(path, hash) loads term with a :sha hash by default" do
    {:ok, key} = Cache.Term.load(@safe_term_path, @safe_term_sha)
    assert key == @safe_term_sha
    assert Cache.get(key) == @safe_term
  end

  test "load(path, hash) loads raw with a :sha256 hash" do
    {:ok, key} = Cache.Term.load(@safe_term_path, @safe_term_sha256, hash: :sha256)
    assert key == @safe_term_sha256
    assert Cache.get(key) == @safe_term
  end

  test "load(path, hash) FAILS with invalid :sha hash" do
    assert Cache.Term.load(@safe_term_path, @invalid_sha) == {:error, :hash_failure}
  end

  test "load(path, hash) FAILS with invalid :sha256 hash" do
    assert Cache.Term.load(
             @safe_term_path,
             @invalid_sha256,
             hash: :sha256
           ) == {:error, :hash_failure}
  end

  test "load unsafe term fails by default - even with correct hash" do
    assert Cache.Term.load(
             @unsafe_term_path,
             @unsafe_term_sha
           ) == {:error, :invalid_term}
  end

  test "load non-term fails by default - even with correct hash" do
    assert Cache.Term.load(
             @sample_path,
             @sample_sha
           ) == {:error, :invalid_term}
  end
end
