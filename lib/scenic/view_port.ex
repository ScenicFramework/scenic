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
  alias Scenic.Math.MatrixBin, as: Matrix
  alias Scenic.ViewPort.Input.Context
#  require Logger

  import IEx

  @viewport :viewport
  
  @dynamic_scenes   :dynamic_scenes

  @max_depth        64

  @root_graph       0

  @identity         Matrix.identity()



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
  def set_scene( scene, focus_param \\ nil )

  def set_scene( scene, focus_param ) when is_atom(scene) do
    GenServer.cast( @viewport, {:set_scene, scene, focus_param} )
  end

  def set_scene( {mod, init_data}, focus_param ) when is_atom(mod) do
    GenServer.cast( @viewport, {:set_scene, {mod, init_data}, focus_param} )
  end


  #--------------------------------------------------------
  def put_graph( graph, reference \\ nil )

  def put_graph( graph, nil ), do: put_graph( graph, self() )

  def put_graph( %Graph{primitive_map: p_map}, reference )
  when is_reference(reference) or is_atom(reference) or is_pid(reference) do
    graph = Enum.reduce(p_map, %{}, fn({uid, p}, g) ->
      Map.put( g, uid, Primitive.minimal(p) )
    end)
    GenServer.cast( @viewport, {:put_graph, graph, reference} )
  end

  #--------------------------------------------------------
  def register_scene( scene_ref ) when is_reference(scene_ref) or is_atom(scene_ref) do
    GenServer.cast( @viewport, {:register_scene, scene_ref, self()})
  end


  def graph?( graph_ref ) do
    :ets.lookup(__MODULE__, {:graph, graph_ref})
  end

  #--------------------------------------------------------
  def get_graph( graph_ref ) when is_reference(graph_ref) or is_atom(graph_ref) do
    case :ets.lookup(__MODULE__, graph_ref) do
      [] -> nil
      [{_, graph}] -> graph
    end
  end

  #--------------------------------------------------------
  def list_graphs() do
    :ets.safe_fixtable(__MODULE__, true)
    refs = :ets.first(__MODULE__)
    |> accumulate_graphs( [] )
    :ets.safe_fixtable(__MODULE__, false)
    refs
  end

  defp accumulate_graphs(:"$end_of_table", refs), do: refs

  defp accumulate_graphs(next, refs) do
    refs = [next | refs]
    next = :ets.next(__MODULE__, next)
    accumulate_graphs(next, refs)
  end

  #--------------------------------------------------------
  @doc """
  Send an input event to the viewport for processing. This is typcally called
  by drivers that are generating input events.
  """
  def input( input_event, viewport \\ @viewport ) do
#    GenServer.cast( viewport, {:input, input_event} )
  end

  def capture_input( input_type, %Context{} = context ) do
    GenServer.cast( @viewport, {:capture_input, input_type, context} )
  end

  def release_input( input_type ) do
    GenServer.cast( @viewport, {:release_input, input_type} )
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
      root_scene_pid: nil,
      root_scene_ref: nil,
      hover_primitve: nil,
      input_captures: %{},
      dynamic_scenes: %{},
      scenes: %{},
      max_depth: opts[:max_depth] || @max_depth,
      graph_table: :ets.new(__MODULE__, [:named_table, read_concurrency: true])
    }

IO.puts "GRAPH INIT"
#    GenServer.cast( self(), :after_init )
    {:ok, state}
  end


  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  def handle_cast( {:request_scene, to_pid}, %{root_scene_ref: scene_ref} = state ) do
    GenServer.cast( to_pid, {:set_root, scene_ref} )
    {:noreply, state}
  end

  #--------------------------------------------------------
  # set a scene to be the new root
  def handle_cast( {:set_scene, scene, scene_param},
  %{root_scene_pid: root_scene_pid} = state ) do

    # start by telling the previous scene that it has lost focus
    # done as a call to make sure the previous scene gets the message
    # if it is a dynamic scene, it might otherwise go down too quickly
    case root_scene_pid do
      nil ->
        # no previous scene. do nothing
        :ok

      pid ->
        # don't actually care about the result.
        GenServer.call( pid, :focus_lost )
    end

    # always recycle the dynamic scene supervisor when there is a new root scene
    DynamicSupervisor.which_children(@dynamic_scenes)
    |> Enum.each(fn({:undefined, pid, :worker, _}) ->
      :ok = DynamicSupervisor.terminate_child(@dynamic_scenes, pid)
    end)

    # get or start the pid for the new scene being set as the root
    {scene_pid, scene_ref} = case scene do
      {mod, opts} ->
        ref = make_ref()
        {:ok, pid} = DynamicSupervisor.start_child(@dynamic_scenes, {Scene, {mod, ref, opts}})
        {pid, ref}

      name when is_atom(name) ->
        {Process.whereis( name ), name}
    end

    # tell the new scene that it has gained focus
    GenServer.cast( scene_pid, {:focus_gained, scene_param} )

    # record that this is the new current scene
    state = state
    |> Map.put( :root_scene_pid, scene_pid )
    |> Map.put( :root_scene_ref, scene_ref )
    |> Map.put( :hover_primitve, nil )
    |> Map.put( :input_captures, %{} )

    # send a reset message to the drivers
    Driver.cast( {:set_root, scene_ref} )

    # record the root scene pid and return
    {:noreply, state}
  end

  def handle_cast( {:register_scene, ref, pid}, state ) do
    state = put_in( state, [:scenes, pid], ref )
    {:noreply, state}
  end

  #--------------------------------------------------------
  # before putting the graph, we need to manage any dynamic scenes it
  # reference. This is really the main point of the viewport. The drivers
  # shouldn't have any knowledge of the actual processes used and only
  # refer to graphs by unified keys
  def handle_cast( {:put_graph, graph, pid}, state )  when is_pid(pid) do
    # get the default ref for this pid
    case get_in(state, [:scenes, pid]) do
      nil ->
        raise "Scene must be registered before putting it's default graph"
      reference ->
        handle_cast( {:put_graph, graph, reference}, state )
    end
  end

  def handle_cast( {:put_graph, graph, reference},
  %{dynamic_scenes: dynamic_scenes} = state ) do

    # build a list of the scene references in this graph
    graph_refs = Enum.reduce( graph, %{}, fn
      {uid,%{ data: {Primitive.SceneRef, {{mod, init_data}, scene_id}}}}, nr ->
        Map.put(nr, uid, {mod, init_data})
      # not a ref. ignore it
      _, nr -> nr
    end)

    # scan the existing refs for this graph and shutdown any that are no
    # longer being used.
    old_refs =  Map.get( dynamic_scenes, reference, %{} )
    {new_refs, dead_refs} = Enum.reduce(old_refs, {old_refs, []},
    fn({uid, {pid,ref, old_mod, old_init_data}}, {o_refs, d_refs})->
      case graph_refs[uid] do
        {^old_mod, ^old_init_data} ->
          # an exact match. all good. leave everything alone
          {o_refs, d_refs}

        nil ->
         # this ref is either no longer being used or has changed.
         # shut it down and remove it.
         DynamicSupervisor.terminate_child(@dynamic_scenes, pid)
         d_refs = [ ref | d_refs ]
         o_refs = Map.delete(o_refs, uid)
         {o_refs, d_refs}
      end
    end)

    # scan the new dyanimc refernces and start any that are not
    # already running. Fix up all the refs in the process
    {new_refs, graph} = Enum.reduce(graph_refs, {new_refs, graph},
    fn({uid, {mod, init_data}} = key,{nr,g}) ->
      # see if it is already running in the existing refs
      case nr[key] do
        {_, ref, _, _} ->
          # don't start anything, but do put the ref into the graph
          g = put_in(g, [uid, :data], {Primitive.SceneRef, ref})
          {nr, g}

        nil ->
          # need to start up a dynamic scene
          ref = make_ref()
          {:ok, pid} = DynamicSupervisor.start_child(
            @dynamic_scenes,
            {Scene, {mod, ref, init_data}}
          )
          nr = Map.put(nr, uid, {pid, ref, mod, init_data})
          g = put_in(g, [uid, :data], {Primitive.SceneRef, ref})
          {nr, g}
      end
    end)

    # store the refs and the graph
    state = put_in(state, [:dynamic_scenes, reference], new_refs)
    :ets.insert(__MODULE__, {reference, graph}) 

    # can now safely delete the dead graphs from the table
    Enum.each( dead_refs, &:ets.delete(__MODULE__, &1) )

    # store the dyanamic scenes references
    {:noreply, state}
  end

  #--------------------------------------------------------
  # Input handling is enough of a beast to put move it into it's own section at the
  # bottom of this file.
  def handle_cast( {:input, {input_type, _} = input_event}, 
  %{input_captures: input_captures} = state ) do
#    case Map.get(input_captures, input_type) do
#      nil ->
#        # regular input handling
#        do_handle_input(input_event, state)
#
#      context ->
#        graph = get_graph(context.reference) 
#        # captive input handling
#        do_handle_captured_input(input_event, graph, context, state)
#    end

    {:noreply, state}
  end

  #--------------------------------------------------------
  # capture a type of input
  def handle_cast( {:capture_input, input_type, context}, state ) do
    state = put_in(state, [:input_captures, input_type], context)
    {:noreply, state}
  end

  #--------------------------------------------------------
  # release a captured type of input
  def handle_cast( {:release_input, input_type},
  %{input_captures: input_captures} = state ) do
    input_captures = Map.delete(input_captures, input_type)
    {:noreply, %{state | input_captures: input_captures}}
  end













  #============================================================================
  # utilities

end





