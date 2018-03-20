#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort do
  use GenServer
  alias Scenic.ViewPort.Driver
  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitive
#  require Logger

  import IEx

  @viewport :viewport
  
  @dynamic_scenes   :dynamic_scenes

  @max_depth        64

  @root_graph       0

  # graph_uid_offset is the maximum number of items in a tree that any given
  # graph can have. If this is too high, then the number of merged graphs is too
  # low and vice versa.
#  @graph_uid_offset 96000

  #============================================================================
  # client api

  #--------------------------------------------------------
  @doc """
  Set a scene at the root of the viewport.

  If the scene is already running in a supervisor that you set up, then you can
  pass in that scene's name (an atom) or it's pid.

        set_scene( :my_supervised_scene )
        # or
        set_scene( my_supervised_scene_pid )

  If you are not already running the scene, you can also pass in its  module and 
  intialization data. This will spin up the scene as a temporary new process, then
  load it in to place. The next time you call set_scene, this process will be shut
  down and cleaned up.

        set_scene( {MyScenes.TemporaryScene, :init_data} )

  ## Parameters
  * `scene` The name, or PID or childspec of the scene.
  * `scene_param` Data to be passed to the scene's focus_gained function. Note that
  this is different from the initialization data.
  """
  def set_scene( scene, scene_param \\ nil, viewport \\ @viewport )

  def set_scene( scene, scene_param, vp ) when is_atom(scene) do
    Process.whereis(scene)
    |> set_scene( scene_param, vp )
  end

  def set_scene( scene, scene_param, vp ) when is_pid(scene) do
    GenServer.cast( vp, {:set_scene, scene, scene_param} )
  end

  #--------------------------------------------------------
  @doc """
  Set (or reset) a graph into the viewport. This does NOT make it the root graph
  It will be used if/when the root graph refers to it.

  If this is the root graph setting itself into place, the scene_pid must be the
  pid of the scene that was set via set_scene and the optional id must be nil
  """
  def set_graph( graph, id, scene \\ nil, viewport \\ @viewport )

  def set_graph( graph, id, nil, vp ) do
    set_graph( graph, id, self(), vp )
  end

  def set_graph( graph, id, scene, vp ) when is_atom(scene) do
    set_graph( graph, id, Process.whereis(scene), vp )
  end

  def set_graph( %Graph{primitive_map: p_map}, id, scene, vp ) do
    # prepare the minimal graph that the viewport will use
    Enum.reduce(p_map, %{}, fn({uid, p}, acc) ->
      Map.put(acc, uid, Primitive.minimal(p))
    end)
    |> set_graph( id, scene, vp )  
  end

  def set_graph( %{} = min_graph, id, scene, vp ) when is_pid(scene) do
    GenServer.cast( vp, {:set_graph, min_graph, scene, id} )
  end


  #--------------------------------------------------------
  @doc """
  Update a graph that has already been set into the viewport. 
  """
  def update_graph( deltas, id, scene \\ nil, viewport \\ @viewport ) 

  def update_graph( deltas, id, nil, vp ) do
    update_graph( deltas, id, self(), vp )
  end

  def update_graph( deltas, id, scene, vp ) when is_atom(scene) do
    update_graph( deltas, id, Process.whereis(scene), vp )
  end

  def update_graph( %Graph{deltas: deltas}, id, scene_pid, vp ) do
    update_graph( deltas, id, scene_pid, vp )
  end

  def update_graph( deltas, id, scene, vp ) when is_list(deltas) and is_pid(scene) do
    GenServer.cast( vp, {:update_graph, deltas, scene, id} )
  end


  #--------------------------------------------------------
  @doc """
  Send an input event to the viewport for processing. This is typcally called
  by drivers that are generating input events.
  """
  def input( input_event, viewport \\ @viewport ) do
    GenServer.cast( viewport, {:input, input_event} )
  end



#  #----------------------------------------------
#  -doc """
#  Delete a graph that has already been set into the viewport. You cannot delete
#  the graph for the scene that was set via set_scene. To do that, call set_scene
#  again to point it to something new.
#  """
#  def delete_graph( scene_pid, id \\ nil ) do
#    GenServer.cast( @viewport, {:delete_graph, scene_pid, id} )
#  end

  # TEMPORARY
  def request_set( graph_id, to_pid \\ nil, viewport \\ @viewport )
  def request_set( graph_id, nil, vp ) do
    request_set( graph_id, self(), vp )
  end
  def request_set( graph_id, to_pid, vp ) when is_integer(graph_id) and is_pid(to_pid) do
    GenServer.cast( vp, {:request_set, graph_id, to_pid} )
  end


  #============================================================================
  # internal server api


  #--------------------------------------------------------
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @viewport)
  end

  #--------------------------------------------------------
  def init( opts ) do

    # set up the initial state
    state = %{
      graphs: %{},
      filter_list: [],
      graph_count: 0,
      graph_ids: %{},
      graph_keys: %{},
      max_depth: opts[:max_depth] || @max_depth
    }

    {:ok, state}
  end


  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  # set a scene to be the new root
  def handle_cast( {:set_scene, scene, scene_param}, state ) do

    # start by telling the previous scene that it has lost focus
    # done as a call to make sure the previous scene gets the message
    # if it is a dynamic scene, it might otherwise go down too quickly
    case get_graph_key( state, 0 ) do
      nil ->
        # no previous scene. do nothing
        :ok

      {previous_pid, nil} ->
        # don't actually care about the result.
        GenServer.call( previous_pid, :focus_lost )
    end


    # always recycle the dynamic scene supervisor when there is a new root scene
    DynamicSupervisor.which_children(@dynamic_scenes)
    |> Enum.each(fn({:undefined, pid, :worker, _}) ->
      :ok = DynamicSupervisor.terminate_child(@dynamic_scenes, pid)
    end)

    # get or start the pid for the new scene being set as the root
    scene_pid = case scene do
      {mod, opts}->
        {:ok, pid} = DynamicSupervisor.start_child(@dynamic_scenes, {Scene, {mod, opts}})
        pid

      name when is_atom(name) ->
        Process.whereis( name )

      pid when is_pid(pid) ->
        pid
    end

    # tell the new scene that it has gained focus
    GenServer.cast( scene_pid, {:focus_gained, scene_param} )
    graph_key = {scene_pid, nil}


    # record that this is the new current scene
    state = state
    # clear the graphs
    |> Map.put( :graphs, %{} )

    |> Map.put( :graph_ids, %{graph_key => @root_graph} )
    |> Map.put( :graph_keys, %{@root_graph => graph_key} )

    |> Map.put( :graph_count, 1 )
    # disable input as the new scene sets up
    |> Map.put( :filter_list, [] )

    # send a reset message to the drivers
    Driver.cast( :reset_scene )

    {:noreply, state}
  end

  #--------------------------------------------------------
  # set a graph into the master graph
  def handle_cast( {:set_graph, graph, scene, id}, state ) do

    # calc the graph_ikey
    graph_key = {scene, id}

    # set up the graph id
    state = set_graph_id( state, graph_key )

    # get the graph_id
    graph_id = get_graph_id( state, graph_key )

    # scan the graph, looking for SceneRef primitives. Convert those into graph_ids
    # also collect the scene keys in a list so to activate them next
    {graph, state, skl} = Enum.reduce(graph, {%{}, state, []}, fn({uid, p},{g, s,skl})->
      {p, {s,skl}} = case p do
        %{data: {Primitive.SceneRef, {scene, scene_id}}} ->
          # reolve (possibly starting) the referenced scene into a pid
          {:ok, pid} = ensure_screen_ref_started( scene )

          # this primitive is a scene_ref. Convert it into a graph_id
          s = set_graph_id( s, {pid, scene_id} )
          graph_id = get_graph_id( s, {pid, scene_id} )

          # transform the primitive so it references the local graph_id
          p = Map.put(p, :data, {Primitive.SceneRef, graph_id})
          
          # collect the scene key in a list
          skl = [{pid, scene_id} | skl]
          {p, {s,skl}}
        p ->
          # not a scene_ref
          {p, {s,skl}}
      end
      g = Map.put(g, uid, p)
      {g, s, skl}
    end)

    # tell any referenced scenes to set their graphs
    skl
    |> Enum.uniq()
    |> Enum.each(fn({pid, id})->
      GenServer.cast(pid, {:set_graph, id})
    end)

    state = state
    |> put_in([:graphs, graph_id], graph)
    |> update_filter_list()

    # send this graph to the drivers
    Driver.cast( {:set_graph, {graph_id, graph}} )

    {:noreply, state}
  end

  #--------------------------------------------------------
  # set a graph into the master graph

  def handle_cast( {:update_graph, delta_list, scene_pid, id}, state ) do
    # pass it off to the utility function. This gets the graph_id
    # now allowing the utility function to match on the graph_id
    # and do nothing if it is nil
    do_update_graph(
      delta_list,
      get_graph_id( state, {scene_pid, id} ),
      state
    )
  end


  #--------------------------------------------------------
  # set a graph into the master graph
  def handle_cast( {:request_set, graph_id, to_pid}, %{graphs: graphs} = state ) do
    
    case graphs[graph_id] do
      nil ->
        # no such graph. do nothing
        :ok

      graph ->
        # send it
        GenServer.cast(to_pid, {:set_graph, {graph_id, graph}})
    end

    {:noreply, state}
  end

  #--------------------------------------------------------
  # set a graph into the master graph
#  def handle_cast( {:delete_graph, scene_pid, id}, state ) do
#    {:noreply, state}
#  end


  #--------------------------------------------------------
  # filter the input through the list of scenes in order.
  # each scene will choose whether or not to transform the event and pass it along
  # to the next in the filter list, or to end the process.
  def handle_cast( {:input, _}, %{filter_list: []} = state ), do: {:noreply, state}
  def handle_cast( {:input, input_event}, %{filter_list: [head | tail]} = state ) do
#    GenServer.cast( head, {:filter_input, input_event, tail} )
    {:noreply, state}
  end


  #============================================================================
  # graph key <-> id utilities

  defp set_graph_id( %{graph_ids: ids, graph_count: count} = state, graph_key ) do
    # see if this key is already mapped
    case ids[graph_key] do
      nil ->
        # This is a new id. Set up the mappings
        state
        |> put_in( [:graph_ids, graph_key], count)
        |> put_in( [:graph_keys, count], graph_key)
        |> Map.put( :graph_count, count + 1 )

      _ ->
        # already set up
        state
    end
  end

  defp get_graph_id( %{graph_ids: ids}, graph_key ), do: ids[graph_key]
  defp get_graph_key( %{graph_keys: keys}, graph_id ), do: keys[graph_id]


  #============================================================================
  # utilities

  #--------------------------------------------------------
  # given a scene, make sure it is started and return the pid
  defp ensure_screen_ref_started( scene )

  defp ensure_screen_ref_started( scene ) when is_atom(scene) do
    case Process.whereis(scene) do
      nil ->
        {:error, :scene_not_found}
      pid ->
        {:ok, pid}
    end
  end

  defp ensure_screen_ref_started( scene ) when is_pid(scene) do
    {:ok, scene}
  end

  defp ensure_screen_ref_started( {mod, opts} ) when is_atom(mod) and not is_nil(mod) do
    DynamicSupervisor.start_child(@dynamic_scenes, {Scene, {mod, opts}})
  end

  #--------------------------------------------------------
  # failed to find the graph in question.
  defp do_update_graph( _, nil, _state ) do
    raise "attempted to update a graph that is not set into the viewport"
#    {:noreply, state}
  end

  defp do_update_graph( deltas, graph_id, %{graphs: graphs} = state ) do

    # scan the deltas_list, looking for any put scenerefs and transform
    # them so they use local ids. also build a list of the new scene refs
    # so they can be activated
    {deltas, {state,skl}} = Enum.map_reduce(deltas, {state, []}, fn({uid, d},{s,skl})->
      # a set of deltas for one primitive. map reduce those too
      {dl, {s,skl}} = Enum.map_reduce(d, {s, skl}, fn
        {:put, :data, {Primitive.SceneRef, {scene, scene_id}}}, {s, skl} ->
          # this is putting a new SceneRef in. Need to make sure it is running,
          # activated and such. just like during set_graph

          # reolve (possibly starting) the referenced scene into a pid
          {:ok, pid} = ensure_screen_ref_started( scene )

          # this primitive is a scene_ref. Convert it into a graph_id
          s = set_graph_id( s, {pid, scene_id} )
          graph_id = get_graph_id( s, {pid, scene_id} )

          # transform the deltas
          d = {:put, :data, {Primitive.SceneRef, graph_id}}

          # collect the scene key in a list and return
          skl = [graph_id | skl]
          {d,{s,skl}}

        d, acc ->
          # ok to leave it alone
          {d, acc}
      end)

      {{uid, dl},{s,skl}}
    end)

    # merge the deltas in to the stored graph
    graph = Enum.reduce(deltas, graphs[graph_id], fn({uid, dl},g) ->
      p = Map.get(g, uid, %{})
      |> Scenic.Utilities.Map.apply_difference(dl, true)
      Map.put(g, uid, p)
    end)
    state = put_in( state, [:graphs, graph_id], graph )

    # don't do duplicate work
    skl = Enum.uniq(skl)

    # tell any unset referenced scenes to set their graphs
    Enum.each(skl, fn(graph_id)->
      get_in(state, [:graphs, graph_id])
      |> case do
        nil ->
          #This graph is not already set. Tell the scene to set it
          # get the graph key
          {pid, scene_id } = get_graph_key(state, graph_id)
          GenServer.cast(pid, {:set_graph, scene_id})
        _ ->
          :ok
      end
    end)

    # rebuild the input list if necessary
    state = case skl do
      [] ->
        state
      _ ->
        update_filter_list(state)
    end

    # send the transformed delta list on to the drivers

  #----------------------------------------------
#  def update_graph( [], id ), do: :ok
#  def update_graph( deltas, id ) when is_list(deltas) and is_integer(id) do
#    dispatch_cast( {:update_graph, {id, deltas}} )
#  end

    {:noreply, state}
  end

  #--------------------------------------------------------
  # reset input filter list
  defp update_filter_list( state ) do
    state
  end

end
















