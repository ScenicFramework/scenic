#
#  Created by Boyd Multerer on November 12, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.HashTest do
  use ExUnit.Case, async: true
  doctest Scenic.Cache.File

  alias Scenic.Cache.Hash

  #  import IEx

  @valid_hash_path "test/test_data/valid_hash_file.txt.aqw2vpKePkeDvZzBz-1wFsC2Xac"
  @bad_hash_path "test/test_data/bad_hash_file.txt.not_a_valid_hash"
  @missing_hash_path "test/test_data/missing_hash_file.txt"
  @no_such_file_path "test/test_data/no_such_file.txt.whatever"

  @valid_hash "aqw2vpKePkeDvZzBz-1wFsC2Xac"
  @valid_hash_256 "XmLxE6HaLNGiAE3Xhhs-G4I3PCap-fsK90vJZnQMbFI"
  @missing_hash "TMRA5gAj7BwXxcRfPGq2avbh6nc"
  @missing_hash_256 "6XheyWIkgKP7baORQ3y2TRWVQNptzlOSfuXFiXoZ_Ao"

  #    hash = Cache.File.compute_file_hash( @valid_hash_path )

  # ============================================================================
  # compute hash for binary

  test "binary computes a hash for some binary data" do
    data = "some data. af98hwu4lhrliw4uhtliuhet;giojres;ihg;usdhg"
    expected_hash = :crypto.hash(:sha, data) |> Base.url_encode64(padding: false)
    assert Hash.binary(data, :sha) == {:ok, expected_hash}
  end

  test "binary rejects invalid hash types" do
    data = "some data. af98hwu4lhrliw4uhtliuhet;giojres;ihg;usdhg"
    assert Hash.binary(data, :invalid) == {:error, :invalid_hash_type}
  end

  test "binary! computes a hash for some binary data" do
    data = "some data. af98hwu4lhrliw4uhtliuhet;giojres;ihg;usdhg"
    expected_hash = :crypto.hash(:sha, data) |> Base.url_encode64(padding: false)
    assert Hash.binary!(data, :sha) == expected_hash
  end

  test "binary! raises on an invalid hash type" do
    data = "some data. af98hwu4lhrliw4uhtliuhet;giojres;ihg;usdhg"

    assert_raise Scenic.Cache.Hash.Error, fn ->
      Hash.binary!(data, :invalid)
    end
  end

  # ============================================================================
  # compute_file

  test "file loads a file and computes its hash" do
    assert Hash.file(@missing_hash_path, :sha) == {:ok, @missing_hash}
  end

  test "file loads a file and computes its hash with alternate algorithms" do
    assert Hash.file(@missing_hash_path, :sha256) == {:ok, @missing_hash_256}
  end

  test "file passes through file system errors" do
    assert Hash.file(@no_such_file_path, :sha) == {:error, :enoent}
  end

  # ============================================================================
  # file!

  test "file! loads a file and computes its hash" do
    assert Hash.file!(@missing_hash_path, :sha) == @missing_hash
  end

  test "file! loads a file and computes its hash with alternate algorithms" do
    assert Hash.file!(@missing_hash_path, :sha256) == @missing_hash_256
  end

  test "file! passes through file system errors" do
    assert_raise File.Error, fn -> Hash.file!(@no_such_file_path, :sha) end
  end

  # ============================================================================
  # verify

  test "verify returns {:ok, data} when the hash checks out ok" do
    data = "This is some data to hash - awleiufhoq34htuwehtljwuh5toihu"
    expected = Hash.binary!(data, :sha)
    assert Hash.verify(data, expected, :sha) == {:ok, data}
  end

  test "verify returns {:error, :hash_failure} when the hash fails" do
    data = "This is some data to hash - awleiufhoq34htuwehtljwuh5toihu"
    assert Hash.verify(data, "not_a_hash", :sha) == {:error, :hash_failure}
  end

  # ============================================================================
  # verify!

  test "verify! returns data when the hash checks out ok" do
    data = "This is some data to hash - awleiufhoq34htuwehtljwuh5toihu"
    expected = Hash.binary!(data, :sha)
    assert Hash.verify!(data, expected, :sha) == data
  end

  test "verify! raises on a hash failure" do
    data = "This is some data to hash - awleiufhoq34htuwehtljwuh5toihu"

    assert_raise Hash.Error, fn ->
      Hash.verify!(data, "not_a_hash", :sha)
    end
  end

  # ============================================================================
  # verify_file

  test "verify_file returns {:ok, data} when the hash checks out ok" do
    assert Hash.verify_file(@valid_hash_path) == {:ok, @valid_hash}
    assert Hash.verify_file({@missing_hash_path, @missing_hash}) == {:ok, @missing_hash}

    assert Hash.verify_file({@missing_hash_path, @missing_hash_256, :sha256}) ==
             {:ok, @missing_hash_256}
  end

  test "verify_file returns {:error, :hash_failure} when the hash fails" do
    assert Hash.verify_file(@bad_hash_path) == {:error, :hash_failure}
    assert Hash.verify_file({@missing_hash_path, "not_a_hash"}) == {:error, :hash_failure}

    assert Hash.verify_file({@missing_hash_path, "not_a_hash", :sha256}) ==
             {:error, :hash_failure}
  end

  test "verify_file passes through file system errors" do
    assert Hash.verify_file(@no_such_file_path) == {:error, :enoent}
    assert Hash.verify_file({@no_such_file_path, @valid_hash}) == {:error, :enoent}
    assert Hash.verify_file({@no_such_file_path, @valid_hash_256, :sha256}) == {:error, :enoent}
  end

  # ============================================================================
  # verify_file!

  test "verify_file! returns data when the hash checks out ok" do
    assert Hash.verify_file!(@valid_hash_path) == @valid_hash
    assert Hash.verify_file!({@missing_hash_path, @missing_hash}) == @missing_hash

    assert Hash.verify_file!({@missing_hash_path, @missing_hash_256, :sha256}) ==
             @missing_hash_256
  end

  test "verify_file! raises on a hash failure" do
    assert_raise Hash.Error, fn -> Hash.verify_file!(@bad_hash_path) end
    assert_raise Hash.Error, fn -> Hash.verify_file!({@valid_hash_path, "not_a_hash"}) end
    assert_raise Hash.Error, fn -> Hash.verify_file!({@missing_hash_path, "not_a_hash", :sha}) end
  end

  test "verify_file! passes through file system errors" do
    assert_raise File.Error, fn -> Hash.verify_file!(@no_such_file_path) end
  end

  # ============================================================================
  # path functions

  test "from_path returns just the hash appended to the end of a path" do
    assert Hash.from_path(@valid_hash_path) == @valid_hash
  end

  test "from_path returns the extension - which is obviously not a valid hash" do
    assert Hash.from_path(@missing_hash_path) == "txt"
  end

  # ============================================================================
  # path  param checking

  test "path_params(path) works" do
    assert Hash.path_params(@valid_hash_path) == {@valid_hash_path, @valid_hash, :sha}
  end

  test "path_params(not_a_path) fails" do
    assert_raise FunctionClauseError, fn -> Hash.path_params(:not_a_path) end
  end

  test "path_params(path, hash_type) works" do
    assert Hash.path_params(@valid_hash_path, :sha256) == {@valid_hash_path, @valid_hash, :sha256}

    assert Hash.path_params({@valid_hash_path, :sha256}) ==
             {@valid_hash_path, @valid_hash, :sha256}
  end

  test "path_params(path, hash) works" do
    assert Hash.path_params(@missing_hash_path, @missing_hash) ==
             {@missing_hash_path, @missing_hash, :sha}

    assert Hash.path_params({@missing_hash_path, @missing_hash}) ==
             {@missing_hash_path, @missing_hash, :sha}
  end

  test "path_params(path, something_else) fails" do
    assert_raise FunctionClauseError, fn -> Hash.path_params(@missing_hash_path, 123) end
  end

  test "path_params(path, hash, type) works" do
    assert Hash.path_params(@missing_hash_path, @missing_hash_256, :sha256) ==
             {@missing_hash_path, @missing_hash_256, :sha256}

    assert Hash.path_params({@missing_hash_path, @missing_hash_256, :sha256}) ==
             {@missing_hash_path, @missing_hash_256, :sha256}
  end

  test "path_params(path, hash, type) with bogus params fails" do
    assert_raise FunctionClauseError, fn -> Hash.path_params(123, @missing_hash, :sha256) end
    assert_raise FunctionClauseError, fn -> Hash.path_params({123, @missing_hash, :sha256}) end

    assert_raise FunctionClauseError, fn -> Hash.path_params(@missing_hash_path, 123, :sha256) end

    assert_raise FunctionClauseError, fn ->
      Hash.path_params({@missing_hash_path, 1232, :sha256})
    end

    assert_raise FunctionClauseError, fn ->
      Hash.path_params(@missing_hash_path, @missing_hash, 123)
    end

    assert_raise FunctionClauseError, fn ->
      Hash.path_params({@missing_hash_path, @missing_hash, 123})
    end
  end
end
