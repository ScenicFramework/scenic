#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort do
  use GenServer
  alias Scenic.ViewPort
  alias Scenic.Scene
  alias Scenic.Utilities
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort.Input.Context
  require Logger

  import IEx

  @viewport :viewport
  
  @dynamic_scenes   :dynamic_scenes

  @max_depth        256

  @root_graph       0


  @ets_scenes_table       :_scenic_viewport_scenes_table_
  @ets_graphs_table       :_scenic_viewport_graphs_table_
  @ets_activation_table   :_scenic_viewport_activation_table_
#  @ets_startup_table      :_scenic_viewport_startup_table_


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
  def set_scene( scene_ref, args \\ nil )

  def set_scene( scene_ref, args ) when is_atom(scene_ref) do
    GenServer.cast( @viewport, {:set_scene, scene_ref, args} )
  end

  def set_scene( {mod, init_data}, args ) when is_atom(mod) do
    GenServer.cast( @viewport, {:set_scene, {mod, init_data}, args} )
  end

  #--------------------------------------------------------
  def register_scene( %Scene.Registration{} = registration ) do
    scene_ref = case Process.get(:scene_ref) do
      nil ->
        raise "Scenic.ViewPort.register_scene can only be called from with in a Scene"
      ref ->
        ref
    end
    :ets.insert(@ets_scenes_table, {scene_ref, registration})
    GenServer.cast(@viewport, {:monitor_scene, self()})
  end

  #--------------------------------------------------------
  def register_activation( scene_ref, args ) do
    GenServer.cast(@viewport, {:register_activation, scene_ref, args})
  end


  #--------------------------------------------------------
  def list_scenes() do
    :ets.match(@ets_scenes_table, {:"$1", :"_"})
    |> List.flatten()
  end

  #--------------------------------------------------------
  def list_scene_activations( scene_ref ) do
    :ets.match(@ets_activation_table, {scene_ref, :"$2"})
    |> Enum.map( fn([id,args]) -> {id, args} end)
  end

  #--------------------------------------------------------
  def list_active_scenes() do
    :ets.match(@ets_activation_table, {:"1", :"_"})
    |> List.flatten()
  end

  #--------------------------------------------------------
  def put_graph( graph, opts \\ [] )

  def put_graph( %Graph{primitive_map: p_map} = graph, opts ) do
    scene_ref = case Process.get(:scene_ref) do
      nil ->
        raise "Scenic.ViewPort.put_graph can only be called from with in a Scene"
      ref ->
        ref
    end

    # reduce the incoming graph to it's minimal form
    min_graph = Enum.reduce(p_map, %{}, fn({uid, p}, g) ->
      Map.put( g, uid, Primitive.minimal(p) )
    end)

    GenServer.cast( @viewport, {:put_graph, min_graph, scene_ref, opts} )

    # return the original graph, allowing it to be used in a pipeline
    graph
  end

  #--------------------------------------------------------
  def graph?( scene_ref ) do
    case :ets.lookup(@ets_graphs_table, scene_ref) do
      [] -> false
      _ -> true
    end
  end

  #--------------------------------------------------------
  def get_graph( scene_ref )

  def get_graph( nil ), do: nil

  def get_graph( scene_ref ) when is_reference(scene_ref) or is_atom(scene_ref) do
    case :ets.lookup(@ets_graphs_table, scene_ref) do
      [] -> nil
      [{_, graph}] -> graph
    end
  end

  def get_graph( other ) do
    pry()
  end

  #--------------------------------------------------------
  def list_graphs() do
    :ets.match(@ets_graphs_table, {:"$1", :"_"})
    |> List.flatten()
  end


  #--------------------------------------------------------
  @doc """
  Send an input event to the viewport for processing. This is typcally called
  by drivers that are generating input events.
  """
  def input( input_event ) do
    GenServer.cast( @viewport, {:input, input_event} )
  end

  def input( input_event, context ) do
    GenServer.cast( @viewport, {:input, input_event, context} )
  end

  def capture_input( scene_ref, input_types ) when is_list(input_types) do
    GenServer.cast( @viewport, {:capture_input, scene_ref, input_types} )
  end
  def capture_input( scene_ref, input_type ), do: capture_input( scene_ref, [input_type] )

  def release_input( input_types ) when is_list(input_types) do
    GenServer.cast( @viewport, {:release_input, input_types} )
  end
  def release_input( input_type ), do: release_input( [input_type] )



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
  def request_scene( to_pid \\ nil )
  def request_scene( nil ) do
    request_scene( self() )
  end
  def request_scene( to_pid ) do
    GenServer.cast( @viewport, {:request_scene, to_pid} )
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
      raw_scene_refs: %{},
      dyn_scene_refs: %{},

      root_scene: nil,
      input_captures: %{},
      hover_primitve: nil,

      set_scene: nil,
      set_list: [],

      max_depth: opts[:max_depth] || @max_depth,
      graph_table: :ets.new(@ets_graphs_table, [:named_table, read_concurrency: true]),
      scene_table: :ets.new(@ets_scenes_table, [:named_table, :public, {:read_concurrency, true}]),
      activation_table: :ets.new(@ets_activation_table, [:named_table, read_concurrency: true]),
#      startup_table: :ets.new(@ets_startup_table, [:named_table, :public])
    }

    {:ok, state}
  end



  #============================================================================
  # handle_info

  # when a scene goes down, clear it's graphs from the ets table
  def handle_info({:DOWN, _monitor_ref, :process, pid, reason}, state) do
    # get the scene_ref for this pid
    scene_ref = Scene.pid_to_scene( pid )

    # clear the related scene entry and graphs, but only if another scene
    # has not already registered them. Wand to avoid a possible race
    # condition when a scene crashes and is being restarted
    state = case :ets.lookup(@ets_scenes_table, scene_ref ) do
      [{_,%Scene.Registration{pid: ^pid}}] -> nil

        # delete the scene's graph
        ViewPort.Driver.cast({:delete_graph, scene_ref})
        :ets.delete(@ets_graphs_table, scene_ref)

        # unregister the scene itself
        :ets.delete(@ets_scenes_table, scene_ref)

        # delete the activations - ok if there is none
        :ets.delete(@ets_activation_table, scene_ref)

        # clean up the stored references and return the state
        state
        |> Utilities.Map.delete_in( [:raw_scene_refs, scene_ref] )
        |> Utilities.Map.delete_in( [:dyn_scene_refs, scene_ref] )

      _ ->
        # either not there, or claimed by another scene
        state
    end

    {:noreply, state}
  end


  #--------------------------------------------------------
  # the startup sequence when setting a new scene is tricky. In order to prevent blinking
  # during the transition, we need to make sure any dynamic scenes that are referenced
  # by the scene being set are started and activated before sending :set_root to the drivers.
  # These dynamic scenes may be nested. To make it more fun, init or actiavate on those
  # scenes may (probably will) call ViewPort.put_graph, which means its reentrant. So...
  # this process cannot block while setting the scene.
  #
  # No blinkies...
  #
  # This was hard to figure out. Many approaches were tried and elimiated...

#  def handle_info({ref, {:set_complete, _, _}}, %{setting_scene: nil} = state) do
#    {:noreply, state}
#  end
#
#  def handle_info({ref, {:set_complete, set_ref, complete_ref}},
#  %{setting_scene: {set_scene, []}} = state) when set_ref == set_scene do
#    # setup is complete,send the message to the drivers
#    ViewPort.Driver.cast( {:set_root, set_scene} )
#    {:noreply, %{state | setting_scene: nil}}
#  end
#
#  def handle_info({ref, {:set_complete, set_ref, complete_ref}},
#  %{setting_scene: {set_scene, completion_list}} = state) do
#    completion_list = List.delete(completion_list, complete_ref)
#    state = case completion_list do
#      [] ->
#        # setup is complete,send the message to the drivers
#        ViewPort.Driver.cast( {:set_root, set_scene} )
#        %{state | setting_scene: nil}
#      list ->
#        %{state | setting_scene: {set_scene, completion_list}}
#    end
#    {:noreply, state}
#  end
#
#  def handle_info(other, state) do
#    pry()
#  end


  #============================================================================
  # handle_call

  #--------------------------------------------------------
  # before putting the graph, we need to manage any dynamic scenes it
  # reference. This is really the main point of the viewport. The drivers
  # shouldn't have any knowledge of the actual processes used and only
  # refer to graphs by unified keys
#  def handle_call( {:put_graph, graph, scene_ref, opts}, _,  state ) do
#    state = do_put_graph(graph, scene_ref, opts, state)
#    {:reply, :ok, state}
#  end

  def handle_call( :flush, _,  state ) do
    {:reply, :ok, state}
  end

  #============================================================================
  # handle_cast

  #--------------------------------------------------------
#  def handle_cast( {:register_scene, scene_ref, registration}, state ) do
##    :ets.insert(@ets_scenes_table, {scene_ref, registration})
#    Process.monitor( registration.pid )
#    {:noreply, state}
#  end
  def handle_cast( {:monitor_scene, scene_pid}, state ) do
    Process.monitor( scene_pid )
    {:noreply, state}
  end


  #--------------------------------------------------------
  def handle_cast( {:request_scene, to_pid}, %{root_scene: scene} = state ) do
    GenServer.cast( to_pid, {:set_root, scene} )
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast( {:register_activation, scene_ref, args}, state ) do
    :ets.insert(@ets_activation_table, {scene_ref, args})
    {:noreply, state}
  end


  #--------------------------------------------------------
  def handle_cast( {:activation_complete, _, _}, %{set_scene: nil} = state ) do
    # Not setting a scene. Safe to ignore this.
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast( {:activation_complete, _, root_scene}, %{
    set_scene: {set_scene, activate_args},
    set_list: []
  } = state ) when root_scene == set_scene do
    # setup is complete,send the message to the drivers
    Task.start(fn ->
      GenServer.call(@viewport, :flush)
      ViewPort.Driver.cast( {:set_root, set_scene} )
    end)
    {:noreply, %{state | set_scene: nil}}
  end

  #--------------------------------------------------------
  def handle_cast( {:activation_complete, scene_ref, root_scene}, %{
    set_scene: {set_scene, activate_args},
    set_list: set_list
  } = state ) when root_scene == set_scene do
    state = List.delete(set_list, scene_ref)
    |> case do
      [] ->
        # setup is complete,send the message to the drivers
        Task.start(fn ->
          GenServer.call(@viewport, :flush)
          ViewPort.Driver.cast( {:set_root, set_scene} )
        end)
        %{state | set_scene: nil, set_list: []}
      set_list ->
        # record teh shortened list
        %{state | set_list: set_list}
    end
    {:noreply, state}
  end


  #--------------------------------------------------------
  # Start and activate
  def handle_cast( {:start_dyn_scene, parent, scene_ref, mod, init_data}, %{
    set_scene: {set_scene, activate_args},
    set_list: set_list
  } = state ) do
    {:ok, _} = mod.start_child_scene( parent, scene_ref, init_data)
    Scene.activate( scene_ref, activate_args, set_scene )
    {:noreply, state}
  end

  #--------------------------------------------------------
  # start, but don't activate
  def handle_cast( {:start_dyn_scene, parent, scene_ref, mod, init_data}, state ) do
    {:ok, _} = mod.start_child_scene( parent, scene_ref, init_data)
    {:noreply, state}
  end

  #--------------------------------------------------------
  # set a scene to be the new root
  def handle_cast( {:set_scene, scene_ref, args}, %{root_scene: old_scene} = state ) do

    # reset all activations
    :ets.delete_all_objects(@ets_activation_table)

    # prep the state
    state = state
    |> Map.put( :hover_primitve, nil )
    |> Map.put( :input_captures, %{} )
    |> Map.put( :dynamic_scenes, %{} )


    # set the new scene - how depends on if it is dynamic or app supervised
    state = case scene_ref do
      # dynamic scene
      {mod, init_data} ->
        new_ref = make_ref()

        # start and activate the new scene
        {:ok, _} = mod.start_child_scene( @dynamic_scenes, new_ref, init_data)
        Scene.activate( new_ref, args, new_ref )

        state
        |> Map.put( :root_scene, new_ref )
        |> Map.put( :set_scene, {new_ref, args} )
        |> Map.put( :set_list, [new_ref] )

      # app supervised scene
      scene_ref when is_atom(scene_ref) ->
        # activate the scene
        Scene.activate( scene_ref, args, scene_ref )

        state
        |> Map.put( :root_scene, scene_ref )
        |> Map.put( :set_scene, {scene_ref, args} )
        |> Map.put( :set_list, [scene_ref] )
    end

    # tear down the old scene
    if old_scene != scene_ref do
      with {:ok, scene_pid} <- Scene.to_pid(old_scene) do
        Task.start fn ->
          GenServer.call( scene_pid, :deactivate )
          Scene.stop( old_scene )
        end
      end
    end

    {:noreply, state}
  end

  #--------------------------------------------------------
  # before putting the graph, we need to manage any dynamic scenes it
  # reference. This is really the main point of the viewport. The drivers
  # shouldn't have any knowledge of the actual processes used and only
  # refer to graphs by unified keys
  def handle_cast( {:put_graph, graph, scene_ref, opts}, %{
    raw_scene_refs: raw_scene_refs,
    dyn_scene_refs: dyn_scene_refs,
    set_scene: set_scene,
    set_list: set_list
  } = state ) do
    # get the old refs
    old_raw_refs =  Map.get( raw_scene_refs, scene_ref, %{} )

    # build a list of the dynamic scene references in this graph
    new_raw_refs = Enum.reduce( graph, %{}, fn
      {uid,%{ data: {Primitive.SceneRef, {mod, init_data}}}}, nr ->
        Map.put(nr, uid, {mod, init_data})
      # not a ref. ignore it
      _, nr -> nr
    end)

    # get the difference script between the raw refs
    raw_diff = Utilities.Map.difference( old_raw_refs, new_raw_refs )

    # get the old, resolved dynamic scene refs
    old_dyn_refs = Map.get( dyn_scene_refs, scene_ref, %{} )

    # Enumerate the old refs, using the difference script to determine
    # what to start or stop.
    new_dyn_refs = Enum.reduce(raw_diff, old_dyn_refs, fn
      {:put, uid, {mod, init_data}}, refs ->     # start this dynamic scene
        # make a new, scene ref
        new_scene_ref = make_ref()

        {:ok, _pid} = mod.start_child_scene( scene_ref, new_scene_ref, init_data)
        with {root, activation_args} <- set_scene do
          Scene.activate( new_scene_ref, activation_args, root )  
        end
      
        # add the this ref for next time
        Map.put(refs, uid, new_scene_ref)

      {:del, uid}, refs ->                      # stop this dynaic scene
        # get the old dynamic graph reference
        old_scene_ref = old_dyn_refs[uid]

        # send the optional deactivate message and terminate. ok to be async
        Task.start fn ->
          Scene.deactivate( old_scene_ref )
          Scene.stop( old_scene_ref )
        end

        # remove the reference from the old refs
        Map.delete(refs, uid)
    end)

    # take all the new refs and insert them back into the graph, so that they are
    # nice and normalized for the drivers
    graph = Enum.reduce(new_dyn_refs, graph, fn({uid, new_dyn_ref}, g)->
      put_in(g, [uid, :data], {Primitive.SceneRef, new_dyn_ref})
    end)

    # if we are in the process of setting a scene, add any newly created dyn scenes to the
    # set_list. This is so the drivers won't be notified until they have activated.
    state = with {root_scene, _} <- set_scene do
      dyn_diff = Utilities.Map.difference( old_dyn_refs, new_dyn_refs )
      set_list = Enum.reduce(dyn_diff, set_list, fn
        {:put, _, ref}, sl -> [ ref | sl ]
        _, sl -> sl
      end)
      Map.put(state, :set_list, set_list)
    else
      _ -> state
    end

    # store the refs for next time
    state = put_in(state, [:raw_scene_refs, scene_ref], new_raw_refs)
    state = put_in(state, [:dyn_scene_refs, scene_ref], new_dyn_refs)

    # insert the graph into the etstable
    :ets.insert(@ets_graphs_table, {scene_ref, graph})

    # tell the drivers about the updated graph
    ViewPort.Driver.cast( {:put_graph, scene_ref} )

    # return the updated state
    {:noreply, state}
  end



  #============================================================================
  # The rest of the message are handle as Input. Yes, these functions could
  # easily be in this file, but it got too long, so I moved them.


  #--------------------------------------------------------
  # ignore input until a scene has been set
  def handle_cast( msg, state ) do
    ViewPort.Input.handle_cast( msg, state )
  end


end





