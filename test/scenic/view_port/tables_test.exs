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

 # import IEx

  # ets table names
  @ets_subs_table       :_scenic_subs_table_
  @ets_graphs_table     :_scenic_graphs_table_
  @ets_scenes_table     :_scenic_scenes_table_

  @agent_name           Scenic.ViewPort.Tables

  @graph    Graph.build()
    |> text( "Main Graph" )

  @graph_1  Graph.build()
    |> text( "Second Graph" )

  @state %{sub_monitors: %{}}


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
    assert Tables.get_scene_pid(scene_ref) == {:ok, self()}
    assert Tables.get_scene_pid(graph) == {:ok, self()}

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
    assert Tables.get_scene_registration(scene_ref) == {:ok, registration}
    assert Tables.get_scene_registration(graph) == {:ok, registration}

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

  # test "delete_graph unsubscribes all to the graph", %{agent: scene} do
  #   # setup
  #   graph_key = {:graph, make_ref(), 123}
  #   Tables.insert_graph( graph_key, scene, @graph, [])
  #   Tables.handle_cast( {:graph_subscribe, graph_key, self()}, @state )

  #   # confirm setup
  #   assert :ets.lookup(@ets_subs_table, graph_key) == [ {graph_key, self()} ]

  #   # delete the graph
  #   Tables.delete_graph(graph_key)
  #   refute Tables.get_graph(graph_key)

  #   # we should get a message to unsubscribe
  #   assert_received( {:"$gen_cast", {:graph_unsubscribe, ^graph_key, ^self}} )

  #   # we should have also gotten the delete graph messages
  #   assert_received( {:"$gen_cast", {:delete_graph, ^graph_key}} )
  # end

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
    graph_key_0 = {:graph, scene_ref, 123}
    Tables.insert_graph( graph_key_0, self(), @graph, [1, 2, 3])

    # insert a graph to another scene
    graph_key_1 = {:graph, :scene_ref, 123}
    Tables.insert_graph( graph_key_1, self(), @graph_1, [1, 2, 3])

    # list_graphs_for_scene works
    assert Tables.list_graphs_for_scene(scene_ref) == [graph_key_0]
    assert Tables.list_graphs_for_scene(:scene_ref) == [graph_key_1]
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
    Tables.insert_graph( graph_key_1, self(), @graph_1, [3, 4])

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


  test "handle_info :DOWN removes graphs from a normal shutdown scene" do
    # set up the scene
    scene_ref = make_ref()
    registration = {self(), nil, nil}
    :ets.insert(@ets_scenes_table, {scene_ref, registration})

    # set up the graph
    graph_key = {:graph, make_ref(), 123}
    Tables.insert_graph( graph_key, self(), @graph, [1, 2])
    assert Tables.list_graphs() == [graph_key]

    # process a fake a DOWN message
    Tables.handle_info( {:DOWN, make_ref(), :process, self(), :shutdown}, @state )

    assert Tables.list_graphs() == []
  end

  test "handle_info :DOWN sends subscribers a delete_graph message" do
    # set up the scene
    {:ok, scene} = Agent.start( fn -> 1 + 1 end )
    scene_ref = make_ref()
    registration = {scene, nil, nil}
    :ets.insert(@ets_scenes_table, {scene_ref, registration})

    # set up the graph
    graph_key = {:graph, scene_ref, 123}
    Tables.insert_graph( graph_key, scene, @graph, [1, 2])
    assert Tables.list_graphs() == [graph_key]

    # subscribe to the graph
    Tables.handle_cast( {:graph_subscribe, graph_key, self()}, @state )

    # process a fake a DOWN message
    Tables.handle_info( {:DOWN, make_ref(), :process, scene, :shutdown}, @state )

    # we should have gotten the delete graph messages
    assert_received( {:"$gen_cast", {:delete_graph, ^graph_key}} )

    Agent.stop(scene)
  end

  test "handle_info :DOWN deletes subscribers to a normal shutdown scenes graphs" do
    # set up the scene
    {:ok, scene} = Agent.start( fn -> 1 + 1 end )
    scene_ref = make_ref()
    registration = {scene, nil, nil}
    :ets.insert(@ets_scenes_table, {scene_ref, registration})

    # set up the graph
    graph_key = {:graph, scene_ref, 123}
    Tables.insert_graph( graph_key, scene, @graph, [1, 2])
    assert Tables.list_graphs() == [graph_key]

    # subscribe to the graph
    Tables.handle_cast( {:graph_subscribe, graph_key, self()}, @state )

    # process a fake a DOWN message
    Tables.handle_info( {:DOWN, make_ref(), :process, scene, :shutdown}, @state )

    # inspect the subs table to make sure it is empty
    assert :ets.lookup(@ets_subs_table, graph_key) == []

    Agent.stop(scene)
  end

  test "handle_info :DOWN of a subscriber cleans up its subscription" do
    # set up the graph
    graph_key = {:graph, :scene_ref, 123}
    Tables.insert_graph( graph_key, self(), @graph, [1, 2])
    assert Tables.list_graphs() == [graph_key]

    # set up the subscriber
    {:ok, subscriber} = Agent.start( fn -> 1 + 1 end )
    Tables.handle_cast( {:graph_subscribe, graph_key, subscriber}, @state )
    assert :ets.lookup(@ets_subs_table, graph_key) == [{graph_key, subscriber}]

    # process a fake a DOWN message
    Tables.handle_info( {:DOWN, make_ref(), :process, subscriber, :shutdown}, @state )

    # inspect the subs table to make sure it is empty
    assert :ets.lookup(@ets_subs_table, graph_key) == []

    # the graph should still be OK
    assert Tables.get_graph(graph_key) == {:ok, @graph}

    Agent.stop(subscriber)
  end



  #============================================================================
  # handle_cast( {:register, scene_ref, registration}, state )

  test "handle_cast {:register works", %{agent: scene} do
    {:ok, agent_1} = Agent.start( fn -> 1 + 1 end )

    scene_ref = make_ref()
    registration = {scene, self(), agent_1}

    # register the scene
    Tables.handle_cast( {:register, scene_ref, registration}, @state )

    # it works with either scene_ref or graph
    assert Tables.get_scene_registration(scene_ref) == {:ok, registration}

    Agent.stop(agent_1)
  end

  test "handle_cast {:register starts monitoring the scene", %{agent: agent} do
    {:ok, scene} = Agent.start( fn -> 1 + 1 end )

    scene_ref = make_ref()
    registration = {scene, self(), agent}

    # register the scene
    Tables.handle_cast( {:register, scene_ref, registration}, @state )

    # stop the scene
    Agent.stop(scene)

    # this process should get a DOWN message
    assert_received( {:DOWN, _, :process, ^scene, _}  )
  end

  #============================================================================
  # handle_call( {:graph_subscribe, graph_key, pid}, state )

  test "handle_call {:graph_subscribe works", %{agent: agent} do
    graph_key = {:graph, make_ref(), 123}
    Tables.insert_graph( graph_key, self(), @graph, [1, 2])

    Tables.handle_call( {:graph_subscribe, graph_key, agent}, 123, @state )

    # confirm it was subscribed to
    assert Tables.list_subscriptions(agent) == [graph_key]
  end

  test "handle_call {:graph_subscribe does not create duplicate subscriptions",
  %{agent: agent} do
    graph_key = {:graph, make_ref(), 123}
    Tables.insert_graph( graph_key, agent, @graph, [1, 2])

    Tables.handle_call( {:graph_subscribe, graph_key, agent}, 123, @state )
    Tables.handle_call( {:graph_subscribe, graph_key, agent}, 123, @state )

    # confirm it was subscribed to
    assert Tables.list_subscriptions(agent) == [graph_key]
  end

  test "handle_call {:graph_subscribe starts monitoring the subscriber",
  %{agent: scene} do
    {:ok, subscriber} = Agent.start( fn -> 1 + 1 end )

    graph_key = {:graph, make_ref(), 123}
    Tables.insert_graph( graph_key, scene, @graph, [1, 2])

    Tables.handle_call( {:graph_subscribe, graph_key, subscriber}, 123, @state )

    # confirm it was monitored by stopping the agent and checking for the message
    Agent.stop(subscriber)

    # this process should get a DOWN message
    assert_received( {:DOWN, _, :process, ^subscriber, _}  )
  end

  #============================================================================
  # handle_cast( {:graph_subscribe, graph_key, pid}, state )

  test "handle_cast {:graph_subscribe works", %{agent: agent} do
    graph_key = {:graph, make_ref(), 123}
    Tables.insert_graph( graph_key, agent, @graph, [1, 2])

    Tables.handle_cast( {:graph_subscribe, graph_key, agent}, @state )

    # confirm it was subscribed to
    assert Tables.list_subscriptions(agent) == [graph_key]
  end

  test "handle_cast {:graph_subscribe does not create duplicate subscriptions",
  %{agent: agent} do
    graph_key = {:graph, make_ref(), 123}
    Tables.insert_graph( graph_key, agent, @graph, [1, 2])

    Tables.handle_cast( {:graph_subscribe, graph_key, agent}, @state )
    Tables.handle_cast( {:graph_subscribe, graph_key, agent}, @state )

    # confirm it was subscribed to
    assert Tables.list_subscriptions(agent) == [graph_key]
  end

  test "handle_cast {:graph_subscribe starts monitoring the subscriber",
  %{agent: scene} do
    {:ok, subscriber} = Agent.start( fn -> 1 + 1 end )

    graph_key = {:graph, make_ref(), 123}
    Tables.insert_graph( graph_key, scene, @graph, [1, 2])

    Tables.handle_cast( {:graph_subscribe, graph_key, subscriber}, @state )

    # confirm it was monitored by stopping the agent and checking for the message
    Agent.stop(subscriber)

    # this process should get a DOWN message
    assert_received( {:DOWN, _, :process, ^subscriber, _}  )
  end

  #============================================================================
  # handle_cast( {:graph_unsubscribe, _, pid}, state )

  test "handle_cast {:graph_unsubscribe, :graph_key works",
  %{agent: scene} do
    # setup
    {:ok, subscriber} = Agent.start( fn -> 1 + 1 end )
    graph_key_0 = {:graph, make_ref(), 123}
    graph_key_1 = {:graph, make_ref(), 123}
    Tables.insert_graph( graph_key_0, scene, @graph, [])
    Tables.insert_graph( graph_key_1, scene, @graph_1, [])
    Tables.handle_cast( {:graph_subscribe, graph_key_0, subscriber}, @state )
    Tables.handle_cast( {:graph_subscribe, graph_key_1, subscriber}, @state )

    # confirm setup
    [_, _] = Tables.list_subscriptions(subscriber)

    # unsubscribe
    Tables.handle_cast( {:graph_unsubscribe, graph_key_0, subscriber}, @state )

    # confirm unsubscription
    assert Tables.list_subscriptions(subscriber) == [graph_key_1]

    Agent.stop(subscriber)
  end

  test "handle_cast {:graph_unsubscribe, :all removes all",
  %{agent: scene} do
    # setup
    {:ok, subscriber} = Agent.start( fn -> 1 + 1 end )
    graph_key_0 = {:graph, make_ref(), 123}
    graph_key_1 = {:graph, make_ref(), 123}
    Tables.insert_graph( graph_key_0, scene, @graph, [])
    Tables.insert_graph( graph_key_1, scene, @graph_1, [])
    Tables.handle_cast( {:graph_subscribe, graph_key_0, subscriber}, @state )
    Tables.handle_cast( {:graph_subscribe, graph_key_1, subscriber}, @state )

    # confirm setup
    [_, _] = Tables.list_subscriptions(subscriber)

    # unsubscribe
    Tables.handle_cast( {:graph_unsubscribe, :all, subscriber}, @state )

    # confirm unsubscription
    assert Tables.list_subscriptions(subscriber) == []

    Agent.stop(subscriber)
  end

  test "handle_cast {:graph_unsubscribe, :graph_key de-monitors the subscriber"  do
    # set up the scene
    {:ok, scene} = Agent.start( fn -> 1 + 1 end )
    scene_ref = make_ref()
    registration = {scene, nil, nil}
    :ets.insert(@ets_scenes_table, {scene_ref, registration})

    # set up the graph
    graph_key = {:graph, scene_ref, 123}
    Tables.insert_graph( graph_key, scene, @graph, [1, 2])
    assert Tables.list_graphs() == [graph_key]

    # subscribe to the graph
    {:noreply, state} = Tables.handle_cast( {:graph_subscribe, graph_key, self()}, @state )

    # unsubscribe
    {:noreply, state} = Tables.handle_cast( {:graph_unsubscribe, graph_key, self()}, state )

    # process a fake a DOWN message
    Tables.handle_info( {:DOWN, make_ref(), :process, scene, :shutdown}, state )

    # should NOT get a DOWN messate
    refute_received( {:"$gen_cast", {:delete_graph, _}}  )

    Agent.stop(scene)
  end

  test "handle_cast {:graph_unsubscribe, :all de-monitors the subscriber"  do
    # set up the scene
    {:ok, scene} = Agent.start( fn -> 1 + 1 end )
    scene_ref = make_ref()
    registration = {scene, nil, nil}
    :ets.insert(@ets_scenes_table, {scene_ref, registration})

    # set up the graph
    graph_key = {:graph, scene_ref, 123}
    Tables.insert_graph( graph_key, scene, @graph, [1, 2])
    assert Tables.list_graphs() == [graph_key]

    # subscribe to the graph
    {:noreply, state} = Tables.handle_cast( {:graph_subscribe, graph_key, self()}, @state )

    # unsubscribe
    {:noreply, state} = Tables.handle_cast( {:graph_unsubscribe, :all, self()}, state )

    # process a fake a DOWN message
    Tables.handle_info( {:DOWN, make_ref(), :process, scene, :shutdown}, state )

    # should NOT get a DOWN messate
    refute_received( {:"$gen_cast", {:delete_graph, _}}  )

    Agent.stop(scene)
  end


end


































