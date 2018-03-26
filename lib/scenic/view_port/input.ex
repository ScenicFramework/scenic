#
#  Created by Boyd Multerer on 11/05/17.
#  Rewritten: 3/25/2018
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# The main helpers and organizers for input


defmodule Scenic.ViewPort.Input do

  defmodule Context do
    alias Scenic.Math.MatrixBin, as: Matrix
    @identity         Matrix.identity()
    defstruct tx: @identity, inverse_tx: @identity, uid: nil, graph_ref: nil
  end



  #============================================================================
  # captured input handling
  # mostly events get sent straight to the capturing scene. Common events that
  # have an x,y point, get transformed into the scene's requested coordinate space.

#  defp do_handle_captured_input( event, graph, context, state )
#
##  defp do_handle_captured_input( _, nil, _, state ), do: {:noreply, state}
##  defp do_handle_captured_input( _, _, nil, state ), do: {:noreply, state}
#
#  #--------------------------------------------------------
#  defp do_handle_captured_input( {:cursor_button, {button, action, mods, point}},
#  graph, context, state ) do
#
#    {uid, point} = find_by_captured_point( point, graph, context )
#
#    GenServer.cast(context.scene_pid,
#      {
#        :input,
#        { :cursor_button, {button, action, mods, point}},
#        Map.put(context, :uid, uid)
#      })
#    {:noreply, state}
#  end
#
#
#
#  #--------------------------------------------------------
#  defp do_handle_captured_input( {:cursor_scroll, {offset, point}},
#  graph, context, state ) do
#
#    {uid, point} = find_by_captured_point( point, graph, context )
#
#    GenServer.cast(context.scene_pid,
#      {
#        :input,
#        {:cursor_scroll, {offset, point}},
#        Map.put(context, :uid, uid)
#      })
#    {:noreply, state}
#  end
#
#  #--------------------------------------------------------
#  # cursor_enter is only sent to the root scene
#  defp do_handle_captured_input( {:cursor_enter, point},
#  graph, context, state ) do
#
#    {uid, point} = find_by_captured_point( point, graph, context )
#
#    GenServer.cast(context.scene_pid,
#      {
#        :input,
#        {:cursor_enter, point},
#        Map.put(context, :uid, uid)
#      })
#    {:noreply, state}
#  end
#
#  #--------------------------------------------------------
#  # cursor_exit is only sent to the root scene
#  defp do_handle_captured_input( {:cursor_exit, point},
#  graph, context, state ) do
#
#    {uid, point} = find_by_captured_point( point, graph, context )
#
#    GenServer.cast(context.scene_pid,
#      {
#        :input,
#        {:cursor_enter, point},
#        Map.put(context, :uid, uid)
#      })
#    {:noreply, state}
#  end
#
#  #--------------------------------------------------------
#  # cursor_enter is only sent to the root scene
#  defp do_handle_captured_input( {:cursor_pos, point},
#  graph, context, state ) do
#    
#    {uid, point} = find_by_captured_point( point, graph, context )
#
#    GenServer.cast(context.scene_pid,
#      {
#        :input,
#        {:cursor_pos, point},
#        Map.put(context, :uid, uid)
#      })
#    {:noreply, state}
#  end
#
#
#  #--------------------------------------------------------
#  # all events that don't need a point transformed
#  defp do_handle_captured_input( event, _, context, state ) do
#    GenServer.cast(context.scene_pid,
#      { :input, event, Map.put(context, :uid, nil) })
#    {:noreply, state}
#  end
#
#
#  #============================================================================
#  # regular input handling
#
#  # note. if at any time a scene wants to collect all the raw input and avoid
#  # this filtering mechanism, it can register directly for the input
#
#  defp do_handle_input( event, state )
#
#  #--------------------------------------------------------
#  # text codepoint input is only sent to the scene with the input focus.
#  # If no scene has focus, then send the codepoint to the root scene
##  defp do_handle_input( {:codepoint, _} = msg, state ) do
##    send_input_to_focused_scene( msg, state )
##    {:noreply, state}
##  end
#
#  #--------------------------------------------------------
#  # key press input is only sent to the scene with the input focus.
#  # If no scene has focus, then send the codepoint to the root scene
##  defp do_handle_input( {:key, _} = msg, state ) do
##    send_input_to_focused_scene( msg, state )
##    {:noreply, state}
##  end
#
#  #--------------------------------------------------------
#  # key press input is only sent to the scene with the input focus.
#  # If no scene has focus, then send the codepoint to the root scene
#  defp do_handle_input( {:cursor_button, {button, action, mods, point}} = msg,
#  %{graphs: graphs} = state ) do
#    case find_by_screen_point( point, graphs ) do
#      nil ->
#        # no uid found. let the root scene handle the click
#        # we already know the root scene has identity transforms
#        {scene_pid, scene_id} = get_graph_key(state, 0)
#        GenServer.cast(scene_pid,
#          {
#            :input,
#            msg,
#            %Context{ scene_pid: scene_pid, scene_id: scene_id }
#          })
#
#      {point, {uid, graph_id}, {tx, inv_tx}} ->
#        # get the graph key, so we know what scene to send the event to
#        {scene_pid, scene_id} = get_graph_key(state, graph_id)
#
#        GenServer.cast(scene_pid,
#          {
#            :input,
#            {:cursor_button, {button, action, mods, point}},
#            %Context{
#              scene_pid: scene_pid,
#              scene_id: scene_id,
#              uid: uid,
#              tx: tx, inverse_tx: inv_tx
#            }
#          })
#    end
#    {:noreply, state}
#  end
#
#  #--------------------------------------------------------
#  # key press input is only sent to the scene with the input focus.
#  # If no scene has focus, then send the codepoint to the root scene
#  defp do_handle_input( {:cursor_scroll, {offset, point}} = msg,
#  %{graphs: graphs} = state ) do
#    case find_by_screen_point( point, graphs ) do
#      nil ->
#        # no uid found. let the root scene handle the click
#        # we already know the root scene has identity transforms
#        {scene_pid, scene_id} = get_graph_key(state, 0)
#        GenServer.cast(scene_pid, {:input, msg, %{id: scene_id}})
#
#      {point, {uid, graph_id}, {tx, inv_tx}} ->
#        # get the graph key, so we know what scene to send the event to
#        {scene_pid, scene_id} = get_graph_key(state, graph_id)
#
#        GenServer.cast(scene_pid,
#          {
#            :input,
#            {:cursor_scroll, {offset, point}},
#            %Context{
#              scene_pid: scene_pid,
#              scene_id: scene_id,
#              uid: uid,
#              tx: tx, inverse_tx: inv_tx
#            }
#          })
#    end
#    {:noreply, state}
#  end
#
#  #--------------------------------------------------------
#  # cursor_enter is only sent to the root scene so no need to transform it
#  defp do_handle_input( {:viewport_enter, _} = msg, state ) do
#    {scene_pid, scene_id} = get_graph_key(state, 0)
#    GenServer.cast(scene_pid,
#      {
#        :input,
#        msg,
#         %Context{ scene_pid: scene_pid, scene_id: scene_id }
#      })
#    {:noreply, state}
#  end
#
#  #--------------------------------------------------------
#  # cursor_enter is only sent to the root scene
#  defp do_handle_input( {:cursor_pos, point} = msg,
#  %{graphs: graphs} = state ) do
#    state = case find_by_screen_point( point, graphs ) do
#      nil ->
#        # no uid found. let the root scene handle the click
#        # we already know the root scene has identity transforms
#        state = send_primitive_exit_message(state)
#        {scene_pid, scene_id} = get_graph_key(state, 0)
#        GenServer.cast(scene_pid, {:input, msg, %{id: scene_id}})
#        state
#
#      {point, {uid, graph_id}, _} ->
#        # get the graph key, so we know what scene to send the event to
#        {scene_pid, scene_id} = get_graph_key(state, graph_id)
#        state = send_enter_message( uid, graph_id, state )
#        GenServer.cast(scene_pid,
#          {
#            :input,
#            {:cursor_pos, point},
#            %Context{scene_pid: scene_pid, scene_id: scene_id, uid: uid}
#          })
#        state
#    end
#
#    {:noreply, state}
#  end
#
#  #--------------------------------------------------------
#  # Any other input (non-standard, generated, etc) get sent to the root scene
#  defp do_handle_input( msg, state ) do
#    {scene_pid, scene_id} = get_graph_key(state, 0)
#    GenServer.cast(scene_pid,
#      {
#        :input,
#        msg,
#        %Context{scene_pid: scene_pid, scene_id: scene_id}
#      })
#    {:noreply, state}
#  end
#
#  
#  #============================================================================
#  # regular input helper utilties
#
#  defp send_primitive_exit_message( %{hover_primitve: nil} = state ), do: state
#  defp send_primitive_exit_message( %{hover_primitve: {uid, graph_id}} = state ) do
#    {scene_pid, scene_id} = get_graph_key(state, graph_id)
#    GenServer.cast(scene_pid,
#      {
#        :input,
#        {:cursor_exit, uid},
#        %Context{uid: uid, scene_pid: scene_pid, scene_id: scene_id}
#      })
#    %{state | hover_primitve: nil}
#  end
#
#  defp send_enter_message( uid, graph_id, %{hover_primitve: hover_primitve} = state ) do
#
#    # first, send the previous hover_primitve an exit message
#    state = case hover_primitve do
#      nil ->
#        # no previous hover_primitive set. do not send an exit message
#        state
#
#      {^uid, ^graph_id} -> 
#        # stil in the same hover_primitive. do not send an exit message
#        state
#
#      _ -> 
#        # do send the exit message
#        send_primitive_exit_message( state )
#    end
#
#    # send the new hover_primitve an enter message
#    case state.hover_primitve do
#      nil ->
#        # yes. setting a new one. send it.
#        {scene_pid, scene_id} = get_graph_key(state, graph_id)
#        GenServer.cast(scene_pid,
#          {
#            :input,
#            {:cursor_enter, uid},
#            %Context{uid: uid, scene_pid: scene_pid, scene_id: scene_id}
#          })
#        %{state | hover_primitve: {uid, graph_id}}
#
#      _ ->
#        # not setting a new one. do nothing.
#        state
#    end
#  end
#
#
#
#  #--------------------------------------------------------
#  # find the indicated primitive in a single graph. use the incoming parent
#  # transforms from the context
#  defp find_by_captured_point( {x,y}, graph, context ) do
#    do_find_by_captured_point( x, y, 0, graph, context.tx, context.inverse_tx, context.inverse_tx )
#  end
#
#  defp do_find_by_captured_point( x, y, uid, graph, parent_tx, parent_inv_tx, graph_inv_tx ) do
#    # get the primitive to test
#    case Map.get(graph, uid) do
#      # do nothing if the primitive is hidden
#      %{styles: %{hidden: true}} ->
#        nil
#
#      # if this is a group, then traverse the members backwards
#      # backwards is important as the goal is to find the LAST item drawn
#      # that is under the point in question
#      %{data: {Primitive.Group, ids}} = p ->
#        {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)
#        ids
#        |> Enum.reverse()
#        |> Enum.find_value( fn(uid) ->
#          do_find_by_captured_point( x, y, uid, graph, tx, inv_tx, graph_inv_tx )
#        end)
#
#      # This is a regular primitive, test to see if it is hit
#      %{data: {mod, data}} = p ->
#        {_, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)
#
#        # project the point by that inverse matrix to get the local point
#        local_point = Matrix.project_vector( inv_tx, {x, y} )
#
#        # test if the point is in the primitive
#        case mod.contains_point?( data, local_point ) do
#          true  ->
#            # Return the point in graph coordinates. Local was good for the hit test
#            # but graph coords makes more sense for the scene logic
#            graph_point = Matrix.project_vector( graph_inv_tx, {x, y} )
#            {uid, graph_point}
#
#          false ->
#            nil
#        end
#    end
#  end
#
#
#  #--------------------------------------------------------
#  # find the indicated primitive in the graph given a point in screen coordinates.
#  # to do this, we need to project the point into primitive local coordinates by
#  # projecting it with the primitive's inverse final matrix.
#  # 
#  # Since the last primitive drawn is always on top, we should walk the tree
#  # backwards and return the first hit we find. We could just reduct the whole
#  # thing and return the last one found (that was my first try), but this is
#  # more efficient as we can stop as soon as we find the first one.
#  defp find_by_screen_point( {x,y}, %{} = graphs ) do
#    identity = {@identity, @identity}
#    do_find_by_screen_point( x, y, 0, 0, graphs, identity, identity )
#  end
#
#  defp do_find_by_screen_point( x, y, uid, graph_id, graphs,
#    {parent_tx, parent_inv_tx}, {graph_tx, graph_inv_tx} ) do
#    # get the primitive to test
#    case get_in(graphs, [graph_id, uid]) do
#      # do nothing if the primitive is hidden
#      %{styles: %{hidden: true}} ->
#        nil
#
#      # if this is a group, then traverse the members backwards
#      # backwards is important as the goal is to find the LAST item drawn
#      # that is under the point in question
#      %{data: {Primitive.Group, ids}} = p ->
#        {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)
#        ids
#        |> Enum.reverse()
#        |> Enum.find_value( fn(uid) ->
#          do_find_by_screen_point(
#            x, y, uid, graph_id, graphs,
#            {tx, inv_tx}, {graph_tx, graph_inv_tx}
#          )
#        end)
#
#      # if this is a SceneRef, then traverse into the next graph
#      %{data: {Primitive.SceneRef, ref_id}} = p ->
#        {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)
#        do_find_by_screen_point(x, y, 0, ref_id, graphs, {tx, inv_tx}, {tx, inv_tx} )
#
#      # This is a regular primitive, test to see if it is hit
#      %{data: {mod, data}} = p ->
#        {_, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)
#
#        # project the point by that inverse matrix to get the local point
#        local_point = Matrix.project_vector( inv_tx, {x, y} )
#
#        # test if the point is in the primitive
#        case mod.contains_point?( data, local_point ) do
#          true  ->
#            # Return the point in graph coordinates. Local was good for the hit test
#            # but graph coords makes more sense for the scene logic
#            graph_point = Matrix.project_vector( graph_inv_tx, {x, y} )
#            {graph_point, {uid, graph_id}, {graph_tx, graph_inv_tx}}
#          false -> nil
#        end
#    end
#  end
#
#
#  defp calc_transforms(p, parent_tx, parent_inv_tx) do
#    p
#    |> Map.get(:transforms, nil)
#    |> Primitive.Transform.calculate_local()
#    |> case do
#      nil ->
#        # No local transform. This will often be the case.
#        {parent_tx, parent_inv_tx}
#
#      tx ->
#        # there was a local transform. multiply it into the parent
#        # then also calculate a new inverse transform
#        tx = Matrix.mul( parent_tx, tx )
#        inv_tx = Matrix.invert( tx )
#        {tx, inv_tx}
#    end
#  end
#





end





##  use GenServer
#  use Bitwise
#
#  require Logger
#  alias Scenic.ViewPort
#
#  import IEx
#
#  @valid_input_types  [
#    :key,
#    :codepoint,
#    :cursor_pos,
#    :cursor_button,
#    :cursor_scroll,
#    :cursor_enter
#  ]
#
#  @input_registry     :input_registry
#
#  #===========================================================================
#  defmodule Error do
#    defexception [ message: nil ]
#  end
#
#  #============================================================================
#  # client apis - meant to be called from the listener process
#
#  #--------------------------------------------------------
#  def register( type )
#  def register( :all ) do 
#    ref = make_ref()
#    Enum.each(@valid_input_types, &do_register(&1, ref) )
#    update_input_request()
#    {:input_ref, ref}
#  end
#  def register( type ) when is_atom(type) do
#    ref = make_ref()
#    do_register( type, ref )
#    update_input_request()
#    {:input_ref, ref}
#  end
#  def register( types ) when is_list(types) do
#    ref = make_ref()
#    Enum.each( types, &do_register(&1, ref) )
#    update_input_request()
#    {:input_ref, ref}
#  end
#  # two jobs. 1, prevent duplication. 2 enforce valid types
#  defp do_register( :char, ref ), do: do_register( :codepoint, ref )
#  defp do_register( type, ref ) when is_atom(type) do
#    case Enum.member?(@valid_input_types, type) do
#      true ->
#        # unregistering eliminates dups and makes sure the ref is current
#        Registry.unregister(@input_registry, type )
#        Registry.register(@input_registry, type, ref )
#      false ->
#        raise Error, message: "Invalid input type: #{inspect(type)}"
#    end
#  end
#
#  #--------------------------------------------------------
#  def unregister( type )
#  def unregister( {:input_ref, ref} ) when is_reference(ref) do
#    Enum.each(@valid_input_types, fn(type) ->
#      Registry.unregister_match(@input_registry, type, ref )
#    end)
#    update_input_request()
#  end
#  def unregister( :all ) do
#    Enum.each(@valid_input_types, &Registry.unregister(@input_registry, &1 ) )
#    update_input_request()
#  end
#  def unregister( type ) when is_atom(type) do
#    do_unregister( type )
#    update_input_request()
#  end
#  def unregister( types ) when is_list(types) do
#    Enum.each( types, &do_unregister(&1) )
#    update_input_request()
#  end
#  defp do_unregister( :char ), do: do_unregister( :codepoint )
#  defp do_unregister( type ) when is_atom(type) do
#    case Enum.member?(@valid_input_types, type) do
#      true ->
#        Registry.unregister(@input_registry, type )
#      false ->
#        raise Error, message: "Invalid input type: #{inspect(type)}"
#    end
#  end
#
#
#  #--------------------------------------------------------
#  # gather registrations from the registry. Turn that into a flag field,
#  # then send that to the driver
#  defp update_input_request() do
#    input_flags = Enum.reduce(@valid_input_types, 0, fn(type,flags) ->
#      case Registry.lookup(@input_registry, type) do
#        [] -> flags
#        _ ->
#          # there is at least one entry, so set this flag
#          flags ||| input_type_to_flags(type)
#      end
#    end)
#    ViewPort.Driver.cast({:request_input, input_flags})
#  end
#
#
#  #============================================================================
#  # driver apis - meant to be called from a driver that is sending input
#
#  #----------------------------------------------
#  def send( {input_type, _} = event ) do
#    # needs a different dispatcher than sending a message to the driver. The pid to
#    # send the message to is the value stored in the registry, not the pid that
#    # set up the registry entry. That would be the viewport...
#
#    # dispatch the call to any listening drivers
#    Registry.dispatch(@input_registry, input_type, fn(entries) ->
#      for {pid, _} <- entries do
#        try do
#          GenServer.cast(pid, {:input, event})
#        catch
#          kind, reason ->
#            formatted = Exception.format(kind, reason, System.stacktrace)
#            Logger.error "Registry.dispatch/3 failed with #{formatted}"
#        end
#      end
#    end)
#  end
#  def send( msg ) do
#    IO.puts "Input: invalid message: #{inspect(msg)}"
#  end
#
#  #============================================================================
#  # keyboard input helpers
#  # these are for reading the keyboard directly. If you are trying to do text input
#  # use the text/char helpers instead
#
#  # key codes use the standards defined by GLFW
#  # http://www.glfw.org/docs/latest/group__keys.html
#
#  #--------------------------------------------------------
#  def key_to_atom( key_code )
#  def key_to_atom( 32 ),    do: :space
#  def key_to_atom( 39 ),    do: :apostrophe
#  def key_to_atom( 44 ),    do: :comma
#  def key_to_atom( 45 ),    do: :minus
#  def key_to_atom( 46 ),    do: :period
#  def key_to_atom( 47 ),    do: :slash
#
#  def key_to_atom( 48 ),    do: :zero
#  def key_to_atom( 49 ),    do: :one
#  def key_to_atom( 50 ),    do: :two
#  def key_to_atom( 51 ),    do: :three
#  def key_to_atom( 52 ),    do: :four
#  def key_to_atom( 53 ),    do: :five
#  def key_to_atom( 54 ),    do: :six
#  def key_to_atom( 55 ),    do: :seven
#  def key_to_atom( 56 ),    do: :eight
#  def key_to_atom( 57 ),    do: :nine
#
#  def key_to_atom( 59 ),    do: :semicolon
#  def key_to_atom( 61 ),    do: :equal
#
#  def key_to_atom( 65 ),    do: :a
#  def key_to_atom( 66 ),    do: :b
#  def key_to_atom( 67 ),    do: :c
#  def key_to_atom( 68 ),    do: :d
#  def key_to_atom( 69 ),    do: :e
#  def key_to_atom( 70 ),    do: :f
#  def key_to_atom( 71 ),    do: :g
#  def key_to_atom( 72 ),    do: :h
#  def key_to_atom( 73 ),    do: :i
#  def key_to_atom( 74 ),    do: :j
#  def key_to_atom( 75 ),    do: :k
#  def key_to_atom( 76 ),    do: :l
#  def key_to_atom( 77 ),    do: :m
#  def key_to_atom( 78 ),    do: :n
#  def key_to_atom( 79 ),    do: :o
#  def key_to_atom( 80 ),    do: :p
#  def key_to_atom( 81 ),    do: :q
#  def key_to_atom( 82 ),    do: :r
#  def key_to_atom( 83 ),    do: :s
#  def key_to_atom( 84 ),    do: :t
#  def key_to_atom( 85 ),    do: :u
#  def key_to_atom( 86 ),    do: :v
#  def key_to_atom( 87 ),    do: :w
#  def key_to_atom( 88 ),    do: :x
#  def key_to_atom( 89 ),    do: :y
#  def key_to_atom( 90 ),    do: :z
#
#  def key_to_atom( 91 ),    do: :left_bracket         # [
#  def key_to_atom( 92 ),    do: :backslash            # \
#  def key_to_atom( 93 ),    do: :right_bracket        # ]
#  def key_to_atom( 96 ),    do: :grave_accent         # `
#
#  def key_to_atom( 161 ),   do: :world_1              # non-US #1
#  def key_to_atom( 162 ),   do: :world_2              # non-US #2
#
#  def key_to_atom( 256 ),   do: :escape
#  def key_to_atom( 257 ),   do: :enter
#  def key_to_atom( 258 ),   do: :tab
#  def key_to_atom( 259 ),   do: :backspace
#  def key_to_atom( 260 ),   do: :insert
#  def key_to_atom( 261 ),   do: :delete
#
#  def key_to_atom( 262 ),   do: :right
#  def key_to_atom( 263 ),   do: :left
#  def key_to_atom( 264 ),   do: :down
#  def key_to_atom( 265 ),   do: :up
#  def key_to_atom( 266 ),   do: :page_up
#  def key_to_atom( 267 ),   do: :page_down
#  def key_to_atom( 268 ),   do: :home
#  def key_to_atom( 269 ),   do: :end
#
#  def key_to_atom( 280 ),   do: :caps_lock
#  def key_to_atom( 281 ),   do: :scroll_lock
#  def key_to_atom( 282 ),   do: :num_lock
#
#  def key_to_atom( 283 ),   do: :print_screen
#  def key_to_atom( 284 ),   do: :pause
#
#  def key_to_atom( 290 ),   do: :f1
#  def key_to_atom( 291 ),   do: :f2
#  def key_to_atom( 292 ),   do: :f3
#  def key_to_atom( 293 ),   do: :f4
#  def key_to_atom( 294 ),   do: :f5
#  def key_to_atom( 295 ),   do: :f6
#  def key_to_atom( 296 ),   do: :f7
#  def key_to_atom( 297 ),   do: :f8
#  def key_to_atom( 298 ),   do: :f9
#  def key_to_atom( 299 ),   do: :f10
#  def key_to_atom( 300 ),   do: :f11
#  def key_to_atom( 301 ),   do: :f12
#  def key_to_atom( 302 ),   do: :f13
#  def key_to_atom( 303 ),   do: :f14
#  def key_to_atom( 304 ),   do: :f15
#  def key_to_atom( 305 ),   do: :f16
#  def key_to_atom( 306 ),   do: :f17
#  def key_to_atom( 307 ),   do: :f18
#  def key_to_atom( 308 ),   do: :f19
#  def key_to_atom( 309 ),   do: :f20
#  def key_to_atom( 310 ),   do: :f21
#  def key_to_atom( 311 ),   do: :f22
#  def key_to_atom( 312 ),   do: :f23
#  def key_to_atom( 313 ),   do: :f24
#  def key_to_atom( 314 ),   do: :f25
#
#  def key_to_atom( 320 ),   do: :kp_0
#  def key_to_atom( 321 ),   do: :kp_1
#  def key_to_atom( 322 ),   do: :kp_2
#  def key_to_atom( 323 ),   do: :kp_3
#  def key_to_atom( 324 ),   do: :kp_4
#  def key_to_atom( 325 ),   do: :kp_5
#  def key_to_atom( 326 ),   do: :kp_6
#  def key_to_atom( 327 ),   do: :kp_7
#  def key_to_atom( 328 ),   do: :kp_8
#  def key_to_atom( 329 ),   do: :kp_9
#
#  def key_to_atom( 330 ),   do: :kp_decimal
#  def key_to_atom( 331 ),   do: :kp_divide
#  def key_to_atom( 332 ),   do: :kp_multiply
#  def key_to_atom( 333 ),   do: :kp_subtract
#  def key_to_atom( 334 ),   do: :kp_add
#  def key_to_atom( 335 ),   do: :kp_enter
#  def key_to_atom( 336 ),   do: :kp_equal
#
#  def key_to_atom( 340 ),   do: :left_shift
#  def key_to_atom( 341 ),   do: :left_control
#  def key_to_atom( 342 ),   do: :left_alt
#  def key_to_atom( 343 ),   do: :left_super
#
#  def key_to_atom( 344 ),   do: :right_shift
#  def key_to_atom( 345 ),   do: :right_control
#  def key_to_atom( 346 ),   do: :right_alt
#  def key_to_atom( 347 ),   do: :right_super
#
#  def key_to_atom( 348 ),   do: :menu
#
#  def key_to_atom( key ) do
#    raise Error, message: "Unknown key: #{inspect(key)}"
#  end
#
#
#  #--------------------------------------------------------
#  # defined to follow the GLFW modifier keys
#  # http://www.glfw.org/docs/latest/group__mods.html
#
#  @key_mod_shift    0x0001
#  @key_mod_control  0x0002
#  @key_mod_alt      0x0004
#  @key_mod_super    0x0008
#  @key_mods         [
#    {@key_mod_shift,   :shift},
#    {@key_mod_control, :control},
#    {@key_mod_alt,     :alt},
#    {@key_mod_super,   :super}
#  ]
#
#  def mods_to_atoms( key_mods )
#  def mods_to_atoms( key_mods ) when is_integer(key_mods) do
#    Enum.reduce(@key_mods, [], fn({mask,mod_atom}, acc) -> 
#        case Bitwise.band(mask, key_mods) do
#          0 -> acc
#          _ -> [mod_atom | acc]
#        end
#    end)
#  end
#  def mods_to_atoms( mods ) do
#    raise Error, message: "Unknown mods: #{inspect(mods)}"
#  end
#
#  #--------------------------------------------------------
#  def action_to_atom( action )
#  def action_to_atom( 0 ),  do: :release
#  def action_to_atom( 1 ),  do: :press
#  def action_to_atom( 2 ),  do: :repeat
#  def action_to_atom( _ ),  do: :unknown
#
#  #--------------------------------------------------------
#  def codepoint_to_char( codepoint_to_atom )
#  def codepoint_to_char( cp ),  do: << cp :: utf8 >>
#
#
#  #--------------------------------------------------------
#  def button_to_atom( 0 ), do: :left
#  def button_to_atom( 1 ), do: :right
#  def button_to_atom( _ ), do: :unknown
#
  #--------------------------------------------------------
#  def input_type_to_flags( type )
#  def input_type_to_flags( types ) when is_list(types) do
#    Enum.reduce(types, 0, &(input_type_to_flags(&1) ||| &2) )
#  end
#  def input_type_to_flags( :key ),            do: 0x0001
#  def input_type_to_flags( :codepoint ),      do: 0x0002
#  def input_type_to_flags( :cursor_pos ),     do: 0x0004
#  def input_type_to_flags( :cursor_button ),   do: 0x0008
#  def input_type_to_flags( :cursor_scroll ),   do: 0x0010
#  def input_type_to_flags( :cursor_enter ),    do: 0x0020
#  def input_type_to_flags( :all ),            do: 0xFFFF
#  def input_type_to_flags( type ), do: raise Error, message: "Unknown input type: #{inspect(type)}"
#
#
#
#  #===========================================================================
#  # input normalization
#
#  #--------------------------------------------------------
#  def normalize( {:key, {key, _scancode, action, mods}} ) do
#    {
#      :key,
#      key_to_atom( key ),
#      action_to_atom( action ),
#      mods
#    }
#  end
#
#  #--------------------------------------------------------
#  def normalize( {:codepoint, {codepoint, mods}} ) do
#    {
#      :char,
#      codepoint_to_char( codepoint ),
#      mods 
#    }
#  end
#
#  #--------------------------------------------------------
#  def normalize( {:cursor_button, {btn, action, mods, pos}} ) do
#    {
#      :cursor_button,
#      button_to_atom( btn ),
#      action_to_atom( action ),
#      mods,
#      pos
#    }
#  end
#
#  #--------------------------------------------------------
#  def normalize( {:cursor_enter, {0, pos}} ), do: {:cursor_enter, false, pos}
#  def normalize( {:cursor_enter, {1, pos}} ), do: {:cursor_enter, true, pos}
#
#  #--------------------------------------------------------
#  # all other events pass through unchanged
#  def normalize( event ), do: event


#end















