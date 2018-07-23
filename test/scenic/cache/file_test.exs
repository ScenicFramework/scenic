#
#  Created by Boyd Multerer on November 12, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# putting read and load in seperate modules (both in this file)
# becuase load needs the cache to be set up and read doesn't.

defmodule Scenic.Cache.FileReadTest do
  use ExUnit.Case, async: true
  doctest Scenic.Cache.File

  alias Scenic.Cache, as: Cache
  alias Scenic.Cache.Hash

#  import IEx

  @valid_hash_path      "test/test_data/valid_hash_file.txt.aqw2vpKePkeDvZzBz-1wFsC2Xac"
  @valid_hash_256_path  "test/test_data/valid_hash_256_file.txt.XmLxE6HaLNGiAE3Xhhs-G4I3PCap-fsK90vJZnQMbFI"
  @bad_hash_path        "test/test_data/bad_hash_file.txt.not_a_valid_hash"
  @missing_hash_path    "test/test_data/missing_hash_file.txt"
  @no_such_file_path    "test/test_data/no_such_file.txt.whatever"

  @valid_hash           "aqw2vpKePkeDvZzBz-1wFsC2Xac"
  @valid_hash_256       "XmLxE6HaLNGiAE3Xhhs-G4I3PCap-fsK90vJZnQMbFI"
  @missing_hash         "TMRA5gAj7BwXxcRfPGq2avbh6nc"
  @missing_hash_256     "6XheyWIkgKP7baORQ3y2TRWVQNptzlOSfuXFiXoZ_Ao"


#  test "get hashes" do
#    IO.write "@missing_hash sha: "
#    Hash.compute_file!(@missing_hash_path, :sha)
#    |> IO.inspect()
#    IO.write "@missing_hash sha256: "
#    Hash.compute_file!(@missing_hash_path, :sha256)
#    |> IO.inspect()
#    pry()
#  end


  #============================================================================
  # read

  #--------------------------------------------------------
  test "read(path) accepts a path with an embedded hash and reads it" do
    {:ok, data} = Cache.File.read( @valid_hash_path )
    # compute the real file hash
    hash = :crypto.hash( :sha, data )
    |> Base.url_encode64( padding: false )
    # double check that the hashes are correct
    assert hash == @valid_hash

    # do it again, passing in the hash type
    {:ok, data2} = Cache.File.read( {@valid_hash_path, :sha} )
    assert data == data2
  end

  test "read(path) rejects a path with an valid file, but invalid hash" do
    assert Cache.File.read( @bad_hash_path ) == {:error, :hash_failure}
  end

  test "read(path) rejects a path with an valid file, but missing hash" do
    assert Cache.File.read( @missing_hash_path ) == {:error, :hash_failure}
  end

  test "read(path) accepts other types of hash computations as an optional parameter" do
    {:ok, data} = Cache.File.read( {@valid_hash_256_path, :sha256} )
    hash = :crypto.hash( :sha256, data )
    |> Base.url_encode64( padding: false )
    assert hash == @valid_hash_256
  end

  test "read(path) passes file system errors through" do
    assert Cache.File.read( @no_such_file_path ) == {:error, :enoent}
  end

  test "read(path) uses the optional initializer" do
    {:ok, data} = Cache.File.read( @valid_hash_path, init: fn(_,_)-> {:ok, :init_data} end )
    assert data == :init_data
  end

  #--------------------------------------------------------
  test "read({path, hash}) accepts a path missing a hash and a valid hash passed in" do
    {:ok, data} = Cache.File.read( {@missing_hash_path, @missing_hash} )
    hash = :crypto.hash( :sha, data )
    |> Base.url_encode64( padding: false )
    assert hash == @missing_hash
  end

  test "read({path, hash}) accepts a path with an embedded hash and the same path passed in" do
    {:ok, data} = Cache.File.read( {@valid_hash_path, @valid_hash} )
    assert is_binary( data )
    {:ok, data} = Cache.File.read( {@valid_hash_path, @valid_hash, :sha} )
    assert is_binary( data )
  end

  test "read({path, hash}) accepts a path with a bad hash and a valid hash passed in" do
    {:ok, data} = Cache.File.read( {@bad_hash_path, @valid_hash} )
    assert is_binary( data )
  end

  test "read({path, hash}) rejects a path missing a hash and an invalid hash passed in" do
    assert Cache.File.read( {@missing_hash_path, "not_a_valid_hash"} ) == {:error, :hash_failure}
  end

  test "read({path, hash}) rejects a path with a valid a hash and an invalid hash passed in" do
    assert Cache.File.read( {@valid_hash_path, "not_a_valid_hash"} ) == {:error, :hash_failure}
  end

  test "read(path, hash) passes file system errors through" do
    assert Cache.File.read( {@no_such_file_path, @valid_hash} ) == {:error, :enoent}
  end

  test "read(path, hash) uses the optional initializer" do
    {:ok, data} = Cache.File.read( {@missing_hash_path, @missing_hash}, init: fn(_,_)-> {:ok, :init_data} end )
    assert data == :init_data
  end

  test "read(path, hash) uses the optional reader" do
    {:ok, data} = Cache.File.read( {@missing_hash_path, @missing_hash}, read: fn(_,_,_)-> {:ok, :read_data} end )
    assert data == :read_data
  end

  test "read({path, hash, type}) accepts other types of hash computations" do
    {:ok, data} = Cache.File.read( {@missing_hash_path, @missing_hash_256, :sha256} )
    hash = :crypto.hash( :sha256, data )
    |> Base.url_encode64( padding: false )
    assert hash == @missing_hash_256
  end

  #--------------------------------------------------------
  test "read(path_list) reads multiple files" do
    {:ok, valid_data}   = File.read( @valid_hash_path )
    {:ok, missing_data} = File.read( @missing_hash_path )
    file_list = [@valid_hash_path, {@missing_hash_path, @missing_hash, :sha}]
    assert Cache.File.read( file_list ) == [{:ok, valid_data}, {:ok, missing_data}]
  end

#  test "read(path_list) handles some hash errors"

  #============================================================================
  # read!

  #--------------------------------------------------------
  test "read!(path) accepts a path with an embedded hash and reads it" do
    data = Cache.File.read!( @valid_hash_path )
    assert is_binary( data )
    data2 = Cache.File.read!( @valid_hash_path, hash: :sha )
    assert data == data2
  end

  test "read!(path) rejects a path with an valid file, but invalid hash" do
    assert_raise Hash.Error, fn ->
      Cache.File.read!( @bad_hash_path )
    end
  end

  test "read!(path) rejects a path with an valid file, but missing hash" do
    assert_raise Hash.Error, fn ->
      Cache.File.read!( @missing_hash_path )
    end
  end

  test "read!(path) accepts other types of hash computations as an optional parameter" do
    data = Cache.File.read!( {@valid_hash_256_path, :sha256} )
    assert is_binary( data )
  end

  test "read!(path) passes file system errors through" do
    assert_raise File.Error, fn ->
      Cache.File.read!( @no_such_file_path )
    end
  end

  test "read!(path) uses the optional initializer" do
    assert Cache.File.read!( @valid_hash_path, init: fn(_,_)-> {:ok, :init_data} end ) == :init_data
  end

  #--------------------------------------------------------
  test "read!(path, hash) accepts a path missing a hash and a valid hash passed in" do
    key = Cache.File.read!( {@missing_hash_path, @missing_hash} )
    assert is_bitstring( key )
  end

  test "read!(path, hash) accepts a path with an embedded hash and the same path passed in" do
    key = Cache.File.read!( {@valid_hash_path, @valid_hash} )
    assert is_bitstring( key )
  end

  test "read!(path, hash) accepts a path with a bad hash and a valid hash passed in" do
    key = Cache.File.read!( {@bad_hash_path, @valid_hash} )
    assert is_bitstring( key )
  end

  test "read!(path, hash) rejects a path missing a hash and an invalid hash passed in" do
    assert_raise Hash.Error, fn ->
      Cache.File.read!( {@missing_hash_path, "not_a_valid_hash"} )
    end
  end

  test "read!(path, hash) rejects a path with a valid a hash and an invalid hash passed in" do
    assert_raise Hash.Error, fn ->
      Cache.File.read!( {@valid_hash_path, "not_a_valid_hash"} )
    end
  end

  test "read!(path, hash) accepts other types of hash computations as an optional parameter" do
    key = Cache.File.read!( {@missing_hash_path, @missing_hash_256, :sha256} )
    assert is_bitstring( key )
  end

  test "read!(path, hash) passes file system errors through" do
    assert_raise File.Error, fn ->
      Cache.File.read!( {@no_such_file_path, @valid_hash} )
    end
  end

  test "read!(path, hash) uses the optional initializer" do
    assert Cache.File.read!( {@missing_hash_path, @missing_hash}, init: fn(_,_)-> {:ok, :init_data} end ) == :init_data
  end


  test "read!(path, hash) uses the optional reader" do
    assert Cache.File.read!( {@missing_hash_path, @missing_hash}, read: fn(_,_,_)-> :read_data end ) == :read_data
  end

  #--------------------------------------------------------
  test "read!(path_list) reads multiple files" do
    {:ok, valid_data}   = File.read( @valid_hash_path )
    {:ok, missing_data} = File.read( @missing_hash_path )
    file_list = [@valid_hash_path, {@missing_hash_path, @missing_hash, :sha}]
    assert Cache.File.read!( file_list ) == [valid_data, missing_data]
  end
end



defmodule Scenic.Cache.FileLoadTest do
  use ExUnit.Case, async: false

  alias Scenic.Cache, as: Cache
  # alias Scenic.Cache.Hash

#  import IEx

  @valid_hash_path      "test/test_data/valid_hash_file.txt.aqw2vpKePkeDvZzBz-1wFsC2Xac"
  @valid_hash_256_path  "test/test_data/valid_hash_256_file.txt.XmLxE6HaLNGiAE3Xhhs-G4I3PCap-fsK90vJZnQMbFI"
  @bad_hash_path        "test/test_data/bad_hash_file.txt.not_a_valid_hash"
  @missing_hash_path    "test/test_data/missing_hash_file.txt"
  @no_such_file_path    "test/test_data/no_such_file.txt.whatever"

  @valid_hash           "aqw2vpKePkeDvZzBz-1wFsC2Xac"
  @missing_hash         "TMRA5gAj7BwXxcRfPGq2avbh6nc"
  @missing_hash_256     "6XheyWIkgKP7baORQ3y2TRWVQNptzlOSfuXFiXoZ_Ao"

  @cache_table        :scenic_cache_key_table
  @scope_table        :scenic_cache_scope_table

  #--------------------------------------------------------
  setup do
    assert :ets.info( @cache_table ) == :undefined
    assert :ets.info( @scope_table ) == :undefined
    :ets.new(@cache_table, [:set, :public, :named_table])
    :ets.new(@scope_table, [:bag, :public, :named_table])
    :ok
  end

  #============================================================================
  # load

  #--------------------------------------------------------
  test "load(path) accepts a path with an embedded hash and reads it" do
    {:ok, key} = Cache.File.load( @valid_hash_path )

    {:ok, data} = File.read( @valid_hash_path )
    assert Cache.get(key) == data
    # do it again, passing in the hash type
    {:ok, _} = Cache.File.load( @valid_hash_path, hash: :sha )
  end

  test "load(path) rejects a path with an valid file, but invalid hash" do
    assert Cache.File.load( @bad_hash_path ) == {:error, :hash_failure}
  end

  test "load(path) rejects a path with an valid file, but missing hash" do
    assert Cache.File.load( @missing_hash_path ) == {:error, :hash_failure}
  end

  test "load(path) accepts other types of hash computations as an optional parameter" do
    {:ok, key} = Cache.File.load( {@valid_hash_256_path, :sha256} )

    {:ok, data} = File.read( @valid_hash_path )
    assert Cache.get(key) == data
  end

  test "load(path) passes file system errors through" do
    assert Cache.File.load( @no_such_file_path ) == {:error, :enoent}
  end

  test "load(path) uses the optional initializer" do
    {:ok, key} = Cache.File.load( @valid_hash_path, init: fn(_,_)-> {:ok, :init_data} end )
    assert Cache.get(key) == :init_data
  end

  #--------------------------------------------------------
  test "load(path, hash) accepts a path missing a hash and a valid hash passed in" do
    {:ok, key} = Cache.File.load( {@missing_hash_path, @missing_hash} )
    {:ok, data} = File.read( @missing_hash_path )
    assert Cache.get(key) == data
  end

  test "load(path, hash) accepts a path with an embedded hash and the same path passed in" do
    {:ok, key} = Cache.File.load( {@valid_hash_path, @valid_hash} )
    {:ok, data} = File.read( @valid_hash_path )
    assert Cache.get(key) == data
  end

  test "load(path, hash) accepts a path with a bad hash and a valid hash passed in" do
    {:ok, key} = Cache.File.load( {@bad_hash_path, @valid_hash })

    {:ok, data} = File.read( @valid_hash_path )
    assert Cache.get(key) == data
  end

  test "load(path, hash) rejects a path missing a hash and an invalid hash passed in" do
    assert Cache.File.load( {@missing_hash_path, "not_a_valid_hash"} ) == {:error, :hash_failure}
  end

  test "load(path, hash) rejects a path with a valid a hash and an invalid hash passed in" do
    assert Cache.File.load( {@valid_hash_path, "not_a_valid_hash"} ) == {:error, :hash_failure}
  end

  test "load(path, hash, type) accepts other types of hash" do
    {:ok, key} = Cache.File.load( {@missing_hash_path, @missing_hash_256, :sha256} )
    {:ok, data} = File.read( @missing_hash_path )
    assert Cache.get(key) == data
  end

  test "load(path, hash) passes file system errors through" do
    assert Cache.File.load( {@no_such_file_path, @valid_hash} ) == {:error, :enoent}
  end

  test "load(path, hash) uses the optional initializer" do
    {:ok, key} = Cache.File.load( {@missing_hash_path, @missing_hash}, init: fn(_,_)-> {:ok, :init_data} end )
    assert Cache.get(key) == :init_data
  end

  #--------------------------------------------------------
  test "load(path_list) loads multiple files into this proc's scope" do
    file_list = [@valid_hash_path, {@missing_hash_path, @missing_hash, :sha}]

    assert Cache.File.load( file_list ) == [{:ok, @valid_hash}, {:ok, @missing_hash}]

    keys = Cache.keys( self() )
    assert Enum.member?(keys, @valid_hash)
    assert Enum.member?(keys, @missing_hash)
  end

  #============================================================================
  # load!

  # #--------------------------------------------------------
  # test "load!(path) accepts a path with an embedded hash and reads it" do
  #   key = Cache.File.load!( @valid_hash_path )

  #   {:ok, data} = File.read( @valid_hash_path )
  #   assert Cache.get(key) == data
  #   # do it again, passing in the hash type
  #   assert Cache.File.load!( @valid_hash_path, hash: :sha ) == key
  # end

  # test "load!(path) rejects a path with an valid file, but invalid hash" do
  #   assert_raise Hash.Error, fn ->
  #     Cache.File.load!( @bad_hash_path )
  #   end
  # end

  # test "load!(path) rejects a path with an valid file, but missing hash" do
  #   assert_raise Hash.Error, fn ->
  #     Cache.File.load!( @missing_hash_path )
  #   end
  # end

  # test "load!(path) accepts other types of hash computations as an optional parameter" do
  #   key = Cache.File.load!( {@valid_hash_256_path, :sha256} )
  #   {:ok, data} = File.read( @valid_hash_path )
  #   assert Cache.get(key) == data
  # end

  # test "load!(path) passes file system errors through" do
  #   assert_raise File.Error, fn ->
  #     Cache.File.load!( @no_such_file_path )
  #   end
  # end

  # test "load!(path) uses the optional initializer" do
  #   key = Cache.File.load!( @valid_hash_path, init: fn(_,_)-> {:ok, :init_data} end )
  #   assert Cache.get(key) == :init_data
  # end

  # #--------------------------------------------------------
  # test "load!(path, hash) accepts a path missing a hash and a valid hash passed in" do
  #   key = Cache.File.load!( {@missing_hash_path, @missing_hash} )
  #   {:ok, data} = File.read( @missing_hash_path )
  #   assert Cache.get(key) == data
  #   # do it again, passing in the hash type
  #   assert Cache.File.load!( {@missing_hash_path, @missing_hash, :sha }) == key
  # end

  # test "load!(path, hash) accepts a path with an embedded hash and the same path passed in" do
  #   key = Cache.File.load!( {@valid_hash_path, @valid_hash} )

  #   {:ok, data} = File.read( @valid_hash_path )
  #   assert Cache.get(key) == data
  # end

  # test "load!(path, hash) accepts a path with a bad hash and a valid hash passed in" do
  #   key = Cache.File.load!( {@bad_hash_path, @valid_hash} )

  #   {:ok, data} = File.read( @valid_hash_path )
  #   assert Cache.get(key) == data
  # end

  # test "load!(path, hash) rejects a path missing a hash and an invalid hash passed in" do
  #   assert_raise Hash.Error, fn ->
  #     Cache.File.load!( {@missing_hash_path, "not_a_valid_hash"} )
  #   end
  # end

  # test "load!(path, hash) rejects a path with a valid a hash and an invalid hash passed in" do
  #   assert_raise Hash.Error, fn ->
  #     Cache.File.load!( {@valid_hash_path, "not_a_valid_hash"} )
  #   end
  # end

  # test "load!(path, hash) accepts other types of hash computations as an optional parameter" do
  #   key = Cache.File.load!( {@missing_hash_path, @missing_hash_256, :sha256} )
  #   {:ok, data} = File.read( @missing_hash_path )
  #   assert Cache.get(key) == data
  # end

  # test "load!(path, hash) passes file system errors through" do
  #   assert_raise File.Error, fn ->
  #     Cache.File.load!( {@no_such_file_path, @valid_hash} )
  #   end
  # end

  # test "load!(path, hash) uses the optional initializer" do
  #   key = Cache.File.load!( {@missing_hash_path, @missing_hash}, init: fn(_,_)-> {:ok, :init_data} end )
  #   assert Cache.get(key) == :init_data
  # end

  # #--------------------------------------------------------
  # test "load!(path_list) loads multiple files into this proc's scope" do
  #   file_list = [@valid_hash_path, {@missing_hash_path, @missing_hash, :sha}]

  #   assert Cache.File.load!( file_list ) == [@valid_hash, @missing_hash]

  #   keys = Cache.keys( self() )
  #   assert Enum.member?(keys, @valid_hash)
  #   assert Enum.member?(keys, @missing_hash)
  # end

end
