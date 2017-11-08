#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#
# Build from the pieces of older versions of Scene
#

# in general anything in the Scene's "internal" section of the state should
# be accessed through Scene apis. Future versions may change the formatting
# this data as needed, but will try to keep the APIs compatible.


defmodule Scenic.Scene do
  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Primitive
  require Logger

#  import IEx

  @callback init( any ) :: {:ok, any}
  @callback init_graph(any) :: {:ok, map, any}

  #===========================================================================
  # calls for setting up a scene inside of a supervisor

  def child_spec({scene_module, id}), do: child_spec({scene_module, id, nil})
  def child_spec({scene_module, id, args}) do
    %{
      id: id,
      start: {__MODULE__, :start_link, [scene_module, id, args]},
      type: :worker,
      restart: args[:restart] || :permanent,
      shutdown: 500
    }
  end

  #===========================================================================
  # client APIs. In general if the first parameter is an atom or a pid, then it is coming
  # from another process. call or cast to the real one.
  # if the first parameter is state, then this is already on the right process
  # to be called by other processes

  def find_by_screen_pos( pos, pid ) do
    GenServer.call(pid, {:find_by_screen_pos, pos})
  end

  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Scene

      #--------------------------------------------------------
      # initialization
      def init(_),                                        do: {:ok, nil}

      #--------------------------------------------------------
      # Here so that the scene can override if desired
#      def handle_context_lost(graph, state),          do: {:noreply, graph, state}
      def handle_context_gained(graph, state),        do: {:noreply, graph, state}
 
      def handle_call(_msg, _from, graph, state),     do: {:reply, :err_not_handled, graph, state}
      def handle_cast(_msg, graph, state),            do: {:noreply, graph, state}
      def handle_info(_msg, graph, state),            do: {:noreply, graph, state}

      def handle_input( event, graph, scene_state ),  do: {:noreply, graph, scene_state}

      #--------------------------------------------------------
#      add local shortcuts to things like get/put graph and modify element
#      do not add a put element. keep it at modify to stay atomic
      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        handle_call:            4,
        handle_cast:            3,
        handle_info:            3,
        handle_context_gained:  2,
        handle_input:           3
      ]

    end # quote
  end # defmacro


  #===========================================================================
  # internal code to this module

  #===========================================================================
  # Scene initialization


  #--------------------------------------------------------
  def start_link(module, name, args) do
    GenServer.start_link(__MODULE__, {module, args}, name: name)
  end

  #--------------------------------------------------------
  def init( {module, opts} ) do
    {:ok, scene_state} = module.init(opts)
    {:ok, graph, scene_state} = module.init_graph(scene_state)

    state = %{
      scene_module:       module,
      scene_state:        scene_state,
      graph:              graph,
      vp_context:         nil,
    }

    {:ok, state}
  end


  #--------------------------------------------------------
  # if the viewport says the context has lost (probably because it is showing a different scene),
  # then it sends the scene that is being replaced, the context_lost message
#  def handle_call({:context_lost, context}, _from,
#  %{scene_module: mod, graph: graph, scene_state: scene_state} = state) do
#    # do nothing if this isn't the scene's current context
#    state
#    |> is_current_context?( context ) 
#    |> case do
#      false -> {:reply, :error_bad_context, state}
#      true ->
#        # let the scene know, then clear the context from the state
#        {:noreply, graph, scene_state} = mod.handle_context_lost( context, graph, scene_state )
#
#        state = state
#        |> Map.put(:vp_context, nil)
#        |> Map.put(:graph, graph)
#        |> Map.put(:scene_state, scene_state)
#
#        {:reply, :ok, state}
#    end
#  end

  #--------------------------------------------------------
  # somebody has a screen position and wants an uid for it
  def handle_call({:find_by_screen_pos, pos}, _from, %{graph: graph} = state) do
    uid = case Graph.find_by_screen_point( graph, pos ) do
      %Primitive{uid: uid} -> uid
      _ -> nil
    end
    {:reply, uid, state}
  end

  #--------------------------------------------------------
  # generic call. give the scene a chance to handle it
  def handle_call(msg, from, %{scene_module: mod, graph: graph, scene_state: scene_state} = state) do
    {:reply, reply, graph, scene_state} = mod.handle_call(msg, from, graph, scene_state)
    state = state
    |> Map.put(:graph, graph)
    |> Map.put(:scene_state, scene_state)
    {:reply, reply, state}
  end


  #===========================================================================
  # default cast handlers.



  #--------------------------------------------------------
  # if the viewport says the context has lost (probably because it is showing a different scene),
  # then it sends the scene that is being replaced, the context_lost message
#  def handle_cast(:context_gained, %{scene_module: mod, scene_state: scene_state, graph: graph} = state) do
#
#    # tick any recurring actions before rendering
#    graph = Graph.tick_recurring_actions(graph)
#
#    # tell the scene this is happening
#    {:noreply, graph, scene_state} = mod.handle_context_gained( graph, scene_state )
#
#    # save graph, and the scene state
#    state = state
#    |> Map.put(:graph, graph)
#    |> Map.put(:scene_state, scene_state)
#
#    # reset the viewport with this scene's graph
#    ViewPort.set_graph( graph )
#
#    # return the transformed state
#    {:noreply, state}
#  end

  #--------------------------------------------------------
  def handle_cast({:input, event}, %{graph: graph} = state) do
    # prepare the message and find the default primitive, if any
    prepare_input(event, graph)
    |> do_handle_input( state )
  end

  #--------------------------------------------------------
  def handle_cast({:input_uid, event, uid}, state) do
    do_handle_input( {event, uid}, state )
  end

  #--------------------------------------------------------
  # a graphic driver is requesting an update
  def handle_cast(:graph_update, %{graph: graph} = state) do
    # tick any recurring actions
    graph = Graph.tick_recurring_actions( graph )

    # send the graph to the view_port
    ViewPort.update_graph( graph )

    # reset the deltas
    graph = Graph.reset_deltas( graph )

    # update and return the state
    state = Map.put( state, :graph, graph )

    { :noreply, state }
  end

  #--------------------------------------------------------
  # a graphic driver is requesting a full graph reset
  def handle_cast(:graph_reset, %{ graph: graph } = state) do
    # tick any recurring actions
    graph = Graph.tick_recurring_actions( graph )
    # reset the viewport with this scene's graph
    ViewPort.set_graph(graph)
    { :noreply, Map.put(state, :graph, graph) }
  end

  #--------------------------------------------------------
  # generic cast. give the scene a chance to handle it
  def handle_cast(msg, %{scene_module: mod, graph: graph, scene_state: scene_state} = state) do
    {:noreply, graph, scene_state} = mod.handle_cast(msg, graph, scene_state)
    state = state
    |> Map.put(:graph, graph)
    |> Map.put(:scene_state, scene_state)
    {:noreply, state}
  end


  #===========================================================================
  # info handlers

  #--------------------------------------------------------
  # generic info. give the scene a chance to handle it
  def handle_info(msg, %{scene_module: mod, graph: graph, scene_state: scene_state} = state) do
    {:noreply, graph, scene_state} = mod.handle_info(msg, graph, scene_state)
    state = state
    |> Map.put(:graph, graph)
    |> Map.put(:scene_state, scene_state)
    {:noreply, state}
  end


  #===========================================================================
  # input preperation

  #--------------------------------------------------------
  defp prepare_input( {:key, {key, action, mods}}, _ ) do
    event = {
      :key,
      ViewPort.Input.key_to_atom( key ),
      ViewPort.Input.action_to_atom( action ),
      mods
    }
    {event, nil}
  end

  #--------------------------------------------------------
  defp prepare_input( {:codepoint, {codepoint, mods}}, %Graph{focus: focus} ) do
    event = {
      :char,
      ViewPort.Input.codepoint_to_char( codepoint ),
      mods 
    }
    {event, focus}
  end

  #--------------------------------------------------------
  defp prepare_input( {:mouse_move, pos} = event, graph ) do
    uid = case Graph.find_by_screen_point(graph, pos) do
      nil -> nil
      p   -> Primitive.get_uid(p)
    end
    {event, uid}
  end

  #--------------------------------------------------------
  defp prepare_input( {:mouse_button, {btn, action, mods, pos}}, graph ) do
    event = {
      :mouse_button,
      ViewPort.Input.button_to_atom( btn ),
      ViewPort.Input.action_to_atom( action ),
      mods,
      pos
    }

    uid = case Graph.find_by_screen_point(graph, pos) do
      nil -> nil
      p   -> Primitive.get_uid(p)
    end

    {event, uid}
  end

  #--------------------------------------------------------
  defp prepare_input( {:mouse_scroll, {offsets, pos}}, graph ) do
    uid = case Graph.find_by_screen_point(graph, pos) do
      nil -> nil
      p   -> Primitive.get_uid(p)
    end
    {{:mouse_scroll, offsets, pos}, uid}
  end

  #--------------------------------------------------------
  defp prepare_input( {:mouse_enter, {0, pos}}, _ ) do
    {{:mouse_enter, false, pos}, nil}
  end
  defp prepare_input( {:mouse_enter, {1, pos}}, graph ) do
    uid = case Graph.find_by_screen_point(graph, pos) do
      nil -> nil
      p   -> Primitive.get_uid(p)
    end
    {{:mouse_enter, true, pos}, uid}
  end

  defp prepare_input( event, _ ), do: {event, nil}


  #--------------------------------------------------------
  defp do_handle_input({event, uid}, %{scene_module: mod, graph: graph, scene_state: scene_state} = state) do
    state = try do
      # filter the event through the graph
      case Graph.filter_input(graph, event, uid) do
        {:stop, graph} ->
          # the event is done. Stop handling it
          Map.put(state, :graph, graph)

        {:continue, event, graph} ->
          # let the scene itself handle the event
          {:noreply, graph, scene_state} = mod.handle_input(event, graph, scene_state)
          state
          |> Map.put(:graph, graph)
          |> Map.put(:scene_state, scene_state)
      end
    catch
      kind, reason ->
        formatted = Exception.format(kind, reason, System.stacktrace)
        Logger.error "Scene.handle_cast :input failed with #{formatted}"
        state
    end

    # return the transformed state
    {:noreply, state}
  end


end