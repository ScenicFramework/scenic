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


  @ets_scenes_table       :_scenic_viewport_scenes_table_
  @ets_graphs_table       :_scenic_viewport_graphs_table_
  @ets_activation_table   :_scenic_viewport_activation_table_
#  @ets_startup_table      :_scenic_viewport_startup_table_

  defmodule Input.Context do
    alias Scenic.Math.MatrixBin, as: Matrix
    @identity         Matrix.identity()
    defstruct scene: nil, tx: @identity, inverse_tx: @identity, uid: nil
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
    GenServer.call( @viewport, {:put_graph, min_graph, scene_ref, opts} )

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

      setting_scene: nil,

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
        Driver.cast({:delete_graph, scene_ref})
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
#    Driver.cast( {:set_root, set_scene} )
#    {:noreply, %{state | setting_scene: nil}}
#  end
#
#  def handle_info({ref, {:set_complete, set_ref, complete_ref}},
#  %{setting_scene: {set_scene, completion_list}} = state) do
#    completion_list = List.delete(completion_list, complete_ref)
#    state = case completion_list do
#      [] ->
#        # setup is complete,send the message to the drivers
#        Driver.cast( {:set_root, set_scene} )
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
    Driver.cast( {:set_root, set_scene} )
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
        Driver.cast( {:set_root, set_scene} )
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

#        GenServer.cast(self(), {:start_dyn_scene, @dynamic_scenes, new_ref, mod, init_data})
#       {:ok, pid} = mod.start_child_scene( @dynamic_scenes, new_ref, init_data)
#        Scene.activate( new_ref, args )
        # start and activate the new scene
#        Task.async(fn ->
#          # activate the new scene
#          Scene.activate( new_ref, args )
#          # send the message to the drivers
##          Driver.cast( {:set_root, new_ref} )
#          {:set_complete, new_ref, new_ref}
#        end)

        state
        |> Map.put( :root_scene, new_ref )
        |> Map.put( :set_scene, {new_ref, args} )
        |> Map.put( :set_list, [new_ref] )

      # app supervised scene
      scene_ref when is_atom(scene_ref) ->
        # activate the scene
        Scene.activate( scene_ref, args, scene_ref )
        # activate the incoming scene
#        Task.async(fn ->
#          # activate the new graph here
#          Scene.activate( scene_ref, args )
#          # send the message to the drivers
##          Driver.cast( {:set_root, scene_ref} )
#          {:set_complete, scene_ref, nil}
#        end)
        state
        |> Map.put( :root_scene, scene_ref )
        |> Map.put( :set_scene, {scene_ref, args} )
        |> Map.put( :set_list, [] )
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
  def handle_call( {:put_graph, graph, scene_ref, opts}, _, %{
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

        # start the dynamic scene
#        GenServer.cast(self(), {:start_dyn_scene, scene_ref, new_scene_ref, mod, init_data})

        {:ok, _pid} = mod.start_child_scene( scene_ref, new_scene_ref, init_data)
        with {root, activation_args} <- set_scene do
          Scene.activate( new_scene_ref, activation_args, root )  
        end
      

#        mod.start_child_scene( scene_ref, new_scene_ref, init_data )
#        with {:ok, args} <- Scene.get_activation( scene_ref ) do
#          Scene.activate( scene_ref, args )
#          case setting_scene do
#            nil ->
#              # not setting a scene. no need for fancy async stuff
#              Task.start_link( fn->
#                # activate the new graph in an async task as it might call back in here
#                Scene.activate( scene_ref, args )
#              end)
#
#            {setting_scene, _} ->
#              # setting a scene. Use async to trigger the completion message
#              Task.async( fn->
#                # activate the new graph in an async task as it might call back in here
#                Scene.activate( scene_ref, args )
#                {:set_complete, setting_scene, new_scene_ref}
#              end)
#          end
#        end

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

    # if we are in the process of setting a scene, add any newly created scenes to the
    # set_list. This is so the drivers won't be notified until they have activated.
    state = case set_scene do
      nil -> state
      {root_scene, _} ->
        set_list = Enum.reduce(new_dyn_refs, set_list, fn({_, new_dyn_ref}, l)->
          [new_dyn_ref | l]
        end)
        Map.put(state, :set_list, set_list)
    end

    # store the refs for next time
    state = put_in(state, [:raw_scene_refs, scene_ref], new_raw_refs)
    state = put_in(state, [:dyn_scene_refs, scene_ref], new_dyn_refs)

    # insert the graph into the etstable
    :ets.insert(@ets_graphs_table, {scene_ref, graph})

    # tell the drivers about the updated graph
    Driver.cast( {:put_graph, scene_ref} )

    # store the dyanamic scenes references
    {:reply, :ok, state}
  end












  #--------------------------------------------------------
  # ignore input until a scene has been set
  def handle_cast( {:input, _}, %{root_scene: nil} = state ) do
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
  def handle_cast( {:capture_input, scene_ref, input_types},
  %{input_captures: captures} = state ) do
    captures = Enum.reduce(input_types, captures, fn(input_type, ic)->
      Map.put( ic, input_type, scene_ref )
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
  defp do_handle_captured_input({:cursor_button, {button, action, mods, point}}, context, state ) do
    uid = case find_by_captured_point( point, context, state[:max_depth] ) do
      nil -> nil
      {uid, point} -> uid
    end

    Scene.cast(context.scene,
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

    Scene.cast(context.scene,
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

    Scene.cast(context.scene,
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

    Scene.cast(context.scene,
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
  %{root_scene: root_scene, max_depth: max_depth} = state ) do
    case find_by_captured_point( point, context, max_depth ) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        state = send_primitive_exit_message(state)
        Scene.cast( root_scene, {:input, msg, Map.put(context, :uid, nil)} )
        {:noreply, state}

      {uid, point} ->
        # get the graph key, so we know what scene to send the event to
        state = send_enter_message( uid, context.scene, state )
        Scene.cast(context.scene,
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
    Scene.cast(context.scene,
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
  %{root_scene: root_scene} = state ) do
    case find_by_screen_point( point, state ) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        Scene.cast( root_scene,
          {
            :input,
            msg,
            %Context{ scene: root_scene }
          })

      {point, {uid, scene}, {tx, inv_tx}} ->
        Scene.cast( scene,
          {
            :input,
            {:cursor_button, {button, action, mods, point}},
            %Context{
              scene: scene,
              uid: uid,
              tx: tx, inverse_tx: inv_tx
            }
          })
    end
    {:noreply, state}
  end

  #--------------------------------------------------------
  # key press input is only sent to the scene with the input focus.
  # If no scene has focus, then send the codepoint to the root scene
  defp do_handle_input( {:cursor_scroll, {offset, point}} = msg,
  %{root_scene: root_scene} = state ) do

    case find_by_screen_point( point, state ) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        Scene.cast(root_scene, {:input, msg, %{graph_ref: root_scene}} )

      {point, {uid, scene}, {tx, inv_tx}} ->
        # get the graph key, so we know what scene to send the event to
        Scene.cast( scene,
          {
            :input,
            {:cursor_scroll, {offset, point}},
            %Context{
              scene: scene,
              uid: uid,
              tx: tx, inverse_tx: inv_tx,
            }
          })
    end
    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_enter is only sent to the root scene
  defp do_handle_input( {:cursor_pos, point} = msg,
  %{root_scene: root_scene} = state ) do
    state = case find_by_screen_point( point, state ) do
      nil ->
        # no uid found. let the root scene handle the event
        # we already know the root scene has identity transforms
        state = send_primitive_exit_message(state)
        Scene.cast(root_scene, {:input, msg, %Context{scene: root_scene}} )
        state

      {point, {uid, scene}, _} ->
        # get the graph key, so we know what scene to send the event to
        state = send_enter_message( uid, scene, state )
        Scene.cast( scene,
          {
            :input,
            {:cursor_pos, point},
            %Context{scene: scene, uid: uid}
          })
        state
    end

    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_enter is only sent to the root scene so no need to transform it
  defp do_handle_input( {:viewport_enter, _} = msg, %{root_scene: root_scene} = state ) do
    Scene.cast( root_scene,
      {
        :input,
        msg,
        %Context{ scene: root_scene }
      })
    {:noreply, state}
  end

  #--------------------------------------------------------
  # Any other input (non-standard, generated, etc) get sent to the root scene
  defp do_handle_input( msg, %{root_scene: root_scene} = state ) do
    Scene.cast( root_scene,
      {
        :input,
        msg,
        %Context{ scene: root_scene }
      })
    {:noreply, state}
  end

  
  #============================================================================
  # regular input helper utilties

  defp send_primitive_exit_message( %{hover_primitve: nil} = state ), do: state
  defp send_primitive_exit_message( %{hover_primitve: {uid, scene}} = state ) do
    Scene.cast( scene,
      {
        :input,
        {:cursor_exit, uid},
        %Context{uid: uid, scene: scene}
      })
    %{state | hover_primitve: nil}
  end

  defp send_enter_message( uid, scene, %{hover_primitve: hover_primitve} = state ) do
    # first, send the previous hover_primitve an exit message
    state = case hover_primitve do
      nil ->
        # no previous hover_primitive set. do not send an exit message
        state

      {^uid, ^scene} ->
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
        Scene.cast( scene,
          {
            :input,
            {:cursor_enter, uid},
            %Context{uid: uid, scene: scene}
          })
        %{state | hover_primitve: {uid, scene}}

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
    case get_graph( context.scene ) do
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
  defp find_by_screen_point( {x,y}, %{root_scene: root_scene, max_depth: depth} = state) do
    identity = {@identity, @identity}
    do_find_by_screen_point( x, y, 0, root_scene, get_graph(root_scene),
      identity, identity, depth )
  end


  defp do_find_by_screen_point( _, _, _, _, _, _, _, 0 ) do
    Logger.error "do_find_by_screen_point max depth"
    nil
  end


  defp do_find_by_screen_point( _, _, _, _, nil, _, _, _ ) do
    # for whatever reason, the graph hasn't been put yet. just return nil
    nil
  end

  defp do_find_by_screen_point( x, y, uid, scene, graph,
    {parent_tx, parent_inv_tx}, {graph_tx, graph_inv_tx}, depth ) do

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
            x, y, uid, scene, graph,
            {tx, inv_tx}, {graph_tx, graph_inv_tx}, depth - 1
          )
        end)

      # if this is a SceneRef, then traverse into the next graph
      %{data: {Primitive.SceneRef, scene_ref}} = p ->
        case Scene.to_pid( scene_ref ) do
          {:ok, scene_pid} ->
            {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)
            do_find_by_screen_point(x, y, 0, scene_ref, get_graph(scene_ref),
              {tx, inv_tx}, {tx, inv_tx}, depth - 1
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
            {graph_point, {uid, scene}, {graph_tx, graph_inv_tx}}
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





