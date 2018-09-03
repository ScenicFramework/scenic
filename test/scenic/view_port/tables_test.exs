#
#  Created by Boyd Multerer on August 22, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

#==============================================================================
defmodule Scenic.ViewPort.TablesTest do
  use ExUnit.Case, async: false
  doctest Scenic.ViewPort.Tables

  alias Scenic.Graph
  alias Scenic.ViewPort.Tables
  import Scenic.Primitives

  # ets table names
  @ets_graphs_table     :_scenic_graphs_table_

  @graph    Graph.build()
    |> text( "Main Graph" )

  @graph_1  Graph.build()
    |> text( "Second Graph" )


  #--------------------------------------------------------
  setup do
    {:ok, svc} = Tables.start_link( nil )
    on_exit fn -> Process.exit( svc, :normal ) end
    %{svc: svc}
  end

  #============================================================================
  # integration style tests


  test "integration style test" do
    {:ok, agent_0} = Agent.start(fn -> 1 + 1 end)
    {:ok, agent_1} = Agent.start( fn -> 1 + 1 end )

    scene_ref = make_ref()
    graph_key = {:graph, scene_ref, 123}
    registration = {self(), agent_0, agent_1}

    # register
    Tables.register_scene(scene_ref, registration)
    Process.sleep(100)  # is an async cast, so sleep to let it run

    # confirm the registration by checking the scene
    assert Tables.get_scene_pid(scene_ref) == {:ok, self()}
    assert Tables.get_scene_pid(graph_key) == {:ok, self()}

    # insert a graph
    Tables.insert_graph(graph_key, self(), @graph, [])
    # not subscribed, so confirm no event received - also gives it time to process
    refute_receive( {:"$gen_cast", {:update_graph, {:graph, ^scene_ref, 123}}} )
    assert :ets.lookup(@ets_graphs_table, graph_key) == [{graph_key, self(), @graph, []}]
    assert Tables.get_graph(graph_key) == {:ok, @graph}
    assert Tables.get_refs(graph_key) == {:ok, []}
    assert Tables.get_graph_refs(graph_key) == {:ok, @graph, []}

    # subscribe to the graph_key
    Tables.subscribe(graph_key, self())

    # udpate the graph
    Tables.insert_graph(graph_key, self(), @graph_1, [])
    # subscribed. confirm event received - also gives it time to process
    assert_receive( {:"$gen_cast", {:update_graph, {:graph, ^scene_ref, 123}}} )
    assert :ets.lookup(@ets_graphs_table, graph_key) == [{graph_key, self(), @graph_1, []}]
    assert Tables.get_graph(graph_key) == {:ok, @graph_1}

    # unsubscribe to the graph_key
    Tables.unsubscribe(graph_key, self())

    # confirm unsubscription
    Tables.insert_graph(graph_key, self(), @graph, [])
    # not subscribed, so confirm no event received - also gives it time to process
    refute_receive( {:"$gen_cast", {:update_graph, {:graph, ^scene_ref, 123}}} )
    assert :ets.lookup(@ets_graphs_table, graph_key) == [{graph_key, self(), @graph, []}]


    # subscribe to the graph_key again
    Tables.subscribe(graph_key, self())

    # udpate the graph
    Tables.insert_graph(graph_key, self(), @graph_1, [])
    # subscribed. confirm event received - also gives it time to process
    assert_receive( {:"$gen_cast", {:update_graph, {:graph, ^scene_ref, 123}}} )
    assert :ets.lookup(@ets_graphs_table, graph_key) == [{graph_key, self(), @graph_1, []}]
    assert Tables.get_graph(graph_key) == {:ok, @graph_1}

    # delete the graph
    Tables.delete_graph( graph_key )
    assert_receive( {:"$gen_cast", {:delete_graph, {:graph, ^scene_ref, 123}}} )
    assert :ets.lookup(@ets_graphs_table, graph_key) == []
    assert Tables.get_graph(graph_key) == nil


    Agent.stop(agent_0)
    Agent.stop(agent_1)
  end

end