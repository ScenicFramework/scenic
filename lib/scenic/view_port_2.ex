#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort2 do
  use GenServer
#  alias Scenic.ViewPort.Driver
  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitive
#  require Logger

  import IEx

  @viewport :viewport
  
  @dynamic_scenes   :dynamic_scenes

  @max_depth        64


  # graph_uid_offset is the maximum number of items in a tree that any given
  # graph can have. If this is too high, then the number of merged graphs is too
  # low and vice versa.
  @graph_uid_offset 96000

  #============================================================================
  # client api

  #--------------------------------------------------------
  @doc """
  Send an input event to the viewport for processing. This is typcally called
  by drivers that are generating input events.
  """
  def input( input_event ), do: GenServer.cast( @viewport, {:input, input_event} )


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
  def set_graph( graph, scene, id \\ nil, viewport \\ @viewport )

  def set_graph( graph, scene, id, vp ) when is_atom(scene) do
    set_graph( graph, Process.whereis(scene), id, vp )
  end

  def set_graph( %Graph{primitive_map: p_map}, scene, id, vp ) do
    # prepare the minimal graph that the viewport will use
    Enum.reduce(p_map, %{}, fn({uid, p}, acc) ->
      Map.put(acc, uid, Primitive.minimal(p))
    end)
    |> set_graph( scene, id, vp )  
  end

  def set_graph( %{} = min_graph, scene, id, vp ) when is_pid(scene) do
    GenServer.cast( vp, {:set_graph, min_graph, scene, id} )
  end




  #--------------------------------------------------------
  @doc """
  Update a graph that has already been set into the viewport. 
  """
  def update_graph( graph, scene, id \\ nil, viewport \\ @viewport ) 

  def update_graph( graph, scene, id, vp ) when is_atom(scene) do
    update_graph( graph, Process.whereis(scene), id, vp )
  end

  def update_graph( %Graph{deltas: deltas}, scene_pid, id, vp ) do
    update_graph( deltas, scene_pid, id, vp )
  end

  def update_graph( deltas, scene, id, vp ) when is_list(deltas) and is_pid(scene) do
    GenServer.cast( vp, {:update_graph, deltas, scene, id} )
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
  def request_set(), do: Scenic.ViewPort.request_set()


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
      root_scene: nil,
      graphs: %{},
      offsets: %{},
      filter_list: [],
      graph_count: 0,
      max_depth: opts[:max_depth] || @max_depth
    }

    {:ok, state}
  end


  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  # set a scene to be the new root
  def handle_cast( {:set_scene, scene, scene_param}, state ) do

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

    # tell the scene it is now the root
    GenServer.cast( scene_pid, {:set_graph, nil} )
    graph_id = {scene_pid, nil}

    # record that this is the new current scene
    state = state
    |> Map.put( :root_scene, graph_id )
    # clear the graphs
    |> Map.put( :graphs, %{} )
    |> Map.put( :offsets, %{graph_id => 0} )
    |> Map.put( :graph_count, 1 )
    # disable input as the new scene sets up
    |> Map.put( :filter_list, [] )

    {:noreply, state}
  end

  #--------------------------------------------------------
  # set a graph into the master graph
  def handle_cast( {:set_graph, min_graph, scene_pid, id},
  %{ graphs: graphs, graph_count: graph_count } = state ) do

    # calc the graph_id
    graph_id = {scene_pid, id}

    # get the graph_id offset
    {uid_offset, state} = get_offset( graph_id, state )

    # offset the uids in the min_graph and collect any scene refs
    {min_graph, scene_ref_list} = Enum.reduce(min_graph, {%{},[]}, fn({uid, p},{g,srl})->
      p = ingest_primitive( p, uid_offset, graphs )

      # if the primitive is a SceneRef, collect it in the srl list
      srl = case p do
        %{data: {Primitive.SceneRef, {pid, id}}} ->
          [{pid, id} | srl]
        _ ->
          srl
      end

      # insert the primitive into the offset graph
      {Map.put( g, uid + uid_offset, p ), srl}
    end)

    # tell any referenced scenes to set their graphs
    scene_ref_list
    |> Enum.uniq()
    |> Enum.each(fn({pid, id})->
      GenServer.cast(pid, {:set_graph, id})
    end)

    # add the min_graph to the graphs map
    graphs = Map.put(graphs, graph_id, min_graph)

    state = state
    |> Map.put( :graphs, graphs )
    |> update_filter_list()

    {:noreply, state}
  end

  #--------------------------------------------------------
  # set a graph into the master graph
#  def handle_cast( {:update_graph, delta_list, scene_pid, id}, state ) do
#    # calc the graph_id
#    graph_id = {scene_pid, id}
#
#    # get the offset for this graph
#    {uid_offset, state} = get_offset( graph_id, state )
#
#    # offset the delta_list space
#
#

    # make sure the graph is in the map. if it isn't, do nothing.
#    case graphs[graph_id] do
#      nil ->
#        # do nothing
#        {:noreply, state}
#
#      {uid_offset, graph} ->
#        # the graph is set.
#        # merge the deltas into the master list.
#        {graph, update_input} = Enum.reduce(delta_list, {graph, false},
#        fn({uid, deltas}, {g, inpt})->
#          # offset the uid from the delta
#          uid = uid + uid_offset
#
#          # get the primitive we are updating
#          p = Map.get(g, uid, %{})
#
#          # merge in the deltas
#
#          # put the updated primitive back
#
#        end)
#
#    end
#  end

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
    GenServer.cast( head, {:filter_input, input_event, tail} )
    {:noreply, state}
  end


  #============================================================================
  # utilities

  #--------------------------------------------------------
  # ingest a SceneRef - to be called from set_graph

  defp ingest_primitive( %{data: {Primitive.SceneRef, {{mod, opts}, id}}} = p, uid_offset, graphs )
  when is_atom(mod) and not is_nil(mod) do
    {:ok, pid} = DynamicSupervisor.start_child(@dynamic_scenes, {Scene, {mod, opts}})
    Map.put(p, :data, {Primitive.SceneRef, {pid, id}})
  end

  defp ingest_primitive( %{data: {Primitive.SceneRef, {name, id}}} = p, uid_offset, graphs )
  when is_atom(name) and not is_nil(name) do
    pid = Process.whereis(name)
    Map.put(p, :data, {Primitive.SceneRef, {pid, id}})
  end

  # ingest a Group
  defp ingest_primitive( %{data: {Primitive.Group, ids}} = p, uid_offset, _ ) do
    # offset all the ids
    ids = Enum.map(ids, &(&1 + uid_offset))
    Map.put(p, :data, {Primitive.Group, ids})
  end

  # mainline ingestion. Offset the puid
  defp ingest_primitive( p, _a, _b ) do
    p
  end
#  defp ingest_primitive( %{puid: puid} = p, uid_offset, _ ) do
#    Map.put(p, :puid, puid + uid_offset)
#  end


  #--------------------------------------------------------
#May need to just diff the whole primitive map. might be simpler...



#  defp offset_delta_list(delta_list, uid_offset) do
#    Enum.map(delta_list, fn({uid, deltas})->
#      uid = uid + uid_offset
#
#      deltas = Enum.map(deltas, fn
#        {:put, where, what} ->
#          case where do
#            :puid ->
#              { :put, :puid, offset_puid(what, remote_group_uid) }
#            :data ->
#              { :put, :data, offset_data(what, uid_offset) }
#            _ ->
#              {:put, where, what}
#          end
#        delta ->
#          delta
#      end)
#      { uid, deltas }
#    end)
#  end
#
#  defp offset_delta_puid( -1, remote_group_uid ), do: remote_group_uid
#  defp offset_delta_puid( puid, _ ), do: puid + @graph_uid_offset
#
#  defp offset_delta_data( {Scenic.Primitive.Group, ids}, uid_offset ) do
#    {
#      Scenic.Primitive.Group,
#      Enum.map(ids, fn(id) -> id + uid_offset end)
#    }
#  end
#  defp offset_delta_data( data, _ ), do: data




  #--------------------------------------------------------
  # get (or generate) an offset for a graph
  defp get_offset( graph_id,
  %{offsets: offsets, graph_count: graph_count} = state ) do
    # if the graph_id not in the map, then gen an offset and add it
    case offsets[graph_id] do
      nil ->
        uid_offset = @graph_uid_offset * graph_count
        state = state
        |> put_in([:offsets, graph_id], uid_offset)
        |> Map.put( :graph_count, graph_count + 1 )
        {uid_offset, state}

      uid_offset ->
        # already set. do nothing
        {uid_offset, state}
    end
  end

  #--------------------------------------------------------
  # reset input filter list
  defp update_filter_list( %{root_scene: nil} = state ), do: state
  defp update_filter_list( %{root_scene: root_scene} = state ) do
    # start with the current scene.
    filter_list = [root_scene]

    # put the filter_list into place
    {:noreply, %{state | filter_list: filter_list} }
  end

end
















