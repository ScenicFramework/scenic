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

  # the graph reference is same as the scene itself
  def put_graph( %Graph{primitive_map: p_map}, nil ) do
    case Registry.lookup(:viewport_registry, { :scene, self()} ) do
      [] ->
        # not part of a registered scene
        {:error, :invalid_reference}

      [{_, reference}] ->
        graph = Enum.reduce(p_map, %{}, fn({uid, p}, acc) ->
          Map.put(acc, uid, Primitive.minimal(p))
        end)
        |> prepare_graph_refs( reference )
        {:ok, _} = Registry.register(:viewport_registry, {:graph, reference}, graph )
        Driver.cast({:put_graph, reference})
        :ok
    end
  end

  def put_graph( %Graph{primitive_map: p_map}, reference )
  when is_reference(reference) do
    graph = Enum.reduce(p_map, %{}, fn({uid, p}, acc) ->
      Map.put(acc, uid, Primitive.minimal(p))
    end)
    |> prepare_graph_refs( reference )
    {:ok, _} = Registry.register(:viewport_registry, {:graph, reference}, graph )
    Driver.cast({:put_graph, reference})
    :ok
  end

  #--------------------------------------------------------
  def register_scene( scene_reference )
  when is_reference(scene_reference) or is_atom(scene_reference) do
    {:ok, _} = Registry.register(:viewport_registry, {:scene, self()}, scene_reference )
    {:ok, _} = Registry.register(:viewport_registry, {:scene_ref, scene_reference}, nil )
  end


  #--------------------------------------------------------
  def get_graph( reference ) when is_reference(reference) or is_atom(reference) do
    case Registry.lookup(:viewport_registry, {:graph, reference}) do
      [] -> nil
      [{_, graph}] -> graph
    end
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
      max_depth: opts[:max_depth] || @max_depth
    }

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

    # send this graph to the drivers
    Driver.cast( {:set_graph, {graph_id, graph}} )

    {:noreply, state}
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
  # Input handling is enough of a beast to put move it into it's own section at the
  # bottom of this file.
  def handle_cast( {:input, {input_type, _} = input_event}, 
  %{input_captures: input_captures} = state ) do
    case Map.get(input_captures, input_type) do
      nil ->
        # regular input handling
        do_handle_input(input_event, state)

      context ->
        graph_id = get_graph_key(state, {context.scene_pid, context.scene_id})
        graph = get_in(state, [:graphs, graph_id])
        # captive input handling
        do_handle_captured_input(input_event, graph, context, state)
    end
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
    DynamicSupervisor.start_child(@dynamic_scenes, {Scene, {mod, nil, opts}})
  end



  #============================================================================
  # captured input handling
  # mostly events get sent straight to the capturing scene. Common events that
  # have an x,y point, get transformed into the scene's requested coordinate space.

  defp do_handle_captured_input( event, graph, context, state )

#  defp do_handle_captured_input( _, nil, _, state ), do: {:noreply, state}
#  defp do_handle_captured_input( _, _, nil, state ), do: {:noreply, state}

  #--------------------------------------------------------
  defp do_handle_captured_input( {:cursor_button, {button, action, mods, point}},
  graph, context, state ) do

    {uid, point} = find_by_captured_point( point, graph, context )

    GenServer.cast(context.scene_pid,
      {
        :input,
        { :cursor_button, {button, action, mods, point}},
        Map.put(context, :uid, uid)
      })
    {:noreply, state}
  end



  #--------------------------------------------------------
  defp do_handle_captured_input( {:cursor_scroll, {offset, point}},
  graph, context, state ) do

    {uid, point} = find_by_captured_point( point, graph, context )

    GenServer.cast(context.scene_pid,
      {
        :input,
        {:cursor_scroll, {offset, point}},
        Map.put(context, :uid, uid)
      })
    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_enter is only sent to the root scene
  defp do_handle_captured_input( {:cursor_enter, {entered?, point}},
  graph, context, state ) do

    {uid, point} = find_by_captured_point( point, graph, context )

    GenServer.cast(context.scene_pid,
      {
        :input,
        {:cursor_enter, {entered?, point}},
        Map.put(context, :uid, uid)
      })
    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_enter is only sent to the root scene
  defp do_handle_captured_input( {:cursor_pos, point},
  graph, context, state ) do
    
    {uid, point} = find_by_captured_point( point, graph, context )

    GenServer.cast(context.scene_pid,
      {
        :input,
        {:cursor_pos, point},
        Map.put(context, :uid, uid)
      })
    {:noreply, state}
  end


  #--------------------------------------------------------
  # all events that don't need a point transformed
  defp do_handle_captured_input( event, _, context, state ) do
    GenServer.cast(context.scene_pid,
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
  %{graphs: graphs} = state ) do
    case find_by_screen_point( point, graphs ) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        {scene_pid, scene_id} = get_graph_key(state, 0)
        GenServer.cast(scene_pid,
          {
            :input,
            msg,
            %Context{ scene_pid: scene_pid, scene_id: scene_id }
          })

      {point, {uid, graph_id}, {tx, inv_tx}} ->
        # get the graph key, so we know what scene to send the event to
        {scene_pid, scene_id} = get_graph_key(state, graph_id)

        GenServer.cast(scene_pid,
          {
            :input,
            {:cursor_button, {button, action, mods, point}},
            %Context{
              scene_pid: scene_pid,
              scene_id: scene_id,
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
  %{graphs: graphs} = state ) do
    case find_by_screen_point( point, graphs ) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        {scene_pid, scene_id} = get_graph_key(state, 0)
        GenServer.cast(scene_pid, {:input, msg, %{id: scene_id}})

      {point, {uid, graph_id}, {tx, inv_tx}} ->
        # get the graph key, so we know what scene to send the event to
        {scene_pid, scene_id} = get_graph_key(state, graph_id)

        GenServer.cast(scene_pid,
          {
            :input,
            {:cursor_scroll, {offset, point}},
            %Context{
              scene_pid: scene_pid,
              scene_id: scene_id,
              uid: uid,
              tx: tx, inverse_tx: inv_tx
            }
          })
    end
    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_enter is only sent to the root scene so no need to transform it
  defp do_handle_input( {:viewport_enter, _} = msg, state ) do
    {scene_pid, scene_id} = get_graph_key(state, 0)
    GenServer.cast(scene_pid,
      {
        :input,
        msg,
         %Context{ scene_pid: scene_pid, scene_id: scene_id }
      })
    {:noreply, state}
  end

  #--------------------------------------------------------
  # cursor_enter is only sent to the root scene
  defp do_handle_input( {:cursor_pos, point} = msg,
  %{graphs: graphs} = state ) do
    state = case find_by_screen_point( point, graphs ) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        state = send_primitive_exit_message(state)
        {scene_pid, scene_id} = get_graph_key(state, 0)
        GenServer.cast(scene_pid, {:input, msg, %{id: scene_id}})
        state

      {point, {uid, graph_id}, _} ->
        # get the graph key, so we know what scene to send the event to
        {scene_pid, scene_id} = get_graph_key(state, graph_id)
        state = send_enter_message( uid, graph_id, state )
        GenServer.cast(scene_pid,
          {
            :input,
            {:cursor_pos, point},
            %Context{scene_pid: scene_pid, scene_id: scene_id, uid: uid}
          })
        state
    end

    {:noreply, state}
  end

  #--------------------------------------------------------
  # Any other input (non-standard, generated, etc) get sent to the root scene
  defp do_handle_input( msg, state ) do
    {scene_pid, scene_id} = get_graph_key(state, 0)
    GenServer.cast(scene_pid,
      {
        :input,
        msg,
        %Context{scene_pid: scene_pid, scene_id: scene_id}
      })
    {:noreply, state}
  end

  
  #============================================================================
  # regular input helper utilties

  defp send_primitive_exit_message( %{hover_primitve: nil} = state ), do: state
  defp send_primitive_exit_message( %{hover_primitve: {uid, graph_id}} = state ) do
    {scene_pid, scene_id} = get_graph_key(state, graph_id)
    GenServer.cast(scene_pid,
      {
        :input,
        {:cursor_exit, uid},
        %Context{uid: uid, scene_pid: scene_pid, scene_id: scene_id}
      })
    %{state | hover_primitve: nil}
  end

  defp send_enter_message( uid, graph_id, %{hover_primitve: hover_primitve} = state ) do

    # first, send the previous hover_primitve an exit message
    state = case hover_primitve do
      nil ->
        # no previous hover_primitive set. do not send an exit message
        state

      {^uid, ^graph_id} -> 
        # stil in the same hover_primitive. do not send an exit message
        state

      _ -> 
        # do send the exit message
        send_primitive_exit_message( state )
    end

    # send the new hover_primitve an enter message
    case state.hover_primitve do
      nil ->
        # yes. setting a new one. send it.
        {scene_pid, scene_id} = get_graph_key(state, graph_id)
        GenServer.cast(scene_pid,
          {
            :input,
            {:cursor_enter, uid},
            %Context{uid: uid, scene_pid: scene_pid, scene_id: scene_id}
          })
        %{state | hover_primitve: {uid, graph_id}}

      _ ->
        # not setting a new one. do nothing.
        state
    end
  end



  #--------------------------------------------------------
  # find the indicated primitive in a single graph. use the incoming parent
  # transforms from the context
  defp find_by_captured_point( {x,y}, graph, context ) do
    do_find_by_captured_point( x, y, 0, graph, context.tx, context.inverse_tx, context.inverse_tx )
  end

  defp do_find_by_captured_point( x, y, uid, graph, parent_tx, parent_inv_tx, graph_inv_tx ) do
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
          do_find_by_captured_point( x, y, uid, graph, tx, inv_tx, graph_inv_tx )
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
  defp find_by_screen_point( {x,y}, %{} = graphs ) do
    identity = {@identity, @identity}
    do_find_by_screen_point( x, y, 0, 0, graphs, identity, identity )
  end

  defp do_find_by_screen_point( x, y, uid, graph_id, graphs,
    {parent_tx, parent_inv_tx}, {graph_tx, graph_inv_tx} ) do
    # get the primitive to test
    case get_in(graphs, [graph_id, uid]) do
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
            x, y, uid, graph_id, graphs,
            {tx, inv_tx}, {graph_tx, graph_inv_tx}
          )
        end)

      # if this is a SceneRef, then traverse into the next graph
      %{data: {Primitive.SceneRef, ref_id}} = p ->
        {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)
        do_find_by_screen_point(x, y, 0, ref_id, graphs, {tx, inv_tx}, {tx, inv_tx} )

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
            {graph_point, {uid, graph_id}, {graph_tx, graph_inv_tx}}
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



  #--------------------------------------------------------
  defp prepare_graph_refs( graph, reference ) do
    # get the old graph, if any
    case get_graph( reference ) do
      nil ->
        # first time this graph is being set. can
        # just scan for SceneRefs and spin them up as needed
        Enum.reduce(graph, %{}, fn({uid,p},g)->
            p = ensure_scene_ref_started( p )
            Map.put(g, uid, p)
        end)

      old_graph ->
        # ugh. Need to examine changes becuase referenced graphs
        # may need to be spun up or down
        graph = Scenec.Utilities.Map.difference(old_graph, graph)
        |> Enum.reduce( graph, fn
          {:put, {uid, :data}, {SceneRef, ref} }, g ->
            ensure_scene_ref_stopped( old_graph[uid] )
            # a new reference is being put in place
            p = ensure_scene_ref_started( graph[uid] )
            Map.put(g, uid, p)

          {:del, {uid, :data}}, g ->
            # a primitive's data is being changed. See if it was a SceneRef
            ensure_scene_ref_stopped(old_graph[uid] )
            g

          {:del, uid}, g when is_integer(uid) ->
            # a primitive's being deleted. See if it was a SceneRef
            ensure_scene_ref_stopped( old_graph[uid] )
            g

          _, g ->
            # not a reference. do nothing
            g
        end)
    end

  end

  #--------------------------------------------------------
  defp ensure_scene_ref_started( %{data: {SceneRef, {mod, opts}}} = p ) do
    reference = make_ref()
    DynamicSupervisor.start_child(@dynamic_scenes, {Scene, {mod, reference, opts}})
    %{p | data: {SceneRef, reference}}
  end
  defp ensure_scene_ref_started( p ), do: p

  #--------------------------------------------------------
  defp ensure_scene_ref_stopped( %{data: {SceneRef, ref}} ) when is_reference(ref) do
    [{pid, _}] = Registry.lookup(:viewport_registry, {:scene_ref, ref} )
    # Attempt to spin down the scene. Will do nothing if it isn't dynamic
    DynamicSupervisor.terminate_child(@dynamic_scenes, pid)
  end
  defp ensure_scene_ref_deleted( _ ), do: :ok

end





