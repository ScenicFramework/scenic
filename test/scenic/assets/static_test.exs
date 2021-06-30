#
#  Created by Boyd Multerer on 2012-04-12
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.StaticTest do
  use ExUnit.Case, async: true
  doctest Scenic.Assets.Static

  alias Scenic.Assets.Static

  @roboto_hash <<243, 145, 76, 95, 149, 49, 167, 23, 114, 99, 197, 95,
     239, 40, 165, 67, 253, 202, 42, 117, 16, 198, 39, 218, 236, 72, 219, 150,
     94, 195, 187, 33>>
  @roboto_hash_str "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"

  @parrot_hash <<86, 245, 144, 22, 54, 229, 35, 4, 198, 178, 241,
     177, 243, 174, 173, 240, 194, 6, 217, 204, 214, 200, 135, 60, 111, 46, 151,
     115, 207, 0, 58, 123>>
  @parrot_hash_str "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"


  # test can get metadata for the 
  test "The Asset library was built and configured correctly" do
    assert Scenic.Test.Assets.otp_app() == :scenic
    %{} = lib = Scenic.Test.Assets.library()
    
    {@roboto_hash, @roboto_hash_str, {:font, %FontMetrics{}}} = lib["fonts/roboto.ttf"]
    {@parrot_hash, @parrot_hash_str, {:image, {62, 114, "image/png"}}} = lib["images/parrot.png"]
    refute lib["missing.png"]
  end

  test "resolve_alias resolves into strings" do
    assert Static.resolve_alias(:test_roboto) == {:ok, "fonts/roboto.ttf"}
  end

  test "resolve_alias passes valid strings through" do
    assert Static.resolve_alias("fonts/roboto.ttf") == {:ok, "fonts/roboto.ttf"}
  end

  test "resolve_alias returns error if not mapped" do
    assert Static.resolve_alias(:missing) == {:error, :not_mapped}
  end

  test "to_hash resolves the file path/alias to the hash" do
    assert Static.to_hash("fonts/roboto.ttf") == {:ok, @roboto_hash, @roboto_hash_str}
    assert Static.to_hash(:test_roboto) == {:ok, @roboto_hash, @roboto_hash_str}

    assert Static.to_hash("images/parrot.png") == {:ok, @parrot_hash, @parrot_hash_str}
    assert Static.to_hash(:test_parrot) == {:ok, @parrot_hash, @parrot_hash_str}
  end

  test "fetch returns the metadata" do
    {:ok, {:font, %FontMetrics{}}} = Static.fetch("fonts/roboto.ttf")
    {:ok, {:font, %FontMetrics{}}} = Static.fetch(:test_roboto)

    {:ok, {:image, {62, 114, "image/png"}}} = Static.fetch("images/parrot.png")
    {:ok, {:image, {62, 114, "image/png"}}} = Static.fetch(:test_parrot)

    assert Static.fetch("images/missing") == :error
    assert Static.fetch(:missing) == :error
  end

  test "load returns the contents of the file" do
    {:ok, bin} = Static.load("fonts/roboto.ttf")
    assert is_binary(bin)
    {:ok, bin} = Static.load(:test_roboto)
    assert is_binary(bin)

    {:ok, bin} = Static.load("images/parrot.png")
    assert is_binary(bin)
    {:ok, bin} = Static.load(:test_parrot)
    assert is_binary(bin)
  end

  test "find_hash does a reverse find and returns the file name" do
    assert Static.find_hash(@roboto_hash, :bin_hash) == {:ok, "fonts/roboto.ttf"}
    assert Static.find_hash(@roboto_hash_str, :str_hash) == {:ok, "fonts/roboto.ttf"}
  end

  test "find_hash returns :not_found if it can't be found..." do
    assert Static.find_hash("missing", :bin_hash) == {:error, :not_found}
    assert Static.find_hash("missing", :str_hash) == {:error, :not_found}
  end

end
