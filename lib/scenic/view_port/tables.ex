#
#  Created by Boyd Multerer on 04/13/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# Refactoring the graph and Scene ETS tables into a seperate genserver
# whose whole purpose is to manage them. This will make future support
# for multiple, parallel viewports much easier. Even when there are
# multiple viewports, they would still share the same graphs table and
# scene registrations.

defmodule Scenic.ViewPort.Tables do
  use GenServer

 # import IEx

  # ets table names
  @ets_subs_table       :_scenic_subs_table_
  @ets_graphs_table     :_scenic_graphs_table_
  @ets_scenes_table     :_scenic_scenes_table_

  @name                 __MODULE__

  #============================================================================
  # external client api

  #--------------------------------------------------------
  # helpers so that other modules can get the name graphs during compile time

  @doc false
  def graphs_table(), do: @ets_graphs_table

  @doc false
  def scenes_table(), do: @ets_scenes_table


  #--------------------------------------------------------
  def register_scene( scene_ref, {pid,_,_} = registration ) when is_pid(pid) do
    GenServer.cast(@name, {:register, scene_ref, registration})
  end

  #--------------------------------------------------------
  def get_scene_pid( scene_or_graph_key ) do
    with {:ok, {pid,_,_}} <- get_scene_registration( scene_or_graph_key ) do
      {:ok, pid}
    end
  end

  #--------------------------------------------------------
  def get_scene_registration( scene_or_graph_key )
  def get_scene_registration( {:graph, scene, _} ), do: get_scene_pid( scene )
  def get_scene_registration( scene ) when is_atom(scene) or is_reference(scene) do
    case :ets.lookup(@ets_scenes_table, scene ) do
      [{_,registration}] -> {:ok, registration}
      [] -> {:error, :not_found}
    end
  end

  #--------------------------------------------------------
  def insert_graph( graph_key, scene_pid, graph, refs)

  def insert_graph( graph_key, scene, graph, refs) when is_atom(scene) do
    case Process.whereis( scene ) do
      nil -> {:error, :invalid_scene}
      pid -> insert_graph( pid, graph_key, graph, refs)
    end
  end

  def insert_graph( graph_key, scene_pid, graph, refs) when is_pid(scene_pid) do
    :ets.insert(@ets_graphs_table, {graph_key, scene_pid, graph, refs})

    # let any subscribing listeners know the graph was updated
    graph_key
    |> list_subscribers()
    |> Enum.each( &GenServer.cast(&1, {:update_graph, graph_key}) )
  end

  #--------------------------------------------------------
  def get_graph( {:graph,scene,_} = graph_key ) when is_atom(scene) or is_reference(scene) do
    case :ets.lookup(@ets_graphs_table, graph_key) do
      [] -> nil
      [{_, _, graph, _}] -> {:ok, graph}
    end
  end
  def get_graph( _ ), do: {:error, :invalid_graph_key}

  #--------------------------------------------------------
  def delete_graph( {:graph,scene,_} = graph_key ) when is_atom(scene) or is_reference(scene) do
    :ets.delete(@ets_graphs_table, graph_key)
      # tell the subscribers the key is went away
      list_subscribers(graph_key)
      |> Enum.each( &GenServer.cast(&1, {:delete_graph, graph_key}) )
  end
  def delete_graph( _ ), do: {:error, :invalid_graph_key}


  #--------------------------------------------------------
  def get_refs( {:graph,scene,_} = graph_key ) when is_atom(scene) or is_reference(scene) do
    case :ets.lookup(@ets_graphs_table, graph_key) do
      [] -> nil
      [{_, _, _, refs}] -> {:ok, refs}
    end
  end
  def get_refs( _ ), do: {:error, :invalid_graph_key}

  #--------------------------------------------------------
  def get_graph_refs( {:graph,scene,_} = graph_key ) when is_atom(scene) or is_reference(scene) do
    case :ets.lookup(@ets_graphs_table, graph_key) do
      [] -> nil
      [{_, _, graph, refs}] -> {:ok, graph, refs}
    end
  end
  def get_graph_refs( _ ), do: {:error, :invalid_graph_key}


  #--------------------------------------------------------
  # return a list of all the graph keys that have been pushed by a scene
  def list_graphs() do
    :ets.match(@ets_graphs_table, {:"$1", :"_", :"_", :"_"})
    |> List.flatten()
  end

  #--------------------------------------------------------
  # return a list of all the graph keys that have been pushed by a scene
  def list_graphs_for_scene( scene ) when is_atom(scene) or is_reference(scene) do
    :ets.match(@ets_graphs_table, {{:graph, scene, :"$1"}, :"_", :"_", :"_"})
    |> List.flatten()
    |> Enum.map( fn(sub_id) -> {:graph, scene, sub_id} end)
  end


  #--------------------------------------------------------
  def subscribe( graph_key, pid ) do
#    GenServer.cast( @name, {:graph_subscribe, graph_key, pid} )
    GenServer.call( @name, {:graph_subscribe, graph_key, pid} )
  end

  #--------------------------------------------------------
  def unsubscribe( graph_key, pid ) do
    GenServer.cast( @name, {:graph_unsubscribe, graph_key, pid} )
  end

  #============================================================================
  # internal server api


  #--------------------------------------------------------
  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end


  #--------------------------------------------------------
  @doc false
  def init( :ok ) do

    # set up the initial state
    state = %{
      graph_table_id: :ets.new(@ets_graphs_table, [:named_table, :public, {:read_concurrency, true}]),
      scene_table_id: :ets.new(@ets_scenes_table, [:named_table]),
      subs_table_id: :ets.new(@ets_subs_table, [:named_table, :bag])
    }

    {:ok, state}
  end

  #============================================================================
  # handle_info

  # when a scene shuts down, we need to clean up the tables
  def handle_info({:DOWN, _monitor_ref, :process, pid, :shutdown}, state) do
    # delete any graphs that had been set by this pid
    pid
    |> list_graphs_for_scene_pid()
    |> Enum.each( fn(graph_key) ->
      # tell the subscribers the key is going away
      list_subscribers(graph_key)
      |> Enum.each( fn(sub) ->
        GenServer.cast(sub, {:delete_graph, graph_key} )
        unsubscribe(graph_key, sub )
      end)

      # delete the entry
      :ets.delete( @ets_graphs_table, graph_key )
    end)

    # unregister the scene itself
    with {:ok, scene_ref} <- pid_to_scene( pid ) do
      :ets.delete(@ets_scenes_table, scene_ref)
    end

    {:noreply, state}
  end

  # if the scene crashed - let the supervisor do its thing
  def handle_info({:DOWN,_,:process,_,_}=msg, state), do: {:noreply, state}



  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  def handle_cast( {:register, scene_ref, {pid,_,_} = registration}, state ) do
    :ets.insert(@ets_scenes_table, {scene_ref, registration})
    # start monitoring the scene
    Process.monitor( pid )
    {:noreply, state}
  end


  #--------------------------------------------------------
  def handle_cast( {:graph_subscribe, graph_key, pid}, state ) do
    :ets.insert(@ets_subs_table, {graph_key, pid})
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast( {:graph_unsubscribe, :all, pid}, state ) do
    :ets.match_delete(@ets_subs_table, {:"_", pid}) 
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast( {:graph_unsubscribe, graph_key, pid}, state ) do
    # delete all the specific subscription
    :ets.match_delete(@ets_subs_table, {graph_key, pid}) 
    {:noreply, state}
  end


  #============================================================================
  # internal utilities

  #--------------------------------------------------------
  def handle_call( {:graph_subscribe, graph_key, pid}, _, state ) do
    resp = :ets.insert(@ets_subs_table, {graph_key, pid})
    {:reply, resp, state}
  end



  #============================================================================
  # internal utilities

  #--------------------------------------------------------
  defp pid_to_scene( pid ) do
    case :ets.match(@ets_scenes_table, {:"$1", {pid,:"_",:"_"}}) do
      [[scene_ref]] -> {:ok, scene_ref}
      _ -> {:error, :not_found}
    end
  end


  #--------------------------------------------------------
  # return a list of all the graph keys that have been pushed by a scene
  defp list_graphs_for_scene_pid( pid ) do
    :ets.match(@ets_graphs_table, {:"$1", pid, :"_", :"_"})
    |> List.flatten()
  end


  #--------------------------------------------------------
  def list_subscriptions( pid ) when is_pid(pid) do
    :ets.match(@ets_subs_table, {:"$1", pid})
    |> List.flatten()
  end

  #--------------------------------------------------------
  defp list_subscribers( {:graph,_,_} = graph_key ) do
    :ets.lookup(@ets_subs_table, graph_key)
    |> Enum.map( fn({_,sub})-> sub end)
  end


end

