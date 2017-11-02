#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# each platform-specific version of scenic_platform must implement
# a complient version of Scenic.ViewPort. There won't be any conflics
# as by definition, there should be only one platform adapter in the
# deps of any one build-type of a project.


defmodule Scenic.ViewPort.Driver do
  use GenServer

  require Logger
  alias Scenic.ViewPort

#  import IEx

  @callback handle_set_graph( list, map ) :: {:noreply, map}
  @callback handle_update_graph( list, map ) :: {:noreply, map}
  @callback handle_sync( map ) :: {:noreply, map}

  @sync_message   :timer_sync

  #===========================================================================
  # generic apis for sending a message to the drivers

  #----------------------------------------------
  def set_graph( list )    do
    dispatch( :set_graph, list )
  end
  def update_graph( list ), do: dispatch( :update_graph, list )


  #----------------------------------------------
  def send_client_message( message ), do: dispatch( :client_message, message )

  #----------------------------------------------
  # identify the current, loaded drivers
  def identify() do
    Registry.match(:viewport_registry, :set_graph, :_)
    |> Enum.reduce( [], fn({pid, {mod,_}},acc) -> [{mod, pid} | acc] end)
  end



  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(use_opts) do
    quote do
      @behaviour Scenic.ViewPort.Driver

      def init(_),                        do: {:ok, nil}

      def default_sync_interval(),        do: unquote(use_opts[:sync_interval])

      def handle_sync( state ),           do: { :noreply, state }

      # simple, do-nothing default handlers
      def handle_call(msg, from, state),  do: { :noreply, state }
      def handle_cast(msg, state),        do: { :noreply, state }
      def handle_info(msg, state),        do: { :noreply, state }

      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        handle_sync:            1,
        handle_call:            3,
        handle_cast:            2,
        handle_info:            2,
      ]

    end # quote
  end # defmacro


  #===========================================================================
  # Driver initialization

  #--------------------------------------------------------
  def start_link({module, opts}) do
    GenServer.start_link(__MODULE__, {module, opts}, name: opts[:name])
  end

  #--------------------------------------------------------
  def init( {module, opts} ) do

    # set up the driver with the viewport registry
    {:ok, _} = Registry.register(:viewport_registry, :set_graph,    {module, :set_graph} )
    {:ok, _} = Registry.register(:viewport_registry, :update_graph, {module, :update_graph} )
    {:ok, _} = Registry.register(:viewport_registry, :driver_cast,  {module, :driver_cast} )

    # let the driver initialize itself
    {:ok, driver_state} = module.init( opts )

    state = %{
      driver_module:  module,
      driver_state:   driver_state,
      sync_interval:  nil
    }

    # get the sync_interval to use

    state = case (opts[:sync_interval] || module.default_sync_interval()) do
      nil -> state
      interval -> 
        state
        |> Map.put( :sync_interval, interval )
        |> Map.put( :last_msg, :os.system_time(:millisecond) )
        |> Map.put( :timer, :timer.send_interval(interval, @sync_message) )
    end

    {:ok, state}
  end

  #============================================================================
  # handle_call

  #--------------------------------------------------------
  # unrecognized message. Let the driver handle it
  def handle_call(msg, from, %{driver_module: mod, driver_state: d_state} = state) do
    case mod.handle_call( msg, from, d_state ) do
      { :noreply, d_state }         ->  { :noreply, Map.put(state, :driver_state, d_state) }
      { :reply, response, d_state } ->  { :reply, response, Map.put(state, :driver_state, d_state) }
    end
  end

  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  # set the graph
  def handle_cast({:set_graph, graph}, %{driver_module: mod, driver_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_set_graph( graph, d_state )

    state = state
    |> Map.put( :driver_state, d_state )
    |> Map.put( :last_msg, :os.system_time(:millisecond) )

    { :noreply, state }
  end

  #--------------------------------------------------------
  # update the graph
  def handle_cast({:update_graph, deltas}, %{driver_module: mod, driver_state: d_state} = state) do
    # don't call handle_update_graph if the list is empty
    d_state = case deltas do
      []      -> d_state
      deltas  ->
        { :noreply, d_state } = mod.handle_update_graph( deltas, d_state )
        d_state
    end
    
    state = state
    |> Map.put( :driver_state, d_state )
    |> Map.put( :last_msg, :os.system_time(:millisecond) )

    { :noreply, state }
  end

  #--------------------------------------------------------
  # unrecognized message. Let the driver handle it
  def handle_cast(msg, %{driver_module: mod, driver_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_cast( msg, d_state )
    { :noreply, Map.put(state, :driver_state, d_state) }
  end

  #============================================================================
  # handle_info

  #--------------------------------------------------------
  # there may be more than one driver sending update messages to the
  # scene. Go no faster than the fastest one
  def handle_info(@sync_message,
  %{last_msg: last_msg, driver_module: mod, driver_state: d_state, sync_interval: sync_interval} = state) do
    cur_time = :os.system_time(:millisecond)
    case (cur_time - last_msg) > sync_interval do
      true  ->
        send_client_message( :update )
        { :noreply, d_state } = mod.handle_sync( d_state )
        { :noreply, Map.put(state, :driver_state, d_state) }
      false ->
        { :noreply, state }
    end
  end


  #--------------------------------------------------------
  # unrecognized message. Let the driver handle it
  def handle_info(msg, %{driver_module: mod, driver_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_info( msg, d_state )
    { :noreply, Map.put(state, :driver_state, d_state) }
  end

  #============================================================================
  # helpers

  #----------------------------------------------
  defp dispatch( action, data ) do
    # dispatch the call to any listening drivers
    Registry.dispatch(:viewport_registry, action, fn(entries) ->
      for {pid, {module,msg}} <- entries do
        try do
          GenServer.cast(pid, {msg, data})
        catch
          kind, reason ->
            formatted = Exception.format(kind, reason, System.stacktrace)
            Logger.error "Registry.dispatch/3 failed with #{formatted}"
        end
      end
    end)
    :ok
  end


end


























