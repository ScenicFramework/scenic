#
#  Created by Boyd Multerer on 2017-11-12.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Support.HashTest do
  use ExUnit.Case, async: true
  doctest Scenic.Cache.Support.Hash

  alias Scenic.Cache.Support.Hash

  #  import IEx

  @missing_hash_path "test/test_data/missing_hash_file.txt"
  @no_such_file_path "test/test_data/no_such_file.txt.whatever"

  @valid_hash "aqw2vpKePkeDvZzBz-1wFsC2Xac"
  @valid_hash_256 "XmLxE6HaLNGiAE3Xhhs-G4I3PCap-fsK90vJZnQMbFI"
  @missing_hash "TMRA5gAj7BwXxcRfPGq2avbh6nc"
  @missing_hash_256 "6XheyWIkgKP7baORQ3y2TRWVQNptzlOSfuXFiXoZ_Ao"

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

    assert_raise Hash.Error, fn ->
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
    assert Hash.verify_file(@missing_hash_path, @missing_hash, :sha) == {:ok, @missing_hash}

    assert Hash.verify_file(@missing_hash_path, @missing_hash_256, :sha256) ==
             {:ok, @missing_hash_256}
  end

  test "verify_file returns {:error, :hash_failure} when the hash fails" do
    assert Hash.verify_file(@missing_hash_path, "not_a_hash", :sha) == {:error, :hash_failure}
    assert Hash.verify_file(@missing_hash_path, "not_a_hash", :sha256) == {:error, :hash_failure}
  end

  test "verify_file passes through file system errors" do
    assert Hash.verify_file(@no_such_file_path, @valid_hash, :sha) == {:error, :enoent}
    assert Hash.verify_file(@no_such_file_path, @valid_hash_256, :sha256) == {:error, :enoent}
  end

  # ============================================================================
  # verify_file!

  test "verify_file! returns data when the hash checks out ok" do
    assert Hash.verify_file!(@missing_hash_path, @missing_hash, :sha) == @missing_hash
    assert Hash.verify_file!(@missing_hash_path, @missing_hash_256, :sha256) == @missing_hash_256
  end

  test "verify_file! raises on a hash failure" do
    assert_raise Hash.Error, fn -> Hash.verify_file!(@missing_hash_path, "not_a_hash", :sha) end
  end

  test "verify_file! passes through file system errors" do
    assert_raise File.Error, fn -> Hash.verify_file!(@no_such_file_path, "not_a_hash", :sha) end
  end

end
