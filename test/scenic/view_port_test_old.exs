#
#  Created by Boyd Multerer on 3/18/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPortTest do
  use ExUnit.Case, async: false
  doctest Scenic
  alias Scenic.ViewPort

  #  import IEx

  @max_depth 64
  @root_graph 0

  @dynamic_scenes :dynamic_scenes

  @state %{
    graphs: %{},
    filter_list: [],
    graph_count: 0,
    graph_ids: %{},
    graph_keys: %{},
    max_depth: 64
  }

  @graph Scenic.Graph.build(font: {:roboto, 16})
         |> Scenic.Primitive.Line.add_to_graph({{0, 0}, {500, 0}}, color: :blue)

  @min_graph %{
    0 => %{
      data: {Scenic.Primitive.Group, [1]},
      styles: %{font: {:roboto, 16}}
    },
    1 => %{
      data: {Scenic.Primitive.Line, {{0, 0}, {500, 0}}},
      styles: %{color: {{0, 0, 255, 255}}}
    }
  }

  @delta_list [
    {0, [{:put, :data, {Scenic.Primitive.Group, [1, 2]}}]},
    {1,
     [
       {:put, :data, {Scenic.Primitive.Line, {{0, 0}, {100, 0}}}}
     ]},
    {2, [{:put, :data, {Scenic.Primitive.Line, {{0, 0}, {200, 0}}}}]}
  ]

  @updated_graph %{
    0 => %{
      data: {Scenic.Primitive.Group, [1, 2]},
      styles: %{font: {:roboto, 16}}
    },
    1 => %{
      data: {Scenic.Primitive.Line, {{0, 0}, {100, 0}}},
      styles: %{color: {{0, 0, 255, 255}}}
    },
    2 => %{
      data: {Scenic.Primitive.Line, {{0, 0}, {200, 0}}}
    }
  }

  defmodule TestScene do
    use Scenic.Scene

    @graph Scenic.Graph.build(font: {:roboto, 16})
           |> Scenic.Primitive.Line.add_to_graph({{0, 0}, {500, 0}}, color: :blue)

    def init(opts) do
      graph = @graph
      {:ok, graph, opts}
    end
  end

  @delta_list_ref [
    {0, [{:put, :data, {Scenic.Primitive.Group, [1, 2]}}]},
    {1,
     [
       {:put, :data, {Scenic.Primitive.SceneRef, {{TestScene, :opts}, :delta_ref}}}
     ]}
  ]

  # ============================================================================
  # set_scene

  test "test set_scene sends a set_scene message to the viewport" do
    ViewPort.set_scene(:test_id, 123)
    assert_receive({:"$gen_cast", {:set_scene, :test_id, 123}})
  end

  test "test set_scene resolves a named scene to a pid before sending" do
    self_pid = self()
    {:ok, scene_pid} = Scenic.Scene.start_link(TestScene, :named_scene, [])

    ViewPort.set_scene(:named_scene, :test_id, self_pid)
    assert_receive({:"$gen_cast", {:set_scene, ^scene_pid, :test_id}})

    # clean up
    GenServer.stop(scene_pid)
  end

  # ============================================================================
  # set_graph

  test "test set_graph sends a minimized graph to the viewport" do
    self_pid = self()
    ViewPort.set_graph(@min_graph, self_pid, :test_id, self_pid)
    assert_receive({:"$gen_cast", {:set_graph, @min_graph, ^self_pid, :test_id}})
  end

  test "test set_graph sends a minimizes a graph before sending to the viewport" do
    self_pid = self()
    ViewPort.set_graph(@graph, self_pid, :test_id, self_pid)
    assert_receive({:"$gen_cast", {:set_graph, @min_graph, ^self_pid, :test_id}})
  end

  test "test set_graph resolves a named scene to a pid before sending" do
    self_pid = self()
    {:ok, scene_pid} = Scenic.Scene.start_link(TestScene, :named_scene, [])

    ViewPort.set_graph(@graph, :named_scene, :test_id, self_pid)
    assert_receive({:"$gen_cast", {:set_graph, @min_graph, ^scene_pid, :test_id}})

    # clean up
    GenServer.stop(scene_pid)
  end

  # ============================================================================
  # update_graph

  test "test update_graph sends list of deltas to the viewport" do
    self_pid = self()
    deltas = [:a, :b, :c]
    ViewPort.update_graph(deltas, self_pid, :test_id, self_pid)
    assert_receive({:"$gen_cast", {:update_graph, ^deltas, ^self_pid, :test_id}})
  end

  test "test update_graph extracts deltas from a graph before sending to the viewport" do
    self_pid = self()
    deltas = [:a, :b, :c]
    graph = Map.put(@graph, :deltas, deltas)
    ViewPort.update_graph(graph, self_pid, :test_id, self_pid)
    assert_receive({:"$gen_cast", {:update_graph, ^deltas, ^self_pid, :test_id}})
  end

  test "test update_graph resolves a named scene to a pid before sending" do
    self_pid = self()
    deltas = [:a, :b, :c]
    {:ok, scene_pid} = Scenic.Scene.start_link(TestScene, :named_scene, [])

    ViewPort.update_graph(deltas, :named_scene, :test_id, self_pid)
    assert_receive({:"$gen_cast", {:update_graph, ^deltas, ^scene_pid, :test_id}})

    # clean up
    GenServer.stop(scene_pid)
  end

  # ============================================================================
  # input

  test "input casts an input event to the viewport" do
    ViewPort.input(:some_input, self())
    assert_receive({:"$gen_cast", {:input, :some_input}})
  end

  # ============================================================================
  # init

  test "init sets up default state" do
    assert ViewPort.init([]) ==
             {:ok,
              %{
                graphs: %{},
                filter_list: [],
                graph_count: 0,
                graph_ids: %{},
                graph_keys: %{},
                max_depth: @max_depth
              }}
  end

  test "init accepts an optional max_depth" do
    assert ViewPort.init(max_depth: 128) ==
             {:ok,
              %{
                graphs: %{},
                filter_list: [],
                graph_count: 0,
                graph_ids: %{},
                graph_keys: %{},
                max_depth: 128
              }}
  end

  # ============================================================================
  # handle_cast( {:set_scene, scene, scene_param}

  test ":set_scene sets a scene by pid and tells it to set its graph" do
    {:ok, dynamic_supervisor} =
      DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_scenes)

    # set the a scene as root
    {:noreply, state} = ViewPort.handle_cast({:set_scene, self(), :test_graph}, @state)

    # the scene should be started and set as the root
    assert state.graph_count == 1
    assert state.filter_list == []
    assert state.graphs == %{}
    assert state.graph_ids == %{{self(), nil} => @root_graph}
    assert state.graph_keys == %{@root_graph => {self(), nil}}

    assert_receive({:"$gen_cast", {:set_scene, :test_graph}})

    # clean up
    Supervisor.stop(dynamic_supervisor)
  end

  test ":set_scene starts a dynamic scene" do
    {:ok, dynamic_supervisor} =
      DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_scenes)

    assert DynamicSupervisor.which_children(@dynamic_scenes) == []

    # set a dynamic scene as root
    {:noreply, state} =
      ViewPort.handle_cast({:set_scene, {TestScene, :init_data}, :test_graph}, @state)

    # the dynamic scene should be started and set as the root
    {dynamic_scene_pid, nil} = get_in(state, [:graph_keys, @root_graph])

    # confirm the DynamicSupervisor is supervising it
    [{_, ^dynamic_scene_pid, _, _}] = DynamicSupervisor.which_children(@dynamic_scenes)

    # clean up
    Supervisor.stop(dynamic_supervisor)
  end

  test ":set_scene stops all previous dyanamic scenes" do
    {:ok, dynamic_supervisor} =
      DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_scenes)

    # start a simple agent just so we can watch it close...
    {:ok, agent_pid} = DynamicSupervisor.start_child(@dynamic_scenes, {Agent, fn -> %{} end})
    # confirm previous_pid is good
    [{_, ^agent_pid, _, _}] = DynamicSupervisor.which_children(@dynamic_scenes)
    assert Process.info(agent_pid)

    # set the scene as root
    {:noreply, _} = ViewPort.handle_cast({:set_scene, self(), :test_graph}, @state)

    # the agent was shut down
    assert DynamicSupervisor.which_children(@dynamic_scenes) == []
    refute Process.info(agent_pid)

    # clean up
    Supervisor.stop(dynamic_supervisor)
  end

  # ============================================================================
  # handle_cast( {:set_graph, min_graph, scene_pid, id}

  test ":set_graph sets a new graph, and tracks the id (as first graph)" do
    {:noreply, state} =
      ViewPort.handle_cast({:set_graph, @min_graph, self(), :test_graph}, @state)

    # get the assigned graph_id
    graph_id = get_in(state, [:graph_ids, {self(), :test_graph}])

    # make sure the graph was added with no offset (is the first one...)
    assert get_in(state, [:graphs, graph_id]) == @min_graph

    # the offset should be tracked
    assert graph_id == 0
    assert get_in(state, [:graph_keys, graph_id]) == {self(), :test_graph}

    # the filter_list should be empty as there is no root scene set
    assert state.filter_list == []
  end

  test ":set_graph reuses the id of an already set graph" do
    graph_key = {self(), :test_graph}

    state =
      @state
      |> put_in([:graph_ids, graph_key], 123)
      |> put_in([:graph_keys, 123], graph_key)
      |> Map.put(:graph_count, 123)

    {:noreply, state} = ViewPort.handle_cast({:set_graph, @min_graph, self(), :test_graph}, state)

    # make sure the graph was added at the reused id
    assert get_in(state, [:graphs, 123]) == @min_graph

    # make sure nothing was added to the id/key maps
    assert state.graph_ids == %{graph_key => 123}
    assert state.graph_keys == %{123 => graph_key}

    # the filter_list should be empty as there is no root scene set
    assert state.filter_list == []
  end

  test ":set_graph tells a scene_ref to set its graph" do
    min_graph = %{
      0 => %{data: {Scenic.Primitive.Group, [1]}},
      1 => %{data: {Scenic.Primitive.SceneRef, {self(), :test_graph}}}
    }

    {:noreply, _} = ViewPort.handle_cast({:set_graph, min_graph, self(), nil}, @state)

    assert_receive({:"$gen_cast", {:set_graph, :test_graph}})
  end

  test ":set_graph tells multiple scene_refs to set their graph" do
    min_graph = %{
      0 => %{data: {Scenic.Primitive.Group, [1, 2]}},
      1 => %{data: {Scenic.Primitive.SceneRef, {self(), :test_graph_0}}},
      2 => %{data: {Scenic.Primitive.SceneRef, {self(), :test_graph_1}}}
    }

    {:noreply, _} = ViewPort.handle_cast({:set_graph, min_graph, self(), nil}, @state)

    assert_receive({:"$gen_cast", {:set_graph, :test_graph_0}})
    assert_receive({:"$gen_cast", {:set_graph, :test_graph_1}})
  end

  test ":set_graph tells a scene_ref to set its graph - only once even if referenced twice" do
    min_graph = %{
      0 => %{data: {Scenic.Primitive.Group, [1, 2]}},
      1 => %{data: {Scenic.Primitive.SceneRef, {self(), :test_graph}}},
      2 => %{data: {Scenic.Primitive.SceneRef, {self(), :test_graph}}}
    }

    {:noreply, _} = ViewPort.handle_cast({:set_graph, min_graph, self(), nil}, @state)

    assert_receive({:"$gen_cast", {:set_graph, :test_graph}})
    refute_received({:"$gen_cast", {:set_graph, :test_graph}})
  end

  test ":set_graph resolves named scene_refs" do
    {:ok, scene_pid} = Scenic.Scene.start_link(TestScene, :named_scene, [])

    min_graph = %{
      0 => %{data: {Scenic.Primitive.Group, [1]}},
      1 => %{data: {Scenic.Primitive.SceneRef, {:named_scene, :test_ref}}}
    }

    {:noreply, state} = ViewPort.handle_cast({:set_graph, min_graph, self(), nil}, @state)

    main_graph_id = get_in(state, [:graph_ids, {self(), nil}])
    ref_graph_id = get_in(state, [:graph_ids, {scene_pid, :test_ref}])
    assert state.graphs[main_graph_id][1] == %{data: {Scenic.Primitive.SceneRef, ref_graph_id}}

    # clean up
    GenServer.stop(scene_pid)
  end

  test ":set_graph starts dynamic referenced scenes" do
    {:ok, dynamic_supervisor} =
      DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_scenes)

    # confirm dynamic_supervisor has no children
    assert DynamicSupervisor.which_children(@dynamic_scenes) == []

    min_graph = %{
      0 => %{data: {Scenic.Primitive.Group, [1]}},
      1 => %{data: {Scenic.Primitive.SceneRef, {{TestScene, :init_data}, :test_ref}}}
    }

    {:noreply, state} = ViewPort.handle_cast({:set_graph, min_graph, self(), nil}, @state)

    # get the pid from the DynamicSupervisor
    [{_, dyn_ref_pid, _, _}] = DynamicSupervisor.which_children(@dynamic_scenes)

    # confirm the child_pid is reference in the id/key maps
    graph_key = {dyn_ref_pid, :test_ref}
    graph_id = get_in(state, [:graph_ids, graph_key])
    assert get_in(state, [:graph_keys, graph_id]) == graph_key

    # clean up
    Supervisor.stop(dynamic_supervisor)
  end

  # ============================================================================
  # handle_cast( {:update_graph, delta_list, scene_pid, id}

  test ":update_graph raises if the scene is not set" do
    graph_key = {self(), :test_graph}

    state =
      @state
      |> put_in([:graph_ids, graph_key], 0)
      |> put_in([:graph_keys, 0], graph_key)
      |> put_in([:graphs, 0], @min_graph)
      |> Map.put(:graph_count, 0)

    assert_raise RuntimeError, fn ->
      ViewPort.handle_cast({:update_graph, @delta_list, self(), :not_set}, state)
    end
  end

  test ":update_graph applies the (offset) deltas to the set graph" do
    graph_key = {self(), :test_graph}

    state =
      @state
      |> put_in([:graph_ids, graph_key], 0)
      |> put_in([:graph_keys, 0], graph_key)
      |> put_in([:graphs, 0], @min_graph)
      |> Map.put(:graph_count, 0)

    {:noreply, state} =
      ViewPort.handle_cast({:update_graph, @delta_list, self(), :test_graph}, state)

    # confirm that the graph has been updated
    assert get_in(state, [:graphs, 0]) == @updated_graph
  end

  test ":update_graph starts up references in the deltas" do
    {:ok, dynamic_supervisor} =
      DynamicSupervisor.start_link(strategy: :one_for_one, name: @dynamic_scenes)

    graph_key = {self(), :test_graph}

    state =
      @state
      |> put_in([:graph_ids, graph_key], 0)
      |> put_in([:graph_keys, 0], graph_key)
      |> put_in([:graphs, 0], @min_graph)
      |> Map.put(:graph_count, 0)

    {:noreply, state} =
      ViewPort.handle_cast({:update_graph, @delta_list_ref, self(), :test_graph}, state)

    # get the pid from the DynamicSupervisor
    [{_, dyn_ref_pid, _, _}] = DynamicSupervisor.which_children(@dynamic_scenes)

    # confirm the child_pid is reference in the id/key maps
    ref_key = {dyn_ref_pid, :delta_ref}
    ref_id = get_in(state, [:graph_ids, ref_key])
    assert get_in(state, [:graph_keys, ref_id]) == ref_key

    # confirm the reference in the graph itself points to the graph_id
    graph_id = get_in(state, [:graph_ids, graph_key])
    graph = get_in(state, [:graphs, graph_id])
    assert graph[1].data == {Scenic.Primitive.SceneRef, ref_id}

    # clean up
    Supervisor.stop(dynamic_supervisor)
  end
end
