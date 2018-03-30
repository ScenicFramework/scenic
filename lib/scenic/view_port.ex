#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort do
  use GenServer
  alias Scenic.ViewPort.Driver
  alias Scenic.Scene
  alias Scenic.Utilities
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Math.MatrixBin, as: Matrix
  alias Scenic.ViewPort.Input.Context
  require Logger

  import IEx

  @viewport :viewport
  
  @dynamic_scenes   :dynamic_scenes

  @max_depth        256

  @root_graph       0

  @identity         Matrix.identity()


  @ets_scenes_table   :_scenic_viewport_scenes_table_
  @ets_graphs_table   :_scenic_viewport_graphs_table_
  @ets_graph_activation_table   :_scenic_viewport_graph_activation_table_

  defmodule Input.Context do
    alias Scenic.Math.MatrixBin, as: Matrix
    @identity         Matrix.identity()
    defstruct tx: @identity, inverse_tx: @identity, uid: nil, graph_ref: nil, event_chain: []
  end



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
  def register_scene( scene_ref, scene_pid, dynamic_pid, supervisor_pid ) do
#    Registry.register( :viewport_registry, scene_ref, {scene_pid, dynamic_pid, supervisor_pid} )
#    GenServer.cast(@viewport, {:monitor_scene, self()})
    GenServer.cast(@viewport, {:register_scene, scene_ref, scene_pid, dynamic_pid, supervisor_pid})
  end

  def register_scene( scene_ref, %Scene.Registration{} = registration ) do
#    Registry.register( :viewport_registry, scene_ref, {scene_pid, dynamic_pid, supervisor_pid} )
#    GenServer.cast(@viewport, {:monitor_scene, self()})
    GenServer.cast(@viewport, {:register_scene, scene_ref, registration})
  end

#  def unregister_scene( scene_ref ) do
#    Registry.unregister( :viewport_registry, scene_ref )
#  end

  #--------------------------------------------------------
#  def scene_ref_to_pid( scene_ref ) do
#    case :ets.lookup(@ets_scenes_table, scene_ref ) do
#      [{_,{nil,_,_}}] -> nil
#      [{_,{pid,_,_}}] -> pid
#      [] -> nil
#    end
#  end

  #--------------------------------------------------------
#  def scene_pid_to_ref( pid ) do
#    case :ets.match(:_scenic_viewport_scenes_table_, {:"$1", {pid,:"_",:"_"}}) do
#      [[ref]] -> ref
#      _ -> nil
#    end
#  end

  #--------------------------------------------------------
#  def scene_ref_to_pids( scene_ref ) do
#    case :ets.lookup(@ets_scenes_table, scene_ref ) do
#      [{_,{nil,_,_}}] -> nil
#      [{_,{p0,p1,p2}}] -> {p0,p1,p2}
#      [] -> nil
#    end
#  end

  defp graph_ref_to_pid( nil ), do: nil
  defp graph_ref_to_pid( {scene_ref, _} ) do
    {:ok, pid} = Scene.to_pid( scene_ref )
    pid
  end

  #--------------------------------------------------------
#  def scene_active?( scene_ref ) when is_atom(scene_ref) or is_reference(scene_ref) do
#    case :ets.lookup(@ets_scenes_table, scene_ref ) do
#      [{_,{_,_,_,active,args}}] -> {active,args}
#      _ -> {:error, :not_found}
#    end
#  end

  #--------------------------------------------------------
  def graph_active?( {_,_} = graph_ref ) do
    case :ets.lookup(@ets_graph_activation_table, graph_ref ) do
      [{_,args}] -> {:active, args}
      _ -> :inactive
    end
  end

  #--------------------------------------------------------
  def list_scene_refs() do
    :ets.match(:_scenic_viewport_scenes_table_, {:"$1", :"_"})
    |> List.flatten()
    |> Enum.uniq()
  end

  #--------------------------------------------------------
  def list_graph_refs() do
    :ets.match(:_scenic_viewport_graphs_table_, {:"$1", :"_"})
    |> List.flatten()
    |> Enum.uniq()
  end

  #--------------------------------------------------------
  def list_scene_graph_refs( scene_ref ) do
    :ets.match(:_scenic_viewport_graphs_table_, {{scene_ref, :"$1"}, :"_"})
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.map( fn(id) -> {scene_ref, id} end)
  end

  #--------------------------------------------------------
  def list_scene_activations( scene_ref ) do
    :ets.match(@ets_graph_activation_table, {{scene_ref, :"$1"}, :"$2"})
    |> Enum.map( fn([id,args]) -> {id, args} end)
  end



  #--------------------------------------------------------
  def put_graph( graph, graph_id \\ nil, opts \\ [] )

  def put_graph( %Graph{primitive_map: p_map} = graph, graph_id, opts ) do
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
    GenServer.cast( @viewport, {:put_graph, min_graph, graph_id, scene_ref, opts} )

    # return the original graph, allowing it to be used in a pipeline
    graph
  end

  #--------------------------------------------------------
  def graph?( graph_ref ) do
    case :ets.lookup(@ets_graphs_table, graph_ref) do
      [] -> false
      _ -> true
    end
  end

  #--------------------------------------------------------
  def get_graph( graph_reference )

  def get_graph( {scene_ref, _} = graph_key ) when is_reference(scene_ref) or is_atom(scene_ref) do
    case :ets.lookup(@ets_graphs_table, graph_key) do
      [] -> nil
      [{_, graph}] -> graph
    end
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

  def capture_input( input_types, %Context{} = context ) when is_list(input_types) do
    GenServer.cast( @viewport, {:capture_input, input_types, context} )
  end
  def capture_input( input_type, context ), do: capture_input( [input_type], context )


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

      root_graph_ref: nil,
      input_captures: %{},
      hover_primitve: nil,

      max_depth: opts[:max_depth] || @max_depth,
      graph_table: :ets.new(@ets_graphs_table, [:named_table, read_concurrency: true]),
      scene_table: :ets.new(@ets_scenes_table, [:named_table, read_concurrency: true]),
      activation_table: :ets.new(@ets_graph_activation_table, [:named_table, read_concurrency: true])
    }

    {:ok, state}
  end


  #--------------------------------------------------------
#  defp activate_scene( scene_ref, pid, args ) when is_pid(pid) and
#  (is_reference(scene_ref) or is_atom(scene_ref)) do
#
#    case :ets.lookup(@ets_scenes_table, scene_ref ) do
#      [{_,{p0,p1,p2,_,_}}] ->
#        :ets.insert(@ets_scenes_table, {scene_ref, {p0,p1,p2, true, args}})
#      [] ->
#        :ets.insert(@ets_scenes_table, {scene_ref, {nil,nil,nil, true, args}})
#    end
#
#    GenServer.cast(pid, {:activate, args} )
#  end

  #--------------------------------------------------------
#  defp deactivate_scene( scene_ref ) when is_reference(scene_ref) or is_atom(scene_ref) do
#
#    case :ets.lookup(@ets_scenes_table, scene_ref ) do
#      [{_,{p0,p1,p2,_,_}}] ->
#        :ets.insert(@ets_scenes_table, {scene_ref, {p0,p1,p2, false, nil}})
#      [] ->
#        :ets.insert(@ets_scenes_table, {scene_ref, {nil,nil,nil, false, nil}})
#    end
#
#    scene_ref_to_pid( scene_ref )
#    |> GenServer.call( :deactivate )
#  end


  defp activate_graph( {scene_ref, id} = graph_ref, args ) do
    # get the graph
    case get_graph(graph_ref) do
      nil -> :ok
      graph ->
        # walk the members, of the graph and activate all the referenced graphs
        Enum.each( graph, fn
          {_, %{ data: {Primitive.SceneRef, child_graph}}} ->
            activate_graph( child_graph, args )
          _ -> :ok
        end)
    end
    
    # activate this graph
    case Scene.to_pid(scene_ref) do
      nil -> :ok
      {:ok, scene_pid} ->
        :ets.insert(@ets_graph_activation_table, {graph_ref, args})
        GenServer.call(scene_pid, {:activate, id, args})
    end
  end

  defp deactivate_graph( {scene_ref, id} = graph_ref ) do
    # get the graph
    case get_graph(graph_ref) do
      nil -> :ok
      graph ->
        # walk the members, of the graph and deactivate all the referenced graphs
        Enum.each( graph, fn
          {_, %{ data: {Primitive.SceneRef, child_graph}}} ->
            deactivate_graph( child_graph )
          _ -> :ok
        end)
    end
    
    # deactivate this graph
    case scene_ref_to_pid(scene_ref) do
      nil -> :ok
      scene_pid ->
        record_graph_deactivation( graph_ref )
        :ets.delete(@ets_graph_activation_table, graph_ref)
        GenServer.call(scene_pid, {:deactivate, id})
    end
  end


  defp internal_call_scene( scene_ref, msg, do_after ) when is_function(do_after, 1) do
    
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
      [{_,{^pid,_,_}}] -> nil

        # get all the graphs associated with this scene
        graphs = list_scene_graph_refs( scene_ref )

        # delete the graphs associated with this scene
        Enum.each( graphs, fn(graph_ref) ->
          Driver.cast({:delete_graph, graph_ref})
          :ets.delete(@ets_graphs_table, graph_ref)
        end)

        # unregister the scene itself
        :ets.delete(@ets_scenes_table, scene_ref)

        # delete the recorded activations
        list = :ets.match(@ets_graph_activation_table, {{scene_ref, :"$1"}, :"_"})

        # clean up and return the state
        Enum.reduce(graphs, state, fn(graph_ref, s)->
          s
          |> Utilities.Map.delete_in( [:raw_scene_refs, graph_ref] )
          |> Utilities.Map.delete_in( [:dyn_scene_refs, graph_ref] )
        end)

      _ ->
        # either not there, or claimed by another scene
        state
    end

    {:noreply, state}
  end


  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  def handle_cast( {:register_scene, scene_ref, registration}, state ) do
    :ets.insert(@ets_scenes_table, {scene_ref, registration})
    Process.monitor( registration.pid )
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast( {:request_scene, to_pid}, %{root_graph_ref: graph_ref} = state ) do
    GenServer.cast( to_pid, {:set_root, graph_ref} )
    {:noreply, state}
  end

  #--------------------------------------------------------
  # set a scene to be the new root
  def handle_cast( {:set_scene, scene, activate_args},
  %{root_graph_ref: old_root} = state ) do

    # reset all activations
    :ets.delete_all_objects(@ets_graph_activation_table)
    
    # get or start the pid for the new scene being set as the root
    {new_scene_pid, scene_ref} = case scene do
      {mod, init_data} ->
        ref = make_ref()
        :ets.insert(@ets_graph_activation_table, {{ref, nil}, activate_args})

        {:ok, scene_pid} = mod.start_child_scene( @dynamic_scenes, ref, init_data )
        
        { scene_pid, ref}

      # the scene is managed externally
      name when is_atom(name) ->
        {Process.whereis( name ), name}
    end
    graph_ref = {scene_ref, nil}

    # record that this is the new current scene
    state = state
    |> Map.put( :root_graph_ref, graph_ref )
    |> Map.put( :hover_primitve, nil )
    |> Map.put( :input_captures, %{} )
    |> Map.put( :dynamic_scenes, %{} )


    # activate the new root graph
#    activate_graph( graph_ref, activate_args )

    # send a reset message to the drivers
    Driver.cast( {:set_root, graph_ref} )

    # tear down the old scene
    with  {scene_ref, _} <- old_root,
      {:ok, scene_pid} <- Scene.to_pid(scene_ref) do
      Task.start fn ->
        GenServer.call( scene_pid, :deactivate )
        Scene.stop( scene_ref )
      end
    end

    {:noreply, state}
  end

  #--------------------------------------------------------
  # before putting the graph, we need to manage any dynamic scenes it
  # reference. This is really the main point of the viewport. The drivers
  # shouldn't have any knowledge of the actual processes used and only
  # refer to graphs by unified keys
  def handle_cast( {:put_graph, graph, graph_id, scene_ref, opts}, %{
    raw_scene_refs: raw_scene_refs, dyn_scene_refs: dyn_scene_refs
  } = state ) do
    graph_ref = {scene_ref, graph_id}

    # get the old refs
    old_raw_refs =  Map.get( raw_scene_refs, graph_ref, %{} )

    # build a list of the dynamic scene references in this graph
    new_raw_refs = Enum.reduce( graph, %{}, fn
      {uid,%{ data: {Primitive.SceneRef, {{mod, init_data}, nil}}}}, nr ->
        Map.put(nr, uid, {mod, init_data})
      # not a ref. ignore it
      _, nr -> nr
    end)

    # get the difference script between the raw refs
    raw_diff = Utilities.Map.difference( old_raw_refs, new_raw_refs )

    # get the old, resolved dynamic scene refs
    old_dyn_refs = Map.get( dyn_scene_refs, graph_ref, %{} )

    # Enumerate the old refs, using the difference script to determine
    # what to start or stop.
    new_dyn_refs = Enum.reduce(raw_diff, old_dyn_refs, fn
      {:put, uid, {mod, init_data}}, refs ->     # start this dynamic scene

        # get the host scene's dynamic scene supervisor
#        {:ok, dynamic_pid} = Scene.child_supervisor_pid( scene_ref )

        # make a new, scene ref
        new_scene_ref = make_ref()

        case graph_active?( graph_ref ) do
          {:active, args} ->
            :ets.insert(@ets_graph_activation_table, {{new_scene_ref, nil}, args})
          _ -> :ok
        end

        # start up the new child scene
        {:ok, pid} = mod.start_child_scene(
          scene_ref,
          new_scene_ref,
          init_data
        )

        # build the new graph_ref for the new scene
        new_graph_ref = {new_scene_ref, nil}

        # add the this ref for next time
        Map.put(refs, uid, new_graph_ref)

      {:del, uid}, refs ->                      # stop this dynaic scene
        # get the old dynamic graph reference
        graph_ref = old_dyn_refs[uid]

        # get the pid for this dynamic graph
        scene_pid = graph_ref_to_pid( graph_ref )
        # send the optional deactivate message and terminate. ok to be async
        Task.start fn ->
          GenServer.call( scene_pid, :deactivate )
          Scene.terminate( scene_pid )
        end

        # remove the reference from the old refs
        Map.delete(refs, uid)
    end)

    # take all the new refs and insert them back into the graph, so that they are
    # nice and normalized for the drivers
    graph = Enum.reduce(new_dyn_refs, graph, fn({uid, graph_ref}, g)->
      put_in(g, [uid, :data], {Primitive.SceneRef, graph_ref})
    end)

    # store the refs for next time
    state = put_in(state, [:raw_scene_refs, graph_ref], new_raw_refs)
    state = put_in(state, [:dyn_scene_refs, graph_ref], new_dyn_refs)

    # insert the graph into the etstable
    resp = :ets.insert(@ets_graphs_table, {graph_ref, graph})

    # if requested, activate the graph
    if Enum.member?(opts, :activate) do
      activate_graph( graph_ref, opts[:activate] )
    end

    # tell the drivers about the updated graph
    Driver.cast( {:put_graph, graph_ref} )

    # store the dyanamic scenes references
    {:noreply, state}
  end








  #--------------------------------------------------------
  # ignore input until a scene has been set
  def handle_cast( {:input, _}, %{root_scene_pid: nil} = state ) do
    {:noreply, state}
  end

  #--------------------------------------------------------
  # Input handling is enough of a beast to put move it into it's own section below
  # bottom of this file.
  def handle_cast( {:input, {input_type, _} = input_event}, 
  %{input_captures: input_captures} = state ) do
    case Map.get(input_captures, input_type) do
      nil ->
        # regular input handling
        do_handle_input(input_event, state)

      context ->
        # captive input handling
        do_handle_captured_input(input_event, context, state)
    end
  end

  #--------------------------------------------------------
  # capture a type of input
  def handle_cast( {:capture_input, input_types, context},
  %{input_captures: captures} = state ) do
    captures = Enum.reduce(input_types, captures, fn(input_type, ic)->
      Map.put( ic, input_type, context )
    end)
    {:noreply, %{state | input_captures: captures}}
  end

  #--------------------------------------------------------
  # release a captured type of input
  def handle_cast( {:release_input, input_types},
  %{input_captures: captures} = state ) do
    captures = Enum.reduce(input_types, captures, fn(input_type, ic)->
      Map.delete(ic, input_type)
    end)
    {:noreply, %{state | input_captures: captures}}
  end


  #============================================================================
  # input handling



  #============================================================================
  # captured input handling
  # mostly events get sent straight to the capturing scene. Common events that
  # have an x,y point, get transformed into the scene's requested coordinate space.

  defp do_handle_captured_input( event, context, state )

#  defp do_handle_captured_input( _, nil, _, state ), do: {:noreply, state}
#  defp do_handle_captured_input( _, _, nil, state ), do: {:noreply, state}

  #--------------------------------------------------------
  defp do_handle_captured_input({:cursor_button, {button, action, mods, point}}, state ) do
    uid = case find_by_captured_point( point, context ) do
      nil -> nil
      {uid, point} -> uid
    end

    scene_ref_to_pid(context.graph_ref, state)
    |> GenServer.cast(
      {
        :input,
        { :cursor_button, {button, action, mods, point}},
        Map.put(context, :uid, uid)
      })
    {:noreply, state}
  end



  #--------------------------------------------------------
  defp do_handle_captured_input( {:cursor_scroll, {offset, point}}, context,
  %{max_depth: max_depth} = state ) do
    {uid, point} = case find_by_captured_point( point, context, max_depth ) do
      nil -> {nil, point}
      r -> r
    end

    graph_ref_to_pid(context.graph_ref)
    |> GenServer.cast(
      {
        :input,
        {:cursor_scroll, {offset, point}},
        Map.put(context, :uid, uid)
      })
    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_enter is only sent to the root scene
  defp do_handle_captured_input( {:cursor_enter, point}, context,
  %{max_depth: max_depth} = state ) do
    {uid, point} = case find_by_captured_point( point, context, max_depth ) do
      nil -> {nil, point}
      r -> r
    end

    graph_ref_to_pid( context.graph_ref )
    |> GenServer.cast(
      {
        :input,
        {:cursor_enter, point},
        Map.put(context, :uid, uid)
      })
    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_exit is only sent to the root scene
  defp do_handle_captured_input( {:cursor_exit, point}, context,
  %{max_depth: max_depth} = state ) do
    {uid, point} = case find_by_captured_point( point, context, max_depth ) do
      nil -> {nil, point}
      r -> r
    end

    graph_ref_to_pid( context.graph_ref )
    |> GenServer.cast(
      {
        :input,
        {:cursor_enter, point},
        Map.put(context, :uid, uid)
      })
    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_enter is only sent to the root scene
  defp do_handle_captured_input( {:cursor_pos, point} = msg, context,
  %{root_graph_ref: root_ref, max_depth: max_depth} = state ) do
    case find_by_captured_point( point, context, max_depth ) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        state = send_primitive_exit_message(state)
        graph_ref_to_pid( root_ref )
        |> GenServer.cast({:input, msg, Map.put(context, :uid, nil)} )
        {:noreply, state}

      {uid, point} ->
        # get the graph key, so we know what scene to send the event to
        state = send_enter_message( uid, context.graph_ref, state, context.event_chain )
        graph_ref_to_pid( context.graph_ref )
        |> GenServer.cast(
          {
            :input,
            {:cursor_pos, point},
            Map.put(context, :uid, uid)
          })
        {:noreply, state}
    end
  end


  #--------------------------------------------------------
  # all events that don't need a point transformed
  defp do_handle_captured_input( event, context, state ) do
    graph_ref_to_pid( context.graph_ref )
    |> GenServer.cast(
      { :input, event, Map.put(context, :uid, nil) })
    {:noreply, state}
  end


  #============================================================================
  # regular input handling

  # note. if at any time a scene wants to collect all the raw input and avoid
  # this filtering mechanism, it can register directly for the input

  defp do_handle_input( event, state )

  #--------------------------------------------------------
  # text codepoint input is only sent to the scene with the input focus.
  # If no scene has focus, then send the codepoint to the root scene
#  defp do_handle_input( {:codepoint, _} = msg, state ) do
#    send_input_to_focused_scene( msg, state )
#    {:noreply, state}
#  end

  #--------------------------------------------------------
  # key press input is only sent to the scene with the input focus.
  # If no scene has focus, then send the codepoint to the root scene
#  defp do_handle_input( {:key, _} = msg, state ) do
#    send_input_to_focused_scene( msg, state )
#    {:noreply, state}
#  end

  #--------------------------------------------------------
  # key press input is only sent to the scene with the input focus.
  # If no scene has focus, then send the codepoint to the root scene
  defp do_handle_input( {:cursor_button, {button, action, mods, point}} = msg,
  %{root_graph_ref: root_ref} = state ) do
    case find_by_screen_point( point, state ) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        graph_ref_to_pid( root_ref )
        |> GenServer.cast(
          {
            :input,
            msg,
            %Context{ graph_ref: root_ref }
          })

      {point, {uid, graph_ref}, {tx, inv_tx}, event_chain} ->
        graph_ref_to_pid( graph_ref )
        |> GenServer.cast(
          {
            :input,
            {:cursor_button, {button, action, mods, point}},
            %Context{
              graph_ref: graph_ref,
              uid: uid,
              tx: tx, inverse_tx: inv_tx,
              event_chain: event_chain
            }
          })
    end
    {:noreply, state}
  end

  #--------------------------------------------------------
  # key press input is only sent to the scene with the input focus.
  # If no scene has focus, then send the codepoint to the root scene
  defp do_handle_input( {:cursor_scroll, {offset, point}} = msg,
  %{root_graph_ref: root_ref} = state ) do

    case find_by_screen_point( point, state ) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        graph_ref_to_pid( root_ref )
        |> GenServer.cast( {:input, msg, %{graph_ref: root_ref}} )

      {point, {uid, graph_ref}, {tx, inv_tx}, event_chain} ->
        # get the graph key, so we know what scene to send the event to
        graph_ref_to_pid( graph_ref )
        |> GenServer.cast(
          {
            :input,
            {:cursor_scroll, {offset, point}},
            %Context{
              graph_ref: graph_ref,
              uid: uid,
              tx: tx, inverse_tx: inv_tx,
              event_chain: event_chain
            }
          })
    end
    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_enter is only sent to the root scene
  defp do_handle_input( {:cursor_pos, point} = msg,
  %{root_graph_ref: root_ref} = state ) do
    state = case find_by_screen_point( point, state ) do
      nil ->
        # no uid found. let the root scene handle the event
        # we already know the root scene has identity transforms
        state = send_primitive_exit_message(state)
        graph_ref_to_pid( root_ref )
        |> GenServer.cast( {:input, msg, %Context{graph_ref: root_ref}} )
        state

      {point, {uid, graph_ref}, _, event_chain} ->
        # get the graph key, so we know what scene to send the event to
        state = send_enter_message( uid, graph_ref, state, event_chain )
        graph_ref_to_pid( graph_ref )
        |> GenServer.cast(
          {
            :input,
            {:cursor_pos, point},
            %Context{graph_ref: graph_ref, uid: uid, event_chain: event_chain}
          })
        state
    end

    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_enter is only sent to the root scene so no need to transform it
  defp do_handle_input( {:viewport_enter, _} = msg,
  %{root_graph_ref: root_ref} = state ) do
    graph_ref_to_pid( root_ref )
    |> GenServer.cast(
      {
        :input,
        msg,
         %Context{ graph_ref: root_ref }
      })
    {:noreply, state}
  end

  #--------------------------------------------------------
  # Any other input (non-standard, generated, etc) get sent to the root scene
  defp do_handle_input( msg, %{root_graph_ref: root_ref} = state ) do
    graph_ref_to_pid( root_ref )
    |> GenServer.cast(
      {
        :input,
        msg,
        %Context{graph_ref: root_ref}
      })
    {:noreply, state}
  end

  
  #============================================================================
  # regular input helper utilties

  defp send_primitive_exit_message( %{hover_primitve: nil} = state ), do: state
  defp send_primitive_exit_message( %{hover_primitve: {uid, graph_ref, event_chain}} = state ) do
    graph_ref_to_pid( graph_ref )
    |> GenServer.cast(
      {
        :input,
        {:cursor_exit, uid},
        %Context{uid: uid, graph_ref: graph_ref, event_chain: event_chain}
      })
    %{state | hover_primitve: nil}
  end

  defp send_enter_message( uid, graph_ref, %{hover_primitve: hover_primitve} = state, event_chain ) do
    # first, send the previous hover_primitve an exit message
    state = case hover_primitve do
      nil ->
        # no previous hover_primitive set. do not send an exit message
        state

      {^uid, ^graph_ref, _} ->
        # stil in the same hover_primitive. do not send an exit message
        state

      _ -> 
        # do send the exit message
        send_primitive_exit_message( state )
    end

    # send the new hover_primitve an enter message
    state = case state.hover_primitve do
      nil ->
        # yes. setting a new one. send it.
        graph_ref_to_pid( graph_ref )
        |> GenServer.cast(
          {
            :input,
            {:cursor_enter, uid},
            %Context{uid: uid, graph_ref: graph_ref, event_chain: event_chain}
          })
        %{state | hover_primitve: {uid, graph_ref, event_chain}}

      _ ->
        # not setting a new one. do nothing.
        state
    end
    state
  end



  #--------------------------------------------------------
  # find the indicated primitive in a single graph. use the incoming parent
  # transforms from the context
  defp find_by_captured_point( {x,y}, context, max_depth ) do
    case get_graph( context.graph_ref ) do
      nil ->
        nil
      graph ->
        do_find_by_captured_point( x, y, 0, graph, context.tx,
          context.inverse_tx, context.inverse_tx, max_depth )
    end
  end

  defp do_find_by_captured_point( _, _, _, graph, _, _, _, 0 ) do
    Logger.error "do_find_by_captured_point max depth"
    nil
  end

  defp do_find_by_captured_point( _, _, _, nil, _, _, _, _ ) do
    Logger.warn "do_find_by_captured_point nil graph"
    nil
  end

  defp do_find_by_captured_point( x, y, uid, graph,
  parent_tx, parent_inv_tx, graph_inv_tx, depth ) do
    # get the primitive to test
    case Map.get(graph, uid) do
      # do nothing if the primitive is hidden
      %{styles: %{hidden: true}} ->
        nil

      # if this is a group, then traverse the members backwards
      # backwards is important as the goal is to find the LAST item drawn
      # that is under the point in question
      %{data: {Primitive.Group, ids}} = p ->
        {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)
        ids
        |> Enum.reverse()
        |> Enum.find_value( fn(uid) ->
          do_find_by_captured_point( x, y, uid, graph, tx, inv_tx, graph_inv_tx, depth - 1 )
        end)

      # This is a regular primitive, test to see if it is hit
      %{data: {mod, data}} = p ->
        {_, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)

        # project the point by that inverse matrix to get the local point
        local_point = Matrix.project_vector( inv_tx, {x, y} )

        # test if the point is in the primitive
        case mod.contains_point?( data, local_point ) do
          true  ->
            # Return the point in graph coordinates. Local was good for the hit test
            # but graph coords makes more sense for the scene logic
            graph_point = Matrix.project_vector( graph_inv_tx, {x, y} )
            {uid, graph_point}

          false ->
            nil
        end
    end
  end


  #--------------------------------------------------------
  # find the indicated primitive in the graph given a point in screen coordinates.
  # to do this, we need to project the point into primitive local coordinates by
  # projecting it with the primitive's inverse final matrix.
  # 
  # Since the last primitive drawn is always on top, we should walk the tree
  # backwards and return the first hit we find. We could just reduct the whole
  # thing and return the last one found (that was my first try), but this is
  # more efficient as we can stop as soon as we find the first one.
  defp find_by_screen_point( {x,y},
  %{root_graph_ref: root_graph, max_depth: depth} = state ) do
    identity = {@identity, @identity}
    event_chain = case graph_ref_to_pid( root_graph ) do
      nil -> []
      pid -> [pid]
    end
    do_find_by_screen_point( x, y, 0, root_graph, get_graph(root_graph),
      identity, identity, event_chain, depth )
  end


  defp do_find_by_screen_point( _, _, _, _, _, _, _, _, 0 ) do
    Logger.error "do_find_by_screen_point max depth"
    nil
  end


  defp do_find_by_screen_point( _, _, _, graph_ref, nil, _, _, _, _ ) do
    # for whatever reason, the graph hasn't been put yet. just return nil
    nil
  end

  defp do_find_by_screen_point( x, y, uid, graph_ref, graph,
    {parent_tx, parent_inv_tx}, {graph_tx, graph_inv_tx}, event_chain, depth ) do

    # get the primitive to test
    case graph[uid] do
      # do nothing if the primitive is hidden
      %{styles: %{hidden: true}} ->
        nil

      # if this is a group, then traverse the members backwards
      # backwards is important as the goal is to find the LAST item drawn
      # that is under the point in question
      %{data: {Primitive.Group, ids}} = p ->
        {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)
        ids
        |> Enum.reverse()
        |> Enum.find_value( fn(uid) ->
          do_find_by_screen_point(
            x, y, uid, graph_ref, graph,
            {tx, inv_tx}, {graph_tx, graph_inv_tx},
            event_chain, depth - 1
          )
        end)

      # if this is a SceneRef, then traverse into the next graph
      %{data: {Primitive.SceneRef, {scene_ref, _} = ref_id}} = p ->
        case Scene.to_pid( scene_ref ) do
          {:ok, scene_pid} ->
            {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)
            do_find_by_screen_point(x, y, 0, ref_id, get_graph(ref_id),
              {tx, inv_tx}, {tx, inv_tx},
              [scene_pid | event_chain], depth - 1
            )
          _ ->
            nil
        end

      # This is a regular primitive, test to see if it is hit
      %{data: {mod, data}} = p ->
        {_, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)

        # project the point by that inverse matrix to get the local point
        local_point = Matrix.project_vector( inv_tx, {x, y} )

        # test if the point is in the primitive
        case mod.contains_point?( data, local_point ) do
          true  ->
            # Return the point in graph coordinates. Local was good for the hit test
            # but graph coords makes more sense for the scene logic
            graph_point = Matrix.project_vector( graph_inv_tx, {x, y} )
            {graph_point, {uid, graph_ref}, {graph_tx, graph_inv_tx}, event_chain}
          false -> nil
        end
    end
  end


  defp calc_transforms(p, parent_tx, parent_inv_tx) do
    p
    |> Map.get(:transforms, nil)
    |> Primitive.Transform.calculate_local()
    |> case do
      nil ->
        # No local transform. This will often be the case.
        {parent_tx, parent_inv_tx}

      tx ->
        # there was a local transform. multiply it into the parent
        # then also calculate a new inverse transform
        tx = Matrix.mul( parent_tx, tx )
        inv_tx = Matrix.invert( tx )
        {tx, inv_tx}
    end
  end


  defp get_scene( scene_ref )


end





