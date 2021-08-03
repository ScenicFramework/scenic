#
#  Created by Boyd Multerer on 2012-04-12
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.StaticTest do
  use ExUnit.Case, async: true
  doctest Scenic.Assets.Static

  alias Scenic.Assets.Static

  # import IEx

  test "module returns the configured library module" do
    assert Static.module() == Scenic.Test.Assets
  end

  test "library returns the configured module's library" do
    assert Static.library() == Scenic.Test.Assets.library()
  end

  test "to_hash retrieves aliased hashes from the library" do
    lib = Static.library()

    assert Static.to_hash(lib, :parrot) == {:ok, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"}

    assert Static.to_hash(lib, {:test_assets, "images/parrot.png"}) ==
             {:ok, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"}

    assert Static.to_hash(lib, :roboto) == {:ok, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"}

    assert Static.to_hash(lib, "fonts/roboto.ttf") ==
             {:ok, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"}

    assert Static.to_hash(lib, {:scenic, "fonts/roboto.ttf"}) ==
             {:ok, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"}

    assert Static.to_hash(lib, :roboto_mono) ==
             {:ok, "seffyKC7EpKVq50qdgz9W7Kk1oj4SPnnSIr66hYTPPA"}

    assert Static.to_hash(lib, {:scenic, "fonts/roboto_mono.ttf"}) ==
             {:ok, "seffyKC7EpKVq50qdgz9W7Kk1oj4SPnnSIr66hYTPPA"}
  end

  test "to_hash passes valid hashes through untouched" do
    lib = Static.library()

    assert Static.to_hash(lib, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns") ==
             {:ok, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"}

    assert Static.to_hash(lib, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE") ==
             {:ok, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"}

    assert Static.to_hash(lib, "seffyKC7EpKVq50qdgz9W7Kk1oj4SPnnSIr66hYTPPA") ==
             {:ok, "seffyKC7EpKVq50qdgz9W7Kk1oj4SPnnSIr66hYTPPA"}
  end

  test "to_hash returns :error for missing errors - just like Map.fetch" do
    lib = Static.library()
    assert Static.to_hash(lib, :missing) == :error
  end

  test "to_hash with lib shortcut works" do
    assert Static.to_hash(:parrot) == {:ok, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"}

    assert Static.to_hash("fonts/roboto.ttf") ==
             {:ok, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"}

    assert Static.to_hash({:scenic, "fonts/roboto_mono.ttf"}) ==
             {:ok, "seffyKC7EpKVq50qdgz9W7Kk1oj4SPnnSIr66hYTPPA"}

    assert Static.to_hash("VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns") ==
             {:ok, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"}

    assert Static.to_hash(:missing) == :error
  end

  test "meta retrieves meta data for an asset" do
    lib = Static.library()

    assert Static.meta(lib, :parrot) ==
             {:ok, {Scenic.Assets.Static.Image, {62, 114, "image/png"}}}

    assert Static.meta(lib, {:test_assets, "images/parrot.png"}) ==
             {:ok, {Scenic.Assets.Static.Image, {62, 114, "image/png"}}}

    assert Static.meta(lib, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns") ==
             {:ok, {Scenic.Assets.Static.Image, {62, 114, "image/png"}}}
  end

  test "meta returns :error for missing errors - just like Map.fetch" do
    lib = Static.library()
    assert Static.meta(lib, :missing) == :error
  end

  test "meta with lib shortcut works" do
    assert Static.meta(:parrot) == {:ok, {Scenic.Assets.Static.Image, {62, 114, "image/png"}}}

    assert Static.meta({:test_assets, "images/parrot.png"}) ==
             {:ok, {Scenic.Assets.Static.Image, {62, 114, "image/png"}}}
  end

  test "load retrieves the binary data for an asset" do
    lib = Static.library()

    {:ok, bin} = Static.load(lib, :parrot)
    assert is_binary(bin)

    {:ok, bin} = Static.load(lib, {:test_assets, "images/parrot.png"})
    assert is_binary(bin)

    {:ok, bin} = Static.load(lib, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns")
    assert is_binary(bin)
  end

  test "load returns :not_found for missing assets" do
    lib = Static.library()

    assert Static.load(lib, :missing) == {:error, :not_found}
  end

  test "load returns :hash_failed when hash_check fails" do
    lib = Static.library()

    # tamper with the file
    {:ok, hash} = Static.to_hash(lib, {:test_assets, "images/tamper.png"})

    path =
      lib.otp_app
      |> :code.lib_dir()
      |> Path.join(Static.dst_dir())
      |> Path.join(hash)

    {:ok, <<t::64, bin::binary>>} = File.read(path)
    File.write!(path, <<t + 1::64, bin::binary>>)

    # it should fail this time
    assert Static.load(lib, {:test_assets, "images/tamper.png"}) == {:error, :hash_failed}
  end

  test "load with lib shortcut works" do
    {:ok, bin} = Static.load(:parrot)
    assert is_binary(bin)

    {:ok, bin} = Static.load({:test_assets, "images/parrot.png"})
    assert is_binary(bin)
  end
end
