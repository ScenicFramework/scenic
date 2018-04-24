#
#  Created by Boyd Multerer on 04/07/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# Taking the learnings from several previous versions.

defmodule Scenic.ViewPort do
  use GenServer
  alias Scenic.ViewPort
  alias Scenic.ViewPort.Input.Context
#  alias Scenic.ViewPort.Driver
#  alias Scenic.Scene
#  alias Scenic.Graph

#  alias Scenic.Primitive

#  import IEx

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
  @viewports            :scenic_viewports

  @viewport             :viewport
#  @dynamic_scenes       :dynamic_scenes
#  @dynamic_supervisor   :vp_dynamic_sup
  @max_depth            256


  #============================================================================
  # client api


  #--------------------------------------------------------
  @doc """
  Start a new viewport
  """
  def start( initial_scene, args, opts \\ [] ) do
    # start the viewport's supervision tree
    {:ok, sup_pid} = DynamicSupervisor.start_child( @viewports,
      {ViewPort.Supervisor, {initial_scene, args, opts}}
    )

    # we want to return the pid of the viewport itself
    {viewport_pid, ds_pid} = Supervisor.which_children( sup_pid )
    |> Enum.reduce( {nil, nil}, fn 
      {_, pid, :worker, [Scenic.ViewPort]}, {_, ds} -> {pid, ds}
      {_, pid, :supervisor, [DynamicSupervisor]}, {vp, _} -> {vp, pid}
    end)

    # tell the new viewport about it's supervisors
    GenServer.cast(viewport_pid, {:init_pids, sup_pid, ds_pid})

    # return the pid to the viewport itself
    {:ok, viewport_pid}
  end

  #--------------------------------------------------------
  @doc """
  Stop a running viewport
  """

  def stop( viewport )

  def stop( viewport ) when is_atom(viewport) and not is_nil(viewport) do
    Process.whereis( viewport ) |> stop()
  end

  def stop( viewport ) when is_pid(viewport) do
    DynamicSupervisor.terminate_child( @viewports, viewport )
  end


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
  def request_root( send_to \\ nil )
  def request_root( nil ) do
    request_root( self() )
  end
  def request_root( to ) when is_pid(to) or is_atom(to) do
    GenServer.cast( @viewport, {:request_root, to} )
  end

  #--------------------------------------------------------
  def input( viewport, input_event ) do
    GenServer.cast( viewport, {:input, input_event} )
  end

  def input( viewport, input_event, context ) do
    GenServer.cast( viewport, {:input, input_event, context} )
  end

  #--------------------------------------------------------
  @doc """
  Capture one or more types of input.

  This must be called by a Scene process.
  """

  def capture_input( %Context{viewport: pid} = context, input_types )
  when is_list(input_types) do
    GenServer.cast( pid, {:capture_input, context, input_types} )
  end
  def capture_input( context, input_type ), do: capture_input( context, [input_type] )


  #--------------------------------------------------------
  @doc """
  release an input capture.

  This is intended be called by a Scene process, but doesn't need to be.
  """
  def release_input( context_or_viewport, input_types )

  def release_input( %Context{viewport: pid}, input_types ) do
    release_input( pid, input_types )
  end
  def release_input( vp, types ) when (is_pid(vp) or is_atom(vp)) and is_list(types) do
    GenServer.cast( vp, {:release_input, types} )
  end
  def release_input( vp, input_type ), do: release_input( vp, [input_type] )


  #--------------------------------------------------------
  @doc """
  Cast a message to all active drivers listening to a viewport.
  """
  def driver_cast( viewport, msg ) do
    GenServer.cast(viewport, {:driver_cast, msg})
  end


  #--------------------------------------------------------
  def start_driver( viewport, module, args, opts \\ [] ) when
  is_atom(module) and is_list(opts) and
  (is_atom(viewport) or is_pid(viewport) )do
    GenServer.call(viewport, { :start_driver, module, args, opts })
  end

  #--------------------------------------------------------
  def stop_driver( viewport, driver_pid ) when
  (is_atom(viewport) or is_pid(viewport) ) and 
  (is_atom(driver_pid) or is_pid(driver_pid) )
  do
    GenServer.cast(viewport, { :stop_driver, driver_pid })
  end


  #============================================================================
  # internal server api

  def child_spec({initial_scene, args, opts}) do
    %{
      id: make_ref(),
      start: {__MODULE__, :start_link, [{initial_scene, args, opts}]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  #--------------------------------------------------------
  @doc false
  def start_link({_, _, opts} = args) do
    case opts[:name] do
      nil -> GenServer.start_link(__MODULE__, args)
      name -> GenServer.start_link(__MODULE__, args, name: name)
    end
  end

  #--------------------------------------------------------
  @doc false
  def init( {initial_scene, args, opts} ) do

    # set up the initial state
    state = %{
      root_graph_key: nil,
      root_scene_pid: nil,
      dynamic_root_pid: nil,

      input_captures: %{},
      hover_primitve: nil,

      drivers: [],
      immediate_supervisor: nil,
      dynamic_supervisor: nil,

      max_depth: opts[:max_depth] || @max_depth,
    }

    # set the initial scene as the root
    case initial_scene do
      nil -> :ok
      scene -> GenServer.cast( self(), {:set_root, scene, args} )
    end

    {:ok, state}
  end

  #============================================================================
  # handle_info

  # when a scene goes down, clean it up
#  def handle_info({:DOWN, _monitor_ref, :process, pid, reason}, state) do
#    {:noreply, state}
#  end


  #============================================================================
  # handle_call


  #--------------------------------------------------------
  def handle_call( {:start_driver, _, _, _}, _, %{
    dynamic_supervisor: dyn_sup
  } = state ) when is_nil(dyn_sup) do
    {:reply, {:error, :viewport_not_ready}, state}
  end

  def handle_call( {:start_driver, module, args, opts}, _, %{
    dynamic_supervisor: dyn_sup
  } = state ) do
    {
      :reply,
      DynamicSupervisor.start_child( dyn_sup,
        {Scenic.ViewPort.Driver, {module, args, self(), opts}}
      ),
      state
    }
  end


  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  def handle_cast( {:init_pids, sup_pid, ds_pid}, state ) do
IO.puts "{:init_pids, sup_pid, ds_pid}"
    {:noreply, %{state | immediate_supervisor: sup_pid, dynamic_supervisor: ds_pid}}
  end

  #--------------------------------------------------------
  def handle_cast( {:set_root, scene, args}, %{
    root_scene_pid: old_root_scene,
    dynamic_root_pid: old_dynamic_root_scene,
    dynamic_supervisor: dyn_sup
  } = state ) do

    # prep state, which is mostly about resetting input
    state = state
    |> Map.put( :hover_primitve, nil )
    |> Map.put( :input_captures, %{} )

    # fetch the dynamic supervisor
    dyn_sup = case dyn_sup do
      nil -> find_dyn_supervisor()
      dyn_sup -> dyn_sup
    end

    # if the scene being set is dynamic, start it up
    {scene_pid, scene_ref, dynamic_scene} = case scene do
      # dynamic scene
      {mod, init_data} ->
        # start the dynamic scene
        {:ok, pid, ref} = mod.start_dynamic_scene( dyn_sup, nil, init_data )
        {pid, ref, pid}

      # app supervised scene - mark dynamic root as nil
      scene when is_atom(scene) ->
        {scene, scene, nil}
    end

    graph_key = {:graph, scene_ref, nil}

    # let the scene know it is the new root
    GenServer.call(scene_pid, {:set_root, args})

    # tell the drivers about the new root
    driver_cast( self(), {:set_root, graph_key} )

    # clean up the old root graph. Can be done async so long as
    # terminating the dynamic scene (if set) is after deactivation
    Task.start( fn ->
      if old_root_scene, do: GenServer.call(old_root_scene, :lose_root)
      if old_dynamic_root_scene do
        GenServer.cast(old_dynamic_root_scene, {:stop, dyn_sup})
      end
    end)

    state = state
    |> Map.put( :root_graph_key, graph_key )
    |> Map.put( :root_scene_pid, scene_pid )
    |> Map.put( :dynamic_root_pid, dynamic_scene )

    { :noreply, state }
  end


  #==================================================================
  # casts about drivers


  #--------------------------------------------------------
  def handle_cast( {:stop_driver, driver_pid}, %{
    drivers: drivers,
    dynamic_supervisor: dyn_sup
  } = state ) do
    DynamicSupervisor.terminate_child( dyn_sup, driver_pid )
    drivers = Enum.reject(drivers, fn(pid) -> pid == driver_pid end)
    {:noreply, %{state | drivers: drivers}}
  end


  #--------------------------------------------------------
  def handle_cast( {:driver_cast, msg}, %{drivers: drivers} = state ) do
    # relay the graph_key to all listening drivers
    do_driver_cast( drivers, msg )
    {:noreply, state}
  end
  
  #--------------------------------------------------------
  def handle_cast( {:driver_ready, driver_pid}, %{
    drivers: drivers,
    root_graph_key: root_key
  } = state ) do
    drivers = [ driver_pid | drivers ] |> Enum.uniq()
    GenServer.cast( driver_pid, {:set_root, root_key} )
    {:noreply, %{state | drivers: drivers}}
  end
  
  #--------------------------------------------------------
  def handle_cast( {:driver_stopped, driver_pid}, %{drivers: drivers} = state ) do
    drivers = Enum.reject(drivers, fn(d)-> d == driver_pid end)
    {:noreply, %{state | drivers: drivers}}
  end
  
  #--------------------------------------------------------
  def handle_cast( {:request_root, to_pid}, %{root_graph_key: root_key} = state ) do
    GenServer.cast( to_pid, {:set_root, root_key} )
    {:noreply, state}
  end

  #==================================================================
  # management casts from scenes
  
  #--------------------------------------------------------
#  def handle_cast( {:monitor, scene_pid}, state ) do
#    Process.monitor( scene_pid )
#    {:noreply, state}
#  end

  #--------------------------------------------------------
  # ignore input until a scene has been set
  def handle_cast( msg, state ) do
    ViewPort.Input.handle_cast( msg, state )
  end


  #============================================================================
  # internal utilities

  defp do_driver_cast( driver_pids, msg ) do
    Enum.each(driver_pids, &GenServer.cast(&1, msg) )
  end

  defp find_dyn_supervisor() do
    # get the scene supervisors
    [supervisor_pid | _] = self()
    |> Process.info()
    |> get_in([:dictionary, :"$ancestors"])

    # make sure it is a pid and not a name
    supervisor_pid = case supervisor_pid do
      name when is_atom(name) -> Process.whereis(name)
      pid when is_pid(pid) -> pid
    end

    case Process.info(supervisor_pid) do
      nil -> nil
      info ->
        case get_in( info, [:dictionary, :"$initial_call"] ) do
          {:supervisor, Scenic.ViewPort.Supervisor, _} ->
            Supervisor.which_children( supervisor_pid )
            |> IO.inspect()
            |> Enum.find_value( fn 
              {DynamicSupervisor, pid, :supervisor, [DynamicSupervisor]} -> pid
              _other -> nil
            end)
          _other -> nil
        end
    end
  end

end



