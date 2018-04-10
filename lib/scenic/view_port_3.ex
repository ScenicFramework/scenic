#
#  Created by Boyd Multerer on 04/07/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# Taking the learnings from several previous versions.

defmodule Scenic.ViewPort3 do
  alias Scenic.ViewPort3, as: ViewPort

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

  @viewport         :viewport
  @dynamic_scenes   :dynamic_scenes
  @max_depth        256


  # ets table names
  @ets_graphs_table     :_scenic_vp3_graphs_table_


  defmodule Input.Context do
    alias Scenic.Math.MatrixBin, as: Matrix
    @identity         Matrix.identity()
    defstruct scene: nil, tx: @identity, inverse_tx: @identity, uid: nil
  end



  #============================================================================
  # client api

  # Get the name of the graphs table. Used by Scene
  @doc false
  def graphs_table(), do: @ets_graphs_table

  #--------------------------------------------------------
  @doc """
  Set a the root scene/graph of the ViewPort.
  """

  def set_root( scene, sub_id \\ nil, args ) do
    GenServer.cast( @viewport, {:set_root, scene, sub_id, args} )
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
  def driver_cast( viewport, msg ), do
    GenServer.cast(viewport, {:driver_cast, msg})
  end


  #============================================================================
  # internal server api


  #--------------------------------------------------------
  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @viewport)
  end


  #--------------------------------------------------------
  @doc false
  def init( opts ) do

    # set up the initial state
    state = %{
      root_graph: nil,
      input_captures: %{},
      hover_primitve: nil,

      drivers: [],

#      unset_scene: nil,
#      unset_exceptions: [],
#      set_scene: nil,
#      set_list: [],

      max_depth: opts[:max_depth] || @max_depth,
      graph_table_id: :ets.new(@ets_graphs_table, [:public])
    }

    # :named_table, read_concurrency: true

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

  # when a scene goes down, clean it up
  def handle_call(:get_graph_table, _, %{graph_table_id: tid} = state) do
    {:reply, {:ok, tid}, state}
  end



  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  def handle_cast( {:monitor, scene_pid}, state ) do
    Process.monitor( scene_pid )
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast( {:set_root, scene, sub_id, args}, %{
    graph_table_id: graph_table_id
  } = state ) do

    # prep state, which is mostly about resetting input
    state = state
    |> Map.put( :hover_primitve, nil )
    |> Map.put( :input_captures, %{} )

    # if the scene being set is dynamic, start it up
    graph_ref = case scene do
      # dynamic scene
      {mod, init_data} ->
        new_ref = make_ref()
        {:graph, new_ref, sub_id}

      # app supervised scene
      scene_name when is_atom(scene_name) ->
        {:graph, scene_name, sub_id}
    end

    # create a unique activation ref. This is used to know that the async
    # activation operation has fully completed
    activation_ref = make_ref()

    # activate the scene
    Scene.activate( graph_ref, args, graph_table_id, activation_ref )

    # set up the local state
    state
    |> Map.put( :root_graph, graph_ref )
    |> Map.put( :activation_ref, activation_ref )
#    |> Map.put( :set_scene, {scene_ref, args} )
#    |> Map.put( :set_list, [scene_ref] )


    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast( {:driver_cast, msg}, %{drivers: drivers} = state ) do
    # relay the graph_key to all listening drivers
    Enum.each(drivers, &GenServer.cast(&1, msg)
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
  
end









