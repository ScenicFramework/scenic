#
#  Created by Boyd Multerer on 04/07/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# Taking the learnings from several previous versions.

defmodule Scenic.ViewPort do
  use GenServer
  alias Scenic.ViewPort
  alias Scenic.Scene
  alias Scenic.Graph

  alias Scenic.Primitive

  import IEx

  @moduledoc """

  ## Overview

  The job of the `ViewPort` is to coordinate the flow of information between
  the scenes and the drivers. Scene's and Drivers should not know anything
  about each other. An app should work identically from it's point of view
  no matter if there is one, multiple, or no drivers currently running.

  Drivers are all about rendering output and collecting input from a single
  source. Usually hardware, but can also be the network or files. Drivers
  only care about graphs and should not need to know anything about the
  logic or state encapsulated in Scenes.

  The goal is to isolate app data & logic from render data & logic. The
  ViewPort is the chokepoint between them that makes sense of the flow
  of information.

  ## OUTPUT

  Practically speaking, the `ViewPort` is the owner of the ETS tables that
  carry the graphs (and any other necessary support info). If the VP
  crashes, then all that information needs to be rebuilt. The VP monitors
  all running scenes and does the appropriate cleanup when any of them
  goes DOWN.

  The scene is responsible for generating graphs and writing them to
  the graph ETS table. (Also tried casting the graph to the ViewPort
  so that the table could be non-public, but that had issues)

  The drivers should only read from the graph tables.

  ## INPUT

  When user input happens, the drivers send it to the `ViewPort`.
  Input that does not depend on screen position (key presses, audio
  window events, etc...) Are sent to the root scene unless some other
  scene has captured that type of input (see captured input) below.

  If the input event does depend on positino (cursor position, cursor
  button presses, scrolling, etc...) then the ViewPort needs to
  travers the hierarchical graph of graphs, to find the corrent
  scene, and the item in that scene that was "hit". The ViewPort
  then sends the event to that scene, with the position projected
  into the scene's local coordinate space (via the built-up stack
  of matrix transformations)

  ## CAPTURED INPUT

  A scene can request to "capture" all input events of a certain type.
  this means that all events of that type are sent to a certain
  scene process regardless of position or root. In this way, a
  text input scene nested deep in the tree can capture key presses.
  Or a button can capture cursor_pos events after it has been pressed.

  if a scene has "captured" a position dependent input type, that
  position is projected into the scene's coordinate space before
  sending the event. Note that instead of walking the graph of graphs,
  the transforms provided in the input "context" field are used. You
  could, in theory change that to something else before capturing,
  but I wouldn't really recommend it.

  Any scene can cancel the current capture. This would probably
  leave the scene that thinks it has "captured" the input in a
  weird state, so I wouldn't recommend it.

  """

  @viewport             :viewport
#  @dynamic_scenes       :dynamic_scenes
  @dynamic_supervisor   :vp_dynamic_sup
  @max_depth            256


  # ets table names
  @ets_graphs_table     :_scenic_vp3_graphs_table_



  #============================================================================
  # client api

  # Get the name of the graphs table. Used by Scene
  @doc false
  def graphs_table(), do: @ets_graphs_table

  #--------------------------------------------------------
  @doc """
  Set a the root scene/graph of the ViewPort.
  """

  def set_root( scene, args \\ nil )

  def set_root( scene, args ) when is_atom(scene) do
    GenServer.cast( @viewport, {:set_root, scene, args} )
  end

  def set_root( {mod, init_data}, args ) when is_atom(mod) do
    GenServer.cast( @viewport, {:set_root, {mod, init_data}, args} )
  end

  #--------------------------------------------------------
  @doc """
  Push a graph to one or more viewports. This will not start any dynamic
  scenes the graph references. Use Scene.update_children for that.

  Pass in a list of activations that the scene received via handle_activation.
  """
  def push_graph( graph, sub_id \\ nil )

  def push_graph( %Graph{primitive_map: p_map} = graph, sub_id ) do
    scene_ref = case Process.get(:scene_ref) do
      nil ->
        raise "Scenic.ViewPort.push_graph must be called from with in a Scene"
      ref ->
        ref
    end
#    IO.puts "--------------> push_graph"

    graph_key = {:graph, scene_ref, sub_id}

    # TEMPORARY HACK
    # reduce the incoming graph to it's minimal form
    min_graph = Enum.reduce(p_map, %{}, fn({uid, p}, g) ->
      Map.put( g, uid, Primitive.minimal(p) )
    end)
    # merge in the dynamic references
    min_graph = Enum.reduce(graph.dyn_refs, min_graph, fn({uid, dyn_ref}, g)->
      put_in(g, [uid, :data], {Primitive.SceneRef, dyn_ref})
    end)

    # write the graph into the ets table
    :ets.insert(@ets_graphs_table, {graph_key, {self(), min_graph}})

    # notify the drivers of the updated graph
    driver_cast( {:push_graph, graph_key} )

    # return the graph itself so this can be chained in a pipeline
    graph
  end


  #--------------------------------------------------------
  def get_graph( {:graph, _, _} = key ) do
    case :ets.lookup(@ets_graphs_table, key) do
      [] -> nil
      [{_, {_, graph}}] -> graph
    end
  end

  #--------------------------------------------------------
  @doc """
  Capture one or more types of input.

  This must be called by a Scene process.
  """

  def capture_input( %ViewPort.Input.Context{} = context, input_types )
  when is_list(input_types) do
  end
  def capture_input( context, input_type ), do: capture_input( context, [input_type] )


  #--------------------------------------------------------
  @doc """
  release an input capture.

  This is intended be called by a Scene process, but doesn't need to be.
  """

  def release_input( input_types ) when is_list(input_types) do
  end
  def release_input( input_type ), do: release_input( [input_type] )


  #--------------------------------------------------------
  @doc """
  Cast a message to all active drivers listening to a viewport.
  """
  def driver_cast( msg ) do
    GenServer.cast(@viewport, {:driver_cast, msg})
  end


  #--------------------------------------------------------
  def start_driver( module, args ) do
    
  end

  #--------------------------------------------------------
  def stop_driver( driver_pid )


  #============================================================================
  # internal server api


  #--------------------------------------------------------
  @doc false
  def start_link({initial_scene, args, opts}) do
    GenServer.start_link(__MODULE__, {initial_scene, args, opts}, name: @viewport)
  end


  #--------------------------------------------------------
  @doc false
  def init( {initial_scene, args, opts} ) do

    # set up the initial state
    state = %{
      root_scene: nil,
      dynamic_root: nil,
      input_captures: %{},
      hover_primitve: nil,

      drivers: [],

      max_depth: opts[:max_depth] || @max_depth,
      graph_table_id: :ets.new(@ets_graphs_table, [:named_table, :public])
    }

    # :named_table, read_concurrency: true

    # set the initial scene as the root
    case initial_scene do
      # dynamic scene can start right up without a splash screen
      {mod, init} when is_atom(mod) ->
        set_root( {mod, init}, args )

      scene when is_atom(scene) ->
        set_root( {Scenic.SplashScreen, {scene, args, opts}}, nil )
    end

    {:ok, state}
  end

  #============================================================================
  # handle_info

  # when a scene goes down, clean it up
  def handle_info({:DOWN, _monitor_ref, :process, pid, reason}, state) do
    {:noreply, state}
  end


  #============================================================================
  # handle_call


  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  def handle_cast( {:monitor, scene_pid}, state ) do
    Process.monitor( scene_pid )
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast( {:set_root, scene, args}, %{
    graph_table_id: graph_table_id,
    drivers: drivers,
    root_scene: old_root_scene,
    dynamic_root: old_dynamic_root_scene
  } = state ) do

    # prep state, which is mostly about resetting input
    state = state
    |> Map.put( :hover_primitve, nil )
    |> Map.put( :input_captures, %{} )

    # if the scene being set is dynamic, start it up
    {scene, dynamic_scene} = case scene do
      # dynamic scene
      {mod, init_data} ->
        # start the dynamic scene
        {:ok, pid, _} = mod.start_dynamic_scene( @dynamic_supervisor, nil, init_data )
        {pid, pid}

      # app supervised scene - mark dynamic root as nil
      scene when is_atom(scene) ->
        {scene, nil}
    end

    # activate the scene
    GenServer.call(scene, {:activate, args})

    # tell the drivers about the new root
#    driver_cast( {:set_root, {:graph, scene, nil}} )
    do_driver_cast( drivers, {:set_root, {:graph, scene, nil}} )

    # clean up the old root graph. Can be done async so long as
    # terminating the dynamic scene (if set) is after deactivation
    if old_root_scene do
      Task.start( fn ->
        GenServer.call(old_root_scene, :deactivate)
        if old_dynamic_root_scene do
          DynamicSupervisor.terminate_child(
            @dynamic_supervisor,
            old_dynamic_root_scene
          )
        end
      end)
    end

    {:noreply, %{state | root_scene: scene, dynamic_root: dynamic_scene}}
  end


  #--------------------------------------------------------
  def handle_cast( {:driver_cast, msg}, %{drivers: drivers} = state ) do
    # relay the graph_key to all listening drivers
    do_driver_cast( drivers, msg )
    {:noreply, state}
  end
  
  #--------------------------------------------------------
  def handle_cast( {:driver_ready, driver_pid}, %{drivers: drivers} = state ) do
    drivers = [ driver_pid | drivers ] |> Enum.uniq()
    {:noreply, %{state | drivers: drivers}}
  end
  
  #--------------------------------------------------------
  def handle_cast( {:driver_stopped, driver_pid}, %{drivers: drivers} = state ) do
    drivers = Enum.reject(drivers, fn(d)-> d == driver_pid end)
    {:noreply, %{state | drivers: drivers}}
  end
  
  #============================================================================
  # internal utilities

  defp do_driver_cast( driver_pids, msg ) do
    Enum.each(driver_pids, &GenServer.cast(&1, msg) )
  end

end









