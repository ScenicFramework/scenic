#
#  Created by Boyd Multerer on June 29, 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.SceneRefTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.SceneRef

  @data_name_id   {:named_scene, 123}
#  pid version must be made dynamically
#  ref version must be made dynamically
  @data_mod       {{__MODULE__, 123}, 456}

  #============================================================================
  # build / add

  test "build name works" do
    p = SceneRef.build( :named_scene )
    assert p.module == SceneRef
    assert Primitive.get(p) == :named_scene
  end


  test "build {name, id} works" do
    p = SceneRef.build( @data_name_id )
    assert p.module == SceneRef
    assert Primitive.get(p) == @data_name_id
  end

  test "build mod works" do
    p = SceneRef.build( @data_mod )
    assert p.module == SceneRef
    assert Primitive.get(p) == @data_mod
  end

  test "build pid works" do
    p = SceneRef.build( self() )
    assert p.module == SceneRef
    assert Primitive.get(p) == {self(), nil}
  end

  test "build {pid, ref} works" do
    p = SceneRef.build( {self(), 123} )
    assert p.module == SceneRef
    assert Primitive.get(p) == {self(), 123}
  end

  test "build graph works" do
    graph = {:graph, make_ref(), 123}
    p = SceneRef.build( graph )
    assert p.module == SceneRef
    assert Primitive.get(p) == graph
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert SceneRef.verify( :named_scene ) == {:ok, :named_scene}
    assert SceneRef.verify( @data_name_id ) == {:ok, @data_name_id}
    assert SceneRef.verify( @data_mod ) == {:ok, @data_mod}
    assert SceneRef.verify( {self(), 123} ) == {:ok, {self(), 123}}
    graph = {:graph, make_ref(), 123}
    assert SceneRef.verify( graph ) == {:ok, graph}
  end

  test "verify fails invalid data" do
    assert SceneRef.verify( {123, 456} ) == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert SceneRef.valid_styles() == [:all]
  end

  test "filter_styles passes all the style, whether or not they are standard ones" do
    styles = %{
      fill: :red,
      banana: :yellow
    }
    assert SceneRef.filter_styles( styles ) == styles
  end

  #============================================================================
  # transforms

  test "default pin simply returns {0,0}" do
    assert SceneRef.default_pin({:named, nil}) == {0,0}
    assert SceneRef.default_pin(@data_name_id) == {0,0}
    assert SceneRef.default_pin(@data_mod) == {0,0}
    assert SceneRef.default_pin({self(), 123}) == {0,0}
    graph = {:graph, make_ref(), 123}
    assert SceneRef.default_pin(graph) == {0,0}
  end

end

