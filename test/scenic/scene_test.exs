#
#  re-Created by Boyd Multerer on 11/09/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#
#

defmodule Scenic.SceneTest do
  use ExUnit.Case, async: false
  doctest Scenic
  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitive

#  import IEx

  @driver_registry      :driver_registry
  @viewport_registry    :viewport_registry


  @graph  Graph.build()
  |> Primitive.Rectangle.add_to_graph({{10,11},100,200})

  @graph_2  Graph.build()
  |> Primitive.Triangle.add_to_graph({{10,11},{100,200}, {10,150}})


  #============================================================================
  # child_spec
  # need a custom child_spec because there can easily be multiple scenes running at the same time
  # they are all really Scenic.Scene as the GenServer module, so need to use differnt ids

  test "child_spec uses the scene module and id - no args" do
    assert Scene.child_spec({__MODULE__,:test_scene}) == %{
      id:       :test_scene,
      start:    {Scene, :start_link, [__MODULE__, :test_scene, nil]},
      type:     :worker,
      restart:  :permanent,
      shutdown: 500
    }
  end

  test "child_spec uses the scene module and id - with args" do
    assert Scene.child_spec({__MODULE__,:test_scene, restart: :temporary}) == %{
      id:       :test_scene,
      start:    {Scene, :start_link, [__MODULE__, :test_scene, [restart: :temporary]]},
      type:     :worker,
      restart:  :temporary,
      shutdown: 500
    }
  end

  #============================================================================
  # faux mod callbacks
  def init( opts ) do
    assert opts == [1,2,3]
    {:ok, :init_state}
  end

  def init_graph( :init_state ) do
    {:ok, @graph, :init_graph_state}
  end

  def handle_call( :call_msg, :from, @graph, :faux_state ) do
    {:reply, :handle_call_reply, @graph_2, :handle_call_state}
  end

  def handle_cast( :cast_msg, @graph, :faux_state ) do
    {:noreply, @graph_2, :handle_cast_state}
  end

  def handle_info( :info_msg, @graph, :faux_state ) do
    {:noreply, @graph_2, :handle_info_state}
  end

  @state %{
    scene_module:  __MODULE__,
    scene_state:   :faux_state,
    graph:        @graph
  }

  #============================================================================
  # default handlers

  #--------------------------------------------------------
  # init
  test "init works and lets the module set up it's data" do
    {:ok, state} = Scene.init( {__MODULE__, [1,2,3]} )
    assert state == %{
      scene_module:       __MODULE__,
      scene_state:        :init_graph_state,
      graph:              @graph
    }
  end

  #--------------------------------------------------------
  # handle_call
  test "handle_call just passes up to the module" do
    {:reply, :handle_call_reply, state} = Scene.handle_call( :call_msg, :from, @state )
    assert state == %{
      scene_module:       __MODULE__,
      scene_state:        :handle_call_state,
      graph:              @graph_2
    }
  end

  #--------------------------------------------------------
  # handle_cast
  
  test "handle_cast passes unknown messages up to the module" do
    {:noreply, state} = Scene.handle_cast( :cast_msg, @state )
    assert state == %{
      scene_module:       __MODULE__,
      scene_state:        :handle_cast_state,
      graph:              @graph_2
    }
  end

  #--------------------------------------------------------
  # handle_info
  
  test "handle_info passes unknown messages up to the module" do
    {:noreply, state} = Scene.handle_info( :info_msg, @state )
    assert state == %{
      scene_module:       __MODULE__,
      scene_state:        :handle_info_state,
      graph:              @graph_2
    }
  end

  #============================================================================
  # custom handlers

end