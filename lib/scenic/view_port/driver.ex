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

  @sync_message       :timer_sync
  
  @driver_registry    :driver_registry

  #===========================================================================
  defmodule Error do
    defexception [ message: nil ]
  end

  #===========================================================================
  # generic apis for sending a message to the drivers

  #----------------------------------------------
  def set_graph( list )    do
    dispatch( :set_graph, list )
  end

  #----------------------------------------------
  def update_graph( list ) do
    dispatch( :update_graph, list )
  end

  #----------------------------------------------
  # identify the current, loaded drivers
  def identify() do
    Registry.match(@driver_registry, :identify, :_)
    |> Enum.reduce( [], fn({pid, mod_opts},acc) -> [{mod_opts, pid} | acc] end)
  end

  def cast( message ) do
    dispatch( :driver_cast, message )
  end

  # client api helpers
  #----------------------------------------------
  defp dispatch( action, data ) do
    # dispatch the call to any listening drivers
    Registry.dispatch(@driver_registry, action, fn(entries) ->
      for {pid, msg} <- entries do
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


  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(use_opts) do
    quote do
      def init(_),                        do: {:ok, nil}

      def default_sync_interval(),        do: unquote(use_opts[:sync_interval])

      def handle_sync( state ),           do: { :noreply, state }

      # simple, do-nothing default handlers
      def handle_call(msg, from, state),  do: { :noreply, state }
      def handle_cast(msg, state),        do: { :noreply, state }
      def handle_info(msg, state),        do: { :noreply, state }

      def start_params(args) do
        Supervisor.child_spec({ViewPort.Driver, {__MODULE__, args}}, id: args[:name])
      end

      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        handle_sync:            1,
        handle_call:            3,
        handle_cast:            2,
        handle_info:            2,
        start_params:           1
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
    {:ok, _} = Registry.register(:driver_registry, :set_graph,    :set_graph )
    {:ok, _} = Registry.register(:driver_registry, :update_graph, :update_graph )
    {:ok, _} = Registry.register(:driver_registry, :driver_cast,  :driver_cast )
    {:ok, _} = Registry.register(:driver_registry, :identify,     {module, opts} )

    # let the driver initialize itself
    {:ok, driver_state} = module.init( opts )

    state = %{
      driver_module:  module,
      driver_state:   driver_state,
      sync_interval:  nil
    }

    # get the correct sync interval
    interval = case Keyword.get(opts, :sync_interval, :none) do
      nil      -> nil
      :none    -> module.default_sync_interval()
      interval -> interval
    end

    # set up the sync timing
    state = case interval do
      nil -> state
      interval when is_integer(interval) and (interval > 0) -> 
        {:ok, timer} = :timer.send_interval(interval, @sync_message)
        state
        |> Map.put( :sync_interval, interval )
        |> Map.put( :last_msg, :os.system_time(:millisecond) )
        |> Map.put( :timer, timer )
      _ -> raise Error, message: "Invalid interval. Must be a positive integer or nil."
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
    { :noreply, d_state } = mod.handle_cast( {:set_graph, graph}, d_state )

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
        { :noreply, d_state } = mod.handle_cast( {:update_graph, deltas}, d_state )
        d_state
    end
    
    state = state
    |> Map.put( :driver_state, d_state )
    |> Map.put( :last_msg, :os.system_time(:millisecond) )

    { :noreply, state }
  end

  #--------------------------------------------------------
  # unrecognized message. Let the driver handle it
  def handle_cast({:driver_cast, msg}, %{driver_module: mod, driver_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_cast( msg, d_state )
    { :noreply, Map.put(state, :driver_state, d_state) }
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
        ViewPort.send_to_scene( :graph_update )
        { :noreply, d_state } = mod.handle_cast( :sync, d_state )
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



end


























