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

  import IEx


  @callback init( any ) :: {:ok, any}
  @callback init_graph(any) :: {:ok, map, any}

#  @half_heartbeat_ms        16
#  @half_heartbeat_ms        32
#  @half_heartbeat_ms        64
#  @half_heartbeat_ms        250
#  @half_heartbeat_ms        500


  #===========================================================================
  # calls for setting up a scene inside of a supervisor

#  def worker( scene_module, id, args \\ [] ) when is_atom(id) do
#    Supervisor.child_spec({Scenic.Scene, {scene_module, id, args} }, [])
#  end

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
  # main APIs. In general if the first parameter is an atom or a pid, then it is coming
  # from another process. call or cast to the real one.
  # if the first parameter is state, then this is already on the right process
  # to be called by other processes


  def send_input( name_or_pid, event, uid )
  def send_input( name_or_pid, event, uid ) when is_integer(uid) do
    GenServer.cast(name_or_pid, {:input, event, uid})
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
      def handle_context_lost(context, graph, state),     do: {:noreply, graph, state}
      def handle_context_gained(context, graph, state),   do: {:noreply, graph, state}


      def handle_call(_msg, _from, graph, state),         do: {:reply, :err_not_handled, graph, state}
      def handle_cast(_msg, graph, state),                do: {:noreply, graph, state}
      def handle_info(_msg, graph, state),                do: {:noreply, graph, state}

      def handle_input( event, graph, scene_state ),      do: {:noreply, graph, scene_state}

      #--------------------------------------------------------
#      add local shortcuts to things like get/put graph and modify element
#      do not add a put element. keep it at modify to stay atomic
      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        handle_call:            4,
        handle_cast:            3,
        handle_info:            3,
        handle_context_lost:    3,
        handle_context_gained:  3,
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
      heart_timer:        nil,
      last_sync:          nil
    }

    {:ok, state}
  end


  #--------------------------------------------------------
  # if the viewport says the context has lost (probably because it is showing a different scene),
  # then it sends the scene that is being replaced, the context_lost message
  def handle_call({:context_lost, context}, _from, %{scene_module: mod, graph: graph, scene_state: scene_state} = state) do
#    IO.puts( ":context_lost #{inspect(context)}" )

    # do nothing if this isn't the scene's current context
    state
    |> is_current_context?( context ) 
    |> case do
      false -> {:reply, :error_bad_context, state}
      true ->
        # let the scene know, then clear the context from the state
        {:noreply, graph, scene_state} = mod.handle_context_lost( context, graph, scene_state )

        state = state
#        |> stop_heartbeat()
        |> Map.put(:vp_context, nil)
        |> Map.put(:graph, graph)
        |> Map.put(:scene_state, scene_state)

        {:reply, :ok, state}
    end
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
  def handle_cast({:context_gained, context}, %{scene_module: mod, scene_state: scene_state, graph: graph} = state) do
#    IO.puts( ":context_gained #{inspect(context)}" )

    # tick any recurring actions before rendering
    graph = Graph.tick_recurring_actions(graph)

    # tell the scene this is happening
    {:noreply, graph, scene_state} = mod.handle_context_gained( context, graph, scene_state )

    # save the context, graph, and the scene state
    state = state
#    |> start_heartbeat()
    |> Map.put(:graph, graph)
    |> Map.put(:vp_context, context)
    |> Map.put(:scene_state, scene_state)
    |> Map.put(:last_sync, :os.system_time(:millisecond))

    # reset the viewport with this scene's graph
    ViewPort.set_graph(context, graph)

    # return the transformed state
    {:noreply, state}
  end


  #--------------------------------------------------------
  def handle_cast({:input, event, uid}, state) do
    handle_info({:input, event, uid}, state)
  end

  #--------------------------------------------------------
  # a graphic driver is requesting an update
  def handle_cast(:vp_update, %{vp_context: context, graph: graph} = state) do
    # tick any recurring actions
    graph = Graph.tick_recurring_actions( graph )

    # send the graph to the view_port
    state = case ViewPort.update_graph( context, graph ) do
      :ok ->            state
      :context_lost ->
#        stop_heartbeat( state )
        state
    end

    # reset the deltas
    graph = Graph.reset_deltas( graph )

    # update and return the state
    state
    |> Map.put( :graph, graph )
    |> Map.put( :last_sync, :os.system_time(:millisecond) )

    { :noreply, state }
  end

  #--------------------------------------------------------
  # a graphic driver is requesting a full graph reset
  def handle_cast(:vp_reset, %{ vp_context: context, graph: graph } = state) do
    # reset the viewport with this scene's graph
    ViewPort.set_graph(context, graph)
    state = Map.put( state, :last_sync, :os.system_time(:millisecond) )
    { :noreply, state }
  end

  def handle_cast(_,state) do
    pry()
    { :noreply, state }
  end


  #--------------------------------------------------------
  # generic cast. give the scene a chance to handle it
  def handle_cast(msg, %{scene_module: mod, graph: graph, scene_state: scene_state} = state) do
    pry()
    {:noreply, graph, scene_state} = mod.handle_cast(msg, graph, scene_state)
    state = state
    |> Map.put(:graph, graph)
    |> Map.put(:scene_state, scene_state)
    {:noreply, state}
  end


  #===========================================================================
  # default info handlers.

  def handle_info({:input, event, uid}, %{scene_module: mod, scene_state: scene_state, graph: graph} = state) do
    # filter the input through the graph
    case Graph.filter_input(graph, event, uid) do
      {:continue, event, graph} ->
        # let the scene handle the remaining event
        {:noreply, graph, scene_state} = mod.handle_input(event, graph, scene_state )
        state = state
        |> Map.put(:graph, graph)
        |> Map.put(:scene_state, scene_state)
        {:noreply, state}

      {:stop, graph} ->
        {:noreply, Map.put(state, :graph, graph)}
    end
  end


  #--------------------------------------------------------
  # this message is the scene's heartbeat telling it to tick any animations and update the view_port
#  def handle_info(:heartbeat, %{ graph: graph, vp_context: context, last_sync: last_sync } = state) do
#    time = :os.system_time(:millisecond)
#    state = cond do
#      last_sync == nil                          -> do_sync(state)
#      (time - last_sync) >= @half_heartbeat_ms  -> do_sync(state)
#      true                                      -> state
#    end
#    {:noreply, state }
#  end


  #--------------------------------------------------------
  # generic info. give the scene a chance to handle it
  def handle_info(msg, %{scene_module: mod, graph: graph, scene_state: scene_state} = state) do
    {:noreply, graph, scene_state} = mod.handle_info(msg, graph, scene_state)
    state = state
    |> Map.put(:graph, graph)
    |> Map.put(:scene_state, scene_state)
    {:noreply, state}
  end


  #--------------------------------------------------------
  defp is_current_context?(%{vp_context: current_context}, {:context, context_id, _}) do
    case current_context do
      {:context, current_id, _} -> current_id == context_id
      _ -> false
    end
  end

  #===========================================================================
  # heartbeat helpers

#  defp start_heartbeat( %{heart_timer: nil} = state ) do
#    {:ok, tref} = :timer.send_interval(@half_heartbeat_ms + @half_heartbeat_ms, :heartbeat)
#    Map.put(state, :heart_timer, tref)
#    state
#  end
#  defp start_heartbeat( state ), do: state
#
# 
#  defp stop_heartbeat( %{heart_timer: nil} = state ), do: state
#  defp stop_heartbeat( %{heart_timer: tref} = state ) do
#    :timer.cancel( tref )
#    Map.put(state, :heart_timer, nil)
#  end

#  #------------------------------------
#  def do_sync( %{vp_context: context, graph: graph} = state ) do
#    # tick any recurring actions
#    graph = Graph.tick_recurring_actions( graph )
#
#    # send the graph to the view_port
#    state = case ViewPort.update_graph( context, graph ) do
#      :ok ->            state
#      :context_lost ->  stop_heartbeat( state )
#    end
#
#    # reset the deltas
#    graph = Graph.reset_deltas( graph )
#
#    # update and return the state
#    state
#    |> Map.put( :graph, graph )
#    |> Map.put( :last_sync, :os.system_time(:millisecond) )
#  end


end