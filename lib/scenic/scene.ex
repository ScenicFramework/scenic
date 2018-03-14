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

  @callback handle_call(any, any, any, any) :: {:reply, any, any, any} | {:noreply, any, any, any}
  @callback handle_cast(any, any, any) :: {:noreply, any, any}
  @callback handle_info(any, any, any) :: {:noreply, any, any}

  @callback handle_input(any, any, any) :: {:noreply, any, any}
  @callback handle_reset(any, any) :: {:noreply, any, any}
  @callback handle_update(any, any) :: {:noreply, any, any}
  @callback focus_gained(any, any, any) :: {:ok, any, any}
  @callback focus_lost(any, any) :: {:ok, any, any}

  @viewport_registry    :viewport_registry

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
      def init(_),                                      do: {:ok, nil}
      def init_graph(state),                            do: {:ok, Graph.build(), state}

      #--------------------------------------------------------
      # Here so that the scene can override if desired
 
      def handle_call(_msg, _from, graph, state),       do: {:reply, :err_not_handled, graph, state}
      def handle_cast(_msg, graph, state),              do: {:noreply, graph, state}
      def handle_info(_msg, graph, state),              do: {:noreply, graph, state}

      def handle_input( event, graph, scene_state ),    do: {:noreply, graph, scene_state}
#      def handle_reset(graph, scene_state),             do: Scenic.Scene.handle_reset(graph, scene_state)
#      def handle_update(graph, scene_state),            do: Scenic.Scene.handle_update(graph, scene_state)
      def graph_set_list(graph, _),                     do: Scenic.Scene.graph_set_list(graph)
      def graph_delta_list(graph, _),                   do: Scenic.Scene.graph_delta_list(graph)

      def focus_gained( _scene_param, graph, scene_state ) do
        Map.get(graph, :input, [])
        |> ViewPort.Input.register()
        {:ok, graph, scene_state}
      end

      def focus_lost( graph, scene_state ) do
        ViewPort.Input.unregister( :all )
        {:ok, graph, scene_state}
      end

      #--------------------------------------------------------
#      add local shortcuts to things like get/put graph and modify element
#      do not add a put element. keep it at modify to stay atomic
      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        init_graph:             1,
        handle_call:            4,
        handle_cast:            3,
        handle_info:            3,
        handle_input:           3,
        focus_gained:           3,
        focus_lost:             2,

        graph_set_list:         2,
        graph_delta_list:       2
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
    }

    {:ok, state}
  end

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
  # unregister this scene for callbacks
  def handle_call(:lose_focus, _from,
  %{scene_module: mod, graph: graph, scene_state: scene_state} = state) do
    {reply, state} = case mod.focus_lost(graph, scene_state) do
      {:ok, graph, scene_state} ->
        Registry.unregister(@viewport_registry, :messages )
        state = state
        |> Map.put(:graph, graph)
        |> Map.put(:scene_state, scene_state)
        {:ok, state}
      {:cancel, graph, scene_state} ->
        state = state
        |> Map.put(:graph, graph)
        |> Map.put(:scene_state, scene_state)
        {:cancel, state}
      _ -> {:err, state}
    end
    {:reply, reply, state}
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
  def handle_cast({:set_scene, scene_param}, state) do
    self = self()
    # someting has requested this scene make set itself into
    # the viewport. This can be canceled by the current scene.
    case ViewPort.current_scene() do
      nil -> 
        # gain the focus
        {_, state} = do_gain_focus( scene_param, state )
        {:noreply, state}
      ^self ->
        # already the current scene. do nothing
        {:noreply, state}
      old_scene ->
        # tell the old scene to unregister itself
        case GenServer.call( old_scene, :lose_focus) do
          :ok -> 
            # gain the focus
            {_, state} = do_gain_focus( scene_param, state )
            {:noreply, state}
        end
    end
  end

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
  # a graphic driver is requesting a full graph reset
  def handle_cast(:graph_reset,
  %{graph: graph, scene_module: mod, scene_state: scene_state} = state) do
    # tick any recurring actions
    graph = Graph.tick_recurring_actions( graph )
    |> Graph.reset_deltas()

    # send the graph to the view_port
    graph
#    |> Graph.minimal()
    |> mod.graph_set_list(scene_state)
    |> ViewPort.set_graph()

    state = state
    |> Map.put(:graph, graph)
    { :noreply, state }
  end

  #--------------------------------------------------------
  # a graphic driver is requesting an update
  def handle_cast(:graph_update,
  %{graph: graph, scene_module: mod, scene_state: scene_state} = state) do
    # tick any recurring actions
    graph = Graph.tick_recurring_actions( graph )

    # send the graph to the view_port
    graph
#    |> Graph.get_delta_scripts()
    |> mod.graph_delta_list(scene_state)
    |> ViewPort.update_graph()

    # reset the deltas
    graph = Graph.reset_deltas( graph )

    state = state
    |> Map.put(:graph, graph)
    { :noreply, state }
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
  defp prepare_input( {:key, {key, _scancode, action, mods}}, _ ) do
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
  defp prepare_input( {:cursor_pos, pos} = event, graph ) do
    uid = case Graph.find_by_screen_point(graph, pos) do
      nil -> nil
      p   -> Primitive.get_uid(p)
    end
    {event, uid}
  end

  #--------------------------------------------------------
  defp prepare_input( {:cursor_button, {btn, action, mods, pos}}, graph ) do
    event = {
      :cursor_button,
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
  defp prepare_input( {:cursor_scroll, {offsets, pos}}, graph ) do
    uid = case Graph.find_by_screen_point(graph, pos) do
      nil -> nil
      p   -> Primitive.get_uid(p)
    end
    {{:cursor_scroll, offsets, pos}, uid}
  end

  #--------------------------------------------------------
  defp prepare_input( {:cursor_enter, {0, pos}}, _ ) do
    {{:cursor_enter, false, pos}, nil}
  end
  defp prepare_input( {:cursor_enter, {1, pos}}, graph ) do
    uid = case Graph.find_by_screen_point(graph, pos) do
      nil -> nil
      p   -> Primitive.get_uid(p)
    end
    {{:cursor_enter, true, pos}, uid}
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

  #--------------------------------------------------------
  defp do_gain_focus(scene_param, %{scene_module: mod, graph: graph, scene_state: scene_state} = state) do
    case mod.focus_gained( scene_param, graph, scene_state) do
      {:ok, graph, scene_state} ->
        # register for messages
        Registry.register(@viewport_registry, :messages, self() )

        # tick and send the graph to the drivers
        GenServer.cast(self(), :graph_reset)
#        graph = do_reset_graph(graph, state)
#        {:noreply, graph, scene_state} = mod.handle_reset(graph, scene_state)


        # tell the Viewport that this is now the root graph to display
#        ViewPort.set_root_graph( mod.identify(scene_state) )

        # store the state
        state = state
        |> Map.put(:graph, graph)
        |> Map.put(:scene_state, scene_state)
        {:ok, state}
      {:cancel, graph, scene_state} ->
        state = state
        |> Map.put(:graph, graph)
        |> Map.put(:scene_state, scene_state)
        {:cancel, state}
      _ -> {:err, state}
    end
  end

  #============================================================================

  #--------------------------------------------------------
  def graph_set_list(graph) do
    Graph.minimal(graph)
  end
  def graph_delta_list(graph) do
    Graph.get_delta_scripts(graph)
  end
end








