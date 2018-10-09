#
#  Created by Boyd Multerer on 2018-04-13.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Tables do
  @moduledoc """
  The Tables processes is a critical piece of Scenic.
  It caches the graphs that have been pushed by the various scenes.
  """

  use GenServer
  alias Scenic.Utilities

  # import IEx

  # ets table names
  @ets_subs_table :_scenic_subs_table_
  @ets_graphs_table :_scenic_graphs_table_
  @ets_scenes_table :_scenic_scenes_table_

  @name __MODULE__

  # ============================================================================
  # external client api

  # --------------------------------------------------------
  # helpers so that other modules can get the name graphs during compile time

  @doc false
  def graphs_table(), do: @ets_graphs_table

  @doc false
  def scenes_table(), do: @ets_scenes_table

  @doc false
  def subs_table(), do: @ets_subs_table

  # --------------------------------------------------------
  @doc false
  # internal function. Called from within a scene's internal init processes
  def register_scene(scene_ref, {pid, _, _} = registration) when is_pid(pid) do
    GenServer.cast(@name, {:register, scene_ref, registration})
  end

  # --------------------------------------------------------
  @doc false
  # internal function. Called from within a scene's internal init processes
  def get_scene_pid(scene_or_graph_key) do
    with {:ok, {pid, _, _}} <- get_scene_registration(scene_or_graph_key) do
      {:ok, pid}
    else
      _ -> {:error, :not_found}
    end
  end

  # --------------------------------------------------------
  defp get_scene_registration(scene_or_graph_key)
  defp get_scene_registration({:graph, scene, _}), do: get_scene_registration(scene)

  defp get_scene_registration(scene) when is_atom(scene) or is_reference(scene) do
    case :ets.lookup(@ets_scenes_table, scene) do
      [{_, registration}] -> {:ok, registration}
      [] -> {:error, :not_found}
    end
  end

  # --------------------------------------------------------
  def insert_graph(graph_key, scene_pid, graph, refs)

  def insert_graph(graph_key, scene, graph, refs) when is_atom(scene) do
    case Process.whereis(scene) do
      nil -> {:error, :invalid_scene}
      pid -> insert_graph(graph_key, pid, graph, refs)
    end
  end

  def insert_graph(graph_key, scene, graph, refs) when is_pid(scene) do
    send(@name, {:insert_graph, graph_key, scene, graph, refs})
  end

  # --------------------------------------------------------
  def get_graph({:graph, scene, _} = graph_key)
      when is_atom(scene) or is_reference(scene) do
    case :ets.lookup(@ets_graphs_table, graph_key) do
      [] -> nil
      [{_, _, graph, _}] -> {:ok, graph}
    end
  end

  def get_graph(_), do: {:error, :invalid_graph_key}

  # --------------------------------------------------------
  def delete_graph({:graph, scene, _} = graph_key)
      when is_atom(scene) or is_reference(scene) do
    send(@name, {:delete_graph, graph_key})
  end

  def delete_graph(_), do: {:error, :invalid_graph_key}

  # --------------------------------------------------------
  def get_refs({:graph, scene, _} = graph_key)
      when is_atom(scene) or is_reference(scene) do
    case :ets.lookup(@ets_graphs_table, graph_key) do
      [] -> nil
      [{_, _, _, refs}] -> {:ok, refs}
    end
  end

  def get_refs(_), do: {:error, :invalid_graph_key}

  # --------------------------------------------------------
  def get_graph_refs({:graph, scene, _} = graph_key)
      when is_atom(scene) or is_reference(scene) do
    case :ets.lookup(@ets_graphs_table, graph_key) do
      [] -> nil
      [{_, _, graph, refs}] -> {:ok, graph, refs}
    end
  end

  def get_graph_refs(_), do: {:error, :invalid_graph_key}

  # #--------------------------------------------------------
  # # return a list of all the graph keys
  # def list_graphs() do
  #   :ets.match(@ets_graphs_table, {:"$1", :_, :_, :_})
  #   |> List.flatten()
  # end

  # --------------------------------------------------------
  # return a list of all the graph keys that have been pushed by a scene
  # defp list_graphs_for_scene( scene ) when is_atom(scene) or is_reference(scene) do
  #   :ets.match(@ets_graphs_table, {{:graph, scene, :"$1"}, :_, :_, :_})
  #   |> List.flatten()
  #   |> Enum.map( fn(sub_id) -> {:graph, scene, sub_id} end)
  # end

  # --------------------------------------------------------
  def subscribe(graph_key, pid) do
    #    GenServer.cast( @name, {:graph_subscribe, graph_key, pid} )
    GenServer.call(@name, {:graph_subscribe, graph_key, pid})
  end

  # --------------------------------------------------------
  def unsubscribe(graph_key, pid) do
    GenServer.cast(@name, {:graph_unsubscribe, graph_key, pid})
  end

  # #--------------------------------------------------------
  # def list_subscriptions( pid ) when is_pid(pid) do
  #   :ets.match(@ets_subs_table, {:"$1", pid})
  #   |> List.flatten()
  # end

  # ============================================================================
  # internal server api

  # --------------------------------------------------------
  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  # --------------------------------------------------------
  @doc false
  def init(:ok) do
    # set up the initial state
    state = %{
      graph_table_id:
        :ets.new(
          @ets_graphs_table,
          [:named_table, {:read_concurrency, true}]
        ),
      scene_table_id: :ets.new(@ets_scenes_table, [:named_table]),
      subs_table_id: :ets.new(@ets_subs_table, [:named_table, :bag]),
      sub_monitors: %{}
    }

    {:ok, state}
  end

  # ============================================================================
  # handle_info

  # when a scene shuts down, we need to clean up the tables
  def handle_info({:DOWN, _monitor_ref, :process, pid, :shutdown}, state) do
    # clean up any subscriptions
    {:noreply, state} = handle_cast({:graph_unsubscribe, :all, pid}, state)

    # delete any graphs that had been set by this pid
    pid
    |> list_graphs_for_scene_pid()
    |> Enum.each(fn graph_key ->
      list_subscribers(graph_key)
      |> Enum.each(fn sub ->
        # tell the subscribers the key is going away
        GenServer.cast(sub, {:delete_graph, graph_key})
        # unsubscribe any listeners
        :ets.match_delete(@ets_subs_table, {graph_key, :_})
      end)

      # delete the entry
      :ets.delete(@ets_graphs_table, graph_key)
    end)

    # unregister the scene itself
    with {:ok, scene_ref} <- pid_to_scene(pid) do
      :ets.delete(@ets_scenes_table, scene_ref)
    end

    {:noreply, state}
  end

  # if the scene crashed - let the supervisor do its thing
  def handle_info({:DOWN, _, :process, pid, _}, state) do
    # clean up any subscriptions
    handle_cast({:graph_unsubscribe, :all, pid}, state)
  end

  # --------------------------------------------------------
  def handle_info({:insert_graph, graph_key, scene, graph, refs}, state) do
    :ets.insert(@ets_graphs_table, {graph_key, scene, graph, refs})

    # let any subscribing listeners know the graph was updated
    graph_key
    |> list_subscribers()
    |> Enum.each(&GenServer.cast(&1, {:update_graph, graph_key}))

    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_info({:delete_graph, graph_key}, state) do
    state =
      list_subscribers(graph_key)
      |> Enum.reduce(state, fn subscriber, s ->
        # tell the subscribers the graph went away
        GenServer.cast(subscriber, {:delete_graph, graph_key})
        # delete the subscription - must be done from Table process
        do_graph_unsubscribe(graph_key, subscriber, s)
      end)

    :ets.delete(@ets_graphs_table, graph_key)
    {:noreply, state}
  end

  # ============================================================================
  # handle_cast

  # --------------------------------------------------------
  def handle_cast({:register, scene_ref, {pid, _, _} = registration}, state) do
    :ets.insert(@ets_scenes_table, {scene_ref, registration})
    # start monitoring the scene
    Process.monitor(pid)
    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_cast({:graph_subscribe, graph_key, pid}, state) do
    :ets.insert(@ets_subs_table, {graph_key, pid})
    {:noreply, monitor_subscriber(pid, graph_key, state)}
  end

  # --------------------------------------------------------
  def handle_cast({:graph_unsubscribe, graph_key, pid}, state) do
    state = do_graph_unsubscribe(graph_key, pid, state)
    {:noreply, state}
  end

  # ============================================================================
  # internal utilities

  # --------------------------------------------------------
  def handle_call({:graph_subscribe, graph_key, pid}, _, state) do
    resp = :ets.insert(@ets_subs_table, {graph_key, pid})
    {:reply, resp, monitor_subscriber(pid, graph_key, state)}
  end

  # --------------------------------------------------------
  defp pid_to_scene(pid) do
    case :ets.match(@ets_scenes_table, {:"$1", {pid, :_, :_}}) do
      [[scene_ref]] -> {:ok, scene_ref}
      _ -> {:error, :not_found}
    end
  end

  # --------------------------------------------------------
  # return a list of all the graph keys that have been pushed by a scene
  defp list_graphs_for_scene_pid(pid) do
    :ets.match(@ets_graphs_table, {:"$1", pid, :_, :_})
    |> List.flatten()
  end

  # --------------------------------------------------------
  defp list_subscribers({:graph, _, _} = graph_key) do
    :ets.lookup(@ets_subs_table, graph_key)
    |> Enum.map(fn {_, sub} -> sub end)
  end

  # ============================================================================
  # internal monitor subscriber helpers
  # somewhat complicated as a listener can subscribe to more than one graph.
  # not globally accessed, so can be in local state

  # --------------------------------------------------------
  defp monitor_subscriber(sub, graph_key, %{sub_monitors: sub_monitors} = state) do
    case sub_monitors[sub] do
      nil ->
        # first-time subscription
        ref = Process.monitor(sub)
        put_in(state, [:sub_monitors, sub], {ref, [graph_key]})

      {ref, keys} ->
        # already monitoring something
        keys =
          [graph_key | keys]
          |> Enum.uniq()

        put_in(state, [:sub_monitors, sub], {ref, keys})
    end
  end

  # --------------------------------------------------------
  # demonitor :all is a nice shortcut. It is not longer monitoring any graphs...
  defp demonitor_subscriber(sub, :all, %{sub_monitors: sub_monitors} = state) do
    case sub_monitors[sub] do
      nil ->
        # not subscribed. do nothing
        state

      {ref, _} ->
        # don't care about the keys.
        Process.demonitor(ref)
        Utilities.Map.delete_in(state, [:sub_monitors, sub])
    end
  end

  # demonitor based on a single going away graph_key
  defp demonitor_subscriber(sub, graph_key, %{sub_monitors: sub_monitors} = state) do
    case sub_monitors[sub] do
      nil ->
        # not subscribed. do nothing
        state

      {ref, keys} ->
        # is subscribed so something. Remove the graph_key
        keys = Enum.reject(keys, fn key -> key == graph_key end)

        case keys do
          [] ->
            # totally unsubscribed
            Process.demonitor(ref)
            Utilities.Map.delete_in(state, [:sub_monitors, sub])

          keys ->
            # save the updated list
            put_in(state, [:sub_monitors, sub], {ref, keys})
        end
    end
  end

  # --------------------------------------------------------
  defp do_graph_unsubscribe(:all, pid, state) do
    # delete all the subscriptions
    :ets.match_delete(@ets_subs_table, {:_, pid})
    demonitor_subscriber(pid, :all, state)
  end

  defp do_graph_unsubscribe(graph_key, pid, state) do
    # delete the specific subscription
    :ets.match_delete(@ets_subs_table, {graph_key, pid})
    demonitor_subscriber(pid, graph_key, state)
  end
end
