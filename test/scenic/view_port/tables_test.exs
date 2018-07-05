#
#  Created by Boyd Multerer on July 5, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#


defmodule Scenic.ViewPort.TablesTest do
  use ExUnit.Case, async: true
  use Bitwise
  doctest Scenic

  alias Scenic.Graph
  alias Scenic.ViewPort.Tables
  import Scenic.Primitives


 import IEx

  # ets table names
  @ets_subs_table       :_scenic_subs_table_
  @ets_graphs_table     :_scenic_graphs_table_
  @ets_scenes_table     :_scenic_scenes_table_

  @agent_name           Scenic.ViewPort.Tables

  @graph    Graph.build()
    |> text( "Main Graph" )

  @graph_2  Graph.build()
    |> text( "Second Graph" )


  #--------------------------------------------------------
  setup do
    assert :ets.info( @ets_graphs_table ) == :undefined
    assert :ets.info( @ets_scenes_table ) == :undefined
    assert :ets.info( @ets_subs_table ) == :undefined
    :ets.new(@ets_graphs_table, [:public, :named_table])
    :ets.new(@ets_scenes_table, [:named_table])
    :ets.new(@ets_subs_table, [:bag, :named_table])

    {:ok, agent} = Agent.start(fn -> 1 + 1 end, name: @agent_name)
    on_exit fn -> Agent.stop( agent ) end

    %{agent: agent}
  end


  #============================================================================
  # access table names

  test "graphs_table returns the name" do
    assert Tables.graphs_table() == @ets_graphs_table
  end

  test "scenes_table returns the name" do
    assert Tables.scenes_table() == @ets_scenes_table
  end

  test "subs_table returns the name" do
    assert Tables.subs_table() == @ets_subs_table
  end

  #============================================================================
  # get_scene_pid( scene_or_graph_key )

  test "get_scene_pid works", %{agent: agent_0} do
    {:ok, agent_1} = Agent.start( fn -> 1 + 1 end )

    scene_ref = make_ref()
    graph = {:graph, scene_ref, 123}
    registration = {self(), agent_0, agent_1}

    # insert the table record
    :ets.insert(@ets_scenes_table, {scene_ref, registration})

    # it works with either scene_ref or graph
    Tables.get_scene_pid(scene_ref) == self()
    Tables.get_scene_pid(graph) == self()

    Agent.stop(agent_1)
  end

  #============================================================================
  # get_scene_registration( scene_or_graph_key )

  test "get_scene_registration works", %{agent: agent_0} do
    {:ok, agent_1} = Agent.start( fn -> 1 + 1 end )

    scene_ref = make_ref()
    graph = {:graph, scene_ref, 123}
    registration = {self(), agent_0, agent_1}

    # insert the table record
    :ets.insert(@ets_scenes_table, {scene_ref, registration})

    # it works with either scene_ref or graph
    Tables.get_scene_registration(scene_ref) == registration
    Tables.get_scene_registration(graph) == registration

    Agent.stop(agent_1)
  end

  #============================================================================
  # insert_graph( graph_key, scene_pid, graph, refs)

  test "insert_graph works" do
    scene_ref = make_ref()

    # insert the graph
    graph_key = {:graph, scene_ref, 123}
    Tables.insert_graph( graph_key, self(), @graph, [])

    # [{graph_key, pid, graph, refs}]
    assert :ets.lookup(@ets_graphs_table, graph_key) == [{graph_key, self(), @graph, []}]
  end

  test "insert_graph works with named scene" do
    scene_ref = :named_scene

    # insert the graph
    graph_key = {:graph, scene_ref, 123}
    Tables.insert_graph( graph_key, self(), @graph, [])

    # [{graph_key, pid, graph, refs}]
    assert :ets.lookup(@ets_graphs_table, graph_key) == [{graph_key, self(), @graph, []}]
  end

  #============================================================================
  # get_graph( graph_key )

  test "get_graph works" do
    graph_key = {:graph, :named_scene, 123}
    Tables.insert_graph( graph_key, self(), @graph, [])

    assert Tables.get_graph(graph_key) == {:ok, @graph}
  end

  test "get_graph returns error for missing key" do
    graph_key = {:graph, :bad_scene, 123}
    refute Tables.get_graph(graph_key)
  end

  test "get_graph returns error for bad key" do
    graph_key = :invalid_graph_key
    assert Tables.get_graph(graph_key) == {:error, :invalid_graph_key}
  end

  #============================================================================
  # delete_graph( graph_key )

  test "delete_graph deletes a graph" do
    graph_key = {:graph, :named_scene, 123}
    Tables.insert_graph( graph_key, self(), @graph, [])
    assert Tables.get_graph(graph_key)
    assert Tables.delete_graph(graph_key) == :ok
    refute Tables.get_graph(graph_key)
  end

  test "delete_graph unsubscribes all to the graph"

  test "delete_graph returns error for bad key" do
    graph_key = :invalid_graph_key
    assert Tables.delete_graph(graph_key) == {:error, :invalid_graph_key}
  end

  #============================================================================
  # get_refs( graph_key )

  test "get_refs works" do
    graph_key = {:graph, :named_scene, 123}
    Tables.insert_graph( graph_key, self(), @graph, [1, 2, 3])

    assert Tables.get_refs(graph_key) == {:ok, [1, 2, 3]}
  end

  test "get_refs returns error for bad key" do
    graph_key = :invalid_graph_key
    assert Tables.get_refs(graph_key) == {:error, :invalid_graph_key}
  end

  #============================================================================
  # get_refs( graph_key )

  test "get_graph_refs works" do
    graph_key = {:graph, :named_scene, 123}
    Tables.insert_graph( graph_key, self(), @graph, [1, 2, 3])

    assert Tables.get_graph_refs(graph_key) == {:ok, @graph, [1, 2, 3]}
  end

  test "get_graph_refs returns error for bad key" do
    graph_key = :invalid_graph_key
    assert Tables.get_graph_refs(graph_key) == {:error, :invalid_graph_key}
  end

  #============================================================================
  # list_graphs()

  test "list_graphs works" do
    graph_key = {:graph, :named_scene, 123}
    Tables.insert_graph( graph_key, self(), @graph, [1, 2, 3])
    assert Tables.list_graphs() == [graph_key]
  end

  #============================================================================
  # list_graphs_for_scene()

  test "list_graphs_for_scene works" do
    scene_ref = make_ref()

    # insert the graph
    graph_key = {:graph, scene_ref, 123}
    Tables.insert_graph( graph_key, self(), @graph, [1, 2, 3])

    # insert a graph to another scene
    graph_key_2 = {:graph, :scene_ref, 123}
    Tables.insert_graph( graph_key_2, self(), @graph_2, [1, 2, 3])

    # list_graphs_for_scene works
    Tables.list_graphs_for_scene(scene_ref) == [graph_key]
    Tables.list_graphs_for_scene(:scene_ref) == [graph_key_2]
  end

  #============================================================================
  # list_subscriptions( pid )
  test "list_subscriptions works", %{agent: agent_0} do
    {:ok, agent_1} = Agent.start( fn -> 1 + 1 end )

    # insert the graph
    graph_key_0 = {:graph, make_ref(), 123}
    Tables.insert_graph( graph_key_0, self(), @graph, [1, 2])
    # insert a graph to another scene
    graph_key_1 = {:graph, :scene_ref, 456}
    Tables.insert_graph( graph_key_1, self(), @graph_2, [3, 4])

    # subscribe to the graphs
    :ets.insert(@ets_subs_table, {graph_key_0, agent_0})
    :ets.insert(@ets_subs_table, {graph_key_1, agent_1})

    # test the lists
    assert Tables.list_subscriptions(agent_0) == [graph_key_0]
    assert Tables.list_subscriptions(agent_1) == [graph_key_1]

    Agent.stop(agent_1)
  end

  #============================================================================
  # handle_info :DOWN

  test "handle_info :DOWN removes graphs from a crashed scene"

  test "handle_info :DOWN unsubscribes listeners to a crashed scene"

  test "handle_info :DOWN subscriber is unsubscribed"

  #============================================================================
  # handle_cast( {:register, scene_ref, registration}, state )

  test "handle_cast {:register works"

  test "handle_cast {:register starts monitoring the scene"

  #============================================================================
  # handle_cast( {:graph_subscribe, graph_key, pid}, state )

  test "handle_call {:graph_subscribe works"

  test "handle_call {:graph_subscribe does not create duplicate subscriptions"

  test "handle_call {:graph_subscribe starts monitoring the subscriber"

  #============================================================================
  # handle_cast( {:graph_subscribe, graph_key, pid}, state )

  test "handle_cast {:graph_subscribe works"

  test "handle_cast {:graph_subscribe does not create duplicate subscriptions"

  test "handle_cast {:graph_subscribe starts monitoring the subscriber"

  #============================================================================
  # handle_cast( {:graph_unsubscribe, :all, pid}, state )

  test "handle_cast {:graph_unsubscribe, :all works"

  #============================================================================
  # handle_cast( {:graph_unsubscribe, :graph_key, pid}, state )

  test "handle_cast {:graph_unsubscribe, :graph_key works"



end


































