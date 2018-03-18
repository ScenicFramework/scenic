#
#  Created by Boyd Multerer on 3/18/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#


defmodule Scenic.ViewPort2Test do
  use ExUnit.Case, async: false
  doctest Scenic
  alias Scenic.ViewPort2, as: ViewPort

  import IEx

  @graph_uid_offset 96000
  @max_depth        64

  @dynamic_scenes   :dynamic_scenes

  @state  %{
    root_scene: nil,
    graphs: %{},
    offsets: %{},
    filter_list: [],
    graph_count: 0,
    max_depth: 64
  }

  @min_graph %{
    0 => %{
      data: {Scenic.Primitive.Group, [1]},
      styles: %{font: {:roboto, 16}}
    },
    1 => %{
      data: {Scenic.Primitive.Line, {{0, 0}, {500, 0}}},
      styles: %{color: {{0, 0, 0, 255}}}
    }
  }

  @offset_min_graph %{
    96000 => %{
      data: {Scenic.Primitive.Group, [96001]},
      styles: %{font: {:roboto, 16}}
    },
    96001 => %{
      data: {Scenic.Primitive.Line, {{0, 0}, {500, 0}}},
      styles:  %{color: {{0, 0, 0, 255}}}
    }
  }

  defmodule TestScene do
    use Scenic.Scene

    @graph Scenic.Graph.build( font: {:roboto, 16} )
    |> Scenic.Primitive.Line.add_to_graph({{0,0},{500,0}}, color: :blue)

    def init( opts ) do
      graph = @graph
      {:ok, graph, opts}
    end

  end


  #============================================================================
  # set_graph

  test "test graph sends a minimized graph to the viewport" do
    self_pid = self()
    assert_receive( {:"$gen_cast", {:set_graph, @min_graph, ^self_pid, :test_id}} )
  end

  #============================================================================
  # init

  test "init sets up default state" do
    assert ViewPort.init([]) == {:ok, %{
      root_scene: nil,
      graphs: %{},
      offsets: %{},
      filter_list: [],
      graph_count: 0,
      max_depth: @max_depth
    }}
  end

  test "init accepts an optional max_depth" do
    assert ViewPort.init([max_depth: 128]) == {:ok, %{
      root_scene: nil,
      graphs: %{},
      offsets: %{},
      filter_list: [],
      graph_count: 0,
      max_depth: 128
    }}
  end


  #============================================================================
  # handle_cast( {:set_scene, scene, scene_param}

  test ":set_scene sets a scene by pid and tells it to set it's graph" do
    {:ok, dynamic_supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_scenes)

    # set the a scene as root
    {:noreply, state} = ViewPort.handle_cast({:set_scene, self(), :test_graph}, @state)

    # the scene should be started and set as the root
    assert state.root_scene == {self(), nil}
    assert state.offsets == %{ {self(), nil} => 0 }
    assert state.graph_count == 1
    assert state.filter_list == []
    assert state.graphs == %{}

    assert_receive( {:"$gen_cast", {:set_graph, nil}} )

    # clean up
    Supervisor.stop(dynamic_supervisor)
  end

  test ":set_scene starts a dynamic scene" do
    {:ok, dynamic_supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_scenes)
    assert DynamicSupervisor.which_children( @dynamic_scenes ) == []

    # set a dynamic scene as root
    {:noreply, state} = ViewPort.handle_cast({:set_scene, {TestScene, :init_data}, :test_graph}, @state)

    # the dynamic scene should be started and set as the root
    {dynamic_scene_pid, nil} = state.root_scene
    assert state.offsets == %{ {dynamic_scene_pid, nil} => 0 }
    assert state.graph_count == 1
    assert state.filter_list == []
    assert state.graphs == %{}

    # confirm the DynamicSupervisor is supervising it
    [{_, ^dynamic_scene_pid, _, _}] = DynamicSupervisor.which_children( @dynamic_scenes )

    # clean up
    Supervisor.stop(dynamic_supervisor)
  end

  test ":set_scene stops all previous dyanamic scenes" do
    {:ok, dynamic_supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_scenes)

    # start a simple agent just so we can watch it close...
    {:ok, agent_pid} = DynamicSupervisor.start_child(@dynamic_scenes, {Agent, fn -> %{} end})
    # confirm previous_pid is good
    [{_, ^agent_pid, _, _}] = DynamicSupervisor.which_children( @dynamic_scenes )
    assert Process.info(agent_pid)

    # set the scene as root
    {:noreply, _} = ViewPort.handle_cast({:set_scene, self(), :test_graph}, @state)

    # the agent was shut down
    assert DynamicSupervisor.which_children( @dynamic_scenes ) == []
    refute Process.info(agent_pid)

    # clean up
    Supervisor.stop(dynamic_supervisor)
  end


  #============================================================================
  # handle_cast( {:set_graph, min_graph, scene_pid, id}

  test ":set_graph sets a new graph, and tracks offsets (as first graph)" do
    graph_id = {self(), :test_graph}
    
    {:noreply, state} = ViewPort.handle_cast({:set_graph, @min_graph, self(), :test_graph}, @state)

    # make sure the graph was added with no offset (is the first one...)
    assert get_in(state, [:graphs, graph_id]) == @min_graph

    # the offset should be tracked
    assert state.offsets == %{graph_id => 0}
    assert state.graph_count == 1

    # the filter_list should be empty as there is no root scene set
    assert state.filter_list == []
  end

  test ":set_graph reuses the offset of an already set graph" do
    graph_id = {self(), :test_graph}

    state = @state
    |> put_in([:offsets, graph_id], @graph_uid_offset)
    |> Map.put(:graph_count, 1)

    {:noreply, state} = ViewPort.handle_cast({:set_graph, @min_graph, self(), :test_graph}, state)

    # make sure the graph was added with no offset (is the first one...)
    assert get_in(state, [:graphs, graph_id]) == @offset_min_graph

    # the offset should be tracked
    assert state.offsets == %{graph_id => @graph_uid_offset}
    assert state.graph_count == 1

    # the filter_list should be empty as there is no root scene set
    assert state.filter_list == []
  end

  test ":set_graph sets and offsets a new graph" do

    state = @state
    |> put_in([:offsets, {self(), :test_graph_one}], 0)
    |> put_in([:graphs, {self(), :test_graph_one}], @min_graph)
    |> Map.put(:graph_count, 1)

    {:noreply, state} = ViewPort.handle_cast({:set_graph, @min_graph, self(), :test_graph_two}, state)

    # make sure the graph are right
    assert get_in(state, [:graphs, {self(), :test_graph_one}]) == @min_graph
    assert get_in(state, [:graphs, {self(), :test_graph_two}]) == @offset_min_graph

    # the offset should be tracked
    assert state.offsets == %{
      {self(), :test_graph_one} => 0,
      {self(), :test_graph_two} => @graph_uid_offset,
    }
    assert state.graph_count == 2

    # the filter_list should be empty as there is no root scene set
    assert state.filter_list == []
  end

  test ":set_graph tells a scene_ref to set it's graph" do
    min_graph = %{
      0 => %{ data: {Scenic.Primitive.Group, [1]} },
      1 => %{ data: {Scenic.Primitive.SceneRef, {self(), :test_graph}} }
    }

    {:noreply, _} = ViewPort.handle_cast({:set_graph, min_graph, self(), nil}, @state)

    assert_receive( {:"$gen_cast", {:set_graph, :test_graph}} )
  end

  test ":set_graph tells multiple scene_refs to set their graph" do
    min_graph = %{
      0 => %{ data: {Scenic.Primitive.Group, [1,2]} },
      1 => %{ data: {Scenic.Primitive.SceneRef, {self(), :test_graph_0}} },
      2 => %{ data: {Scenic.Primitive.SceneRef, {self(), :test_graph_1}} }
    }

    {:noreply, _} = ViewPort.handle_cast({:set_graph, min_graph, self(), nil}, @state)

    assert_receive( {:"$gen_cast", {:set_graph, :test_graph_0}} )
    assert_receive( {:"$gen_cast", {:set_graph, :test_graph_1}} )
  end

  test ":set_graph tells a scene_ref to set it's graph - only once even if referenced twice" do
    min_graph = %{
      0 => %{ data: {Scenic.Primitive.Group, [1,2]} },
      1 => %{ data: {Scenic.Primitive.SceneRef, {self(), :test_graph}} },
      2 => %{ data: {Scenic.Primitive.SceneRef, {self(), :test_graph}} }
    }

    {:noreply, _} = ViewPort.handle_cast({:set_graph, min_graph, self(), nil}, @state)

    assert_receive( {:"$gen_cast", {:set_graph, :test_graph}} )
    refute_received( {:"$gen_cast", {:set_graph, :test_graph}} )
  end

  test ":set_graph resolves named scene_refs" do
    {:ok, scene_pid} = Scenic.Scene.start_link(TestScene, :named_scene, [])

    min_graph = %{
      0 => %{ data: {Scenic.Primitive.Group, [1]} },
      1 => %{ data: {Scenic.Primitive.SceneRef, {:named_scene, :test_ref}} }
    }

    {:noreply, state} = ViewPort.handle_cast({:set_graph, min_graph, self(), nil}, @state)

    assert state.graphs[{self(), nil}][1] ==
      %{ data: {Scenic.Primitive.SceneRef, {scene_pid, :test_ref}} }

    # clean up
    GenServer.stop(scene_pid)
  end

  test ":set_graph starts dynamic referenced scenes" do
    {:ok, dynamic_supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_scenes)

    # confirm dynamic_supervisor has no children
    assert DynamicSupervisor.which_children( @dynamic_scenes ) == []
    
    min_graph = %{
      0 => %{ data: {Scenic.Primitive.Group, [1]} },
      1 => %{ data: {Scenic.Primitive.SceneRef, {{TestScene, :init_data}, :test_ref}} }
    }

    {:noreply, state} = ViewPort.handle_cast({:set_graph, min_graph, self(), :nil}, @state)

    # the pid to the dynamic child should now be in the state
    child_pid = Enum.find_value(state.graphs[{self(),:nil}], fn({_,p})->
      case p do
        %{data: {Scenic.Primitive.SceneRef, {pid,:test_ref}}} ->
          pid
        _ ->
          false
      end
    end)

    # confirm there is now one child
    [{_, ^child_pid, _, _}] = DynamicSupervisor.which_children( @dynamic_scenes )

    # clean up
    Supervisor.stop(dynamic_supervisor)
  end




end



























