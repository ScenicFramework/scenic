#
#  re-Created by Boyd Multerer on 11/09/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#
#

defmodule Scenic.SceneTest do
  use ExUnit.Case, async: false
  doctest Scenic
  alias Scenic.ViewPort
  alias Scenic.Scene
  alias Scenic.Animation
  alias Scenic.Graph
  alias Scenic.Primitive

#  import IEx

  @driver_registry      :driver_registry
  @viewport_registry    :viewport_registry


  @graph  Graph.build()
  |> Primitive.Rectangle.add_to_graph({{10,11},100,200}, id: :rect)
  |> Animation.Basic.Rotate.add_to_graph( {:rect, 0, 0.0002} )

  @graph_2  Graph.build()
  |> Primitive.Triangle.add_to_graph({{20, 300}, {400, 300}, {400, 0}})


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

  def handle_call( :lose_focus, :from_ok, @graph, :faux_state ) do
    {:reply, :ok, @graph_2, :handle_call_lose_focus_ok_state}
  end

  def handle_call( :lose_focus, :from_cancel, @graph, :faux_state ) do
    {:reply, :cancel, @graph_2, :handle_call_lose_focus_cancel_state}
  end

  def handle_cast( :cast_msg, @graph, :faux_state ) do
    {:noreply, @graph_2, :handle_cast_state}
  end

  def handle_info( :info_msg, @graph, :faux_state ) do
    {:noreply, @graph_2, :handle_info_state}
  end

  #--------------------------------------------------------
  def handle_input( {:key, :right, :press, 0}, @graph, :faux_state ) do
    {:noreply, @graph_2, :key_input_state }
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

  #--------------------------------------------------------
  # handle_call({:find_by_screen_pos, pos}...

  test "handle_call :find_by_screen_pos returns the uid of the object under the point" do
    assert Scene.handle_call({:find_by_screen_pos, {20,20}}, :from, @state) ==
      {:reply, 1, @state}
  end

  test "handle_call :find_by_screen_pos returns nil if no object is under the point" do
    assert Scene.handle_call({:find_by_screen_pos, {0,0}}, :from, @state) ==
      {:reply, nil, @state}
  end


  #--------------------------------------------------------
  # handle_call(:lose_focus...
  def focus_lost( @graph, :ok_state) do
    {:ok, @graph_2, :focus_lost_ok_state}
  end

  def focus_lost( @graph, :cancel_state) do
    {:cancel, @graph_2, :focus_lost_cancel_state}
  end

  test "handle_call :lose_focus unregisters the scene and returns :ok" do
    # set up as the current scene
    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )
    assert ViewPort.current_scene?()

    state = Map.put(@state, :scene_state, :ok_state)
    {:reply, :ok, state} = Scene.handle_call(:lose_focus, :from, state)

    %{
      scene_module:       __MODULE__,
      scene_state:        :focus_lost_ok_state,
      graph:              updated_graph
    } = state
    updated_graph = Map.put(updated_graph, :last_recurring_action, nil)
    assert updated_graph == @graph_2
    refute ViewPort.current_scene?()
  end

  test "handle_call :lose_focus cancels and keeps registration" do
    # set up as the current scene
    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )
    assert ViewPort.current_scene?()

    state = Map.put(@state, :scene_state, :cancel_state)
    {:reply, :cancel, state} = Scene.handle_call(:lose_focus, :from, state)

    %{
      scene_module:       __MODULE__,
      scene_state:        :focus_lost_cancel_state,
      graph:              updated_graph
    } = state
    updated_graph = Map.put(updated_graph, :last_recurring_action, nil)
    assert updated_graph == @graph_2
    assert ViewPort.current_scene?()
  end

  #--------------------------------------------------------
  # handle_cast(:input...

  test "handle_cast :input prepares and handles the event" do
    event = {:input, {:key, {262, 1, 0}}}
    {:noreply, state} = Scene.handle_cast(event, @state)
    assert state == %{
      scene_module:       __MODULE__,
      scene_state:        :key_input_state,
      graph:              @graph_2
    }
  end

  #--------------------------------------------------------
  # handle_cast(:input_uid...

  test "handle_cast :input_uid handles the event" do
    event = {:input_uid, {:key, :right, :press, 0}, nil}
    {:noreply, state} = Scene.handle_cast(event, @state)
    assert state == %{
      scene_module:       __MODULE__,
      scene_state:        :key_input_state,
      graph:              @graph_2
    }
  end

  #--------------------------------------------------------
  # handle_cast(:set_scene...
  def focus_gained( @graph, :ok_state) do
    {:ok, @graph_2, :focus_gained_ok_state}
  end

  def focus_gained( @graph, :cancel_state) do
    {:cancel, @graph_2, :focus_gained_cancel_state}
  end

  test "handle_cast :set_scene sets the new scene" do
    state = Map.put(@state, :scene_state, :ok_state)
    {:noreply, state} = Scene.handle_cast(:set_scene, state)
    %{
      scene_module:       __MODULE__,
      scene_state:        :focus_gained_ok_state,
      graph:              updated_graph
    } = state
    updated_graph = Map.put(updated_graph, :last_recurring_action, nil)
    assert updated_graph == @graph_2
    assert ViewPort.current_scene?( self() )
  end

#  test "handle_cast :set_scene unregisters the previous scene" do
#    # spin up a simple agent, just to have a not-self process to use
#    {:ok, pid} = Agent.start_link(fn -> 1 + 1 end, name: __MODULE__)
#
#    # set the agent process as the current scene
#    {:ok, _} = Registry.register(@viewport_registry, :messages, pid )
#    assert ViewPort.current_scene?( pid )
#    refute ViewPort.current_scene?( self() )
#
#    state = Map.put(@state, :scene_state, :ok_state)
#    {:noreply, state} = Scene.handle_cast(:set_scene, state)
#    refute ViewPort.current_scene?( pid )
#    assert ViewPort.current_scene?( self() )
#
#    # clean up
#    Agent.stop(pid)
#  end

  test "handle_cast :set_scene sends set_graph to the driver" do
    # register for the driver message
    {:ok, _} = Registry.register(@driver_registry, :set_graph, :set_graph )
    state = Map.put(@state, :scene_state, :ok_state)

    Scene.handle_cast(:set_scene, state)
    
    assert_receive( {:"$gen_cast", {:set_graph, graph_list}} )
    assert is_list( graph_list )
  end


  test "handle_cast :set_scene fails peacefully if the new scene cancels" do
    state = Map.put(@state, :scene_state, :cancel_state)
    {:noreply, state} = Scene.handle_cast(:set_scene, state)
    %{
      scene_module:       __MODULE__,
      scene_state:        :focus_gained_cancel_state,
      graph:              updated_graph
    } = state
    updated_graph = Map.put(updated_graph, :last_recurring_action, nil)
    assert updated_graph == @graph_2
    assert ViewPort.current_scene() == nil
  end

  #--------------------------------------------------------
  # handle_cast(:graph_reset...

  test "handle_cast :graph_reset ticks the recurring actions" do
    {:noreply, state} = Scene.handle_cast(:graph_reset, @state)
    %{
      scene_module:       __MODULE__,
      scene_state:        :faux_state,
      graph:              graph
    } = state
    # the rectangle primitive should have changed
    assert Graph.get(@graph,1) != Graph.get(graph,1)
  end

  test "handle_cast :graph_reset sets the graph into the viewport" do
    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )

    # register for the driver message
    {:ok, _} = Registry.register(@driver_registry, :set_graph, :set_graph )

    # using graph_2 as there is no animation going on. won't change as it ticks
    min_list =  Graph.minimal( @graph_2 )
    state = Map.put(@state, :graph, @graph_2)

    Scene.handle_cast(:graph_reset, state)

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:set_graph, graph_list}}  )
    assert graph_list == min_list
  end

  #--------------------------------------------------------
  # handle_cast(:graph_update...

  test "handle_cast :graph_update ticks the recurring actions" do
    {:noreply, state} = Scene.handle_cast(:graph_update, @state)
    %{
      scene_module:       __MODULE__,
      scene_state:        :faux_state,
      graph:              graph
    } = state
    # the rectangle primitive should have changed
    assert Graph.get(@graph,1) != Graph.get(graph,1)
  end

  test "handle_cast :graph_update sends deltas to the viewport" do
    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )

    # register for the driver message
    {:ok, _} = Registry.register(@driver_registry, :update_graph, :update_graph )

    # transform the graph so that is a delta to send
    graph = Graph.modify(@graph_2, :rect, fn(p)->
      Primitive.put_style(p, :color, :red)
    end)
    state = Map.put(@state, :graph, graph)
    
    deltas =  Graph.get_delta_scripts( graph )
    Scene.handle_cast(:graph_update, state)

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:update_graph, delta_list}}  )
    assert delta_list == deltas
  end


  test "handle_cast :graph_update resets the delta tracking on the graph" do
    # transform the graph so that is a delta to send
    graph = Graph.modify(@graph, :rect, fn(p)->
      Primitive.put_style(p, :color, :red)
    end)
    state = Map.put(@state, :graph, graph)

    # confirm the graph in the state has deltas
    assert state
    |> Map.get( :graph )
    |> Map.get( :deltas ) != %{}

    {:noreply, state} = Scene.handle_cast(:graph_update, state)

    # confirm the graph in the state no longer has deltas
    assert state
    |> Map.get( :graph )
    |> Map.get( :deltas ) == %{}
  end

end



























