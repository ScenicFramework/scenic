#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# each platform-specific version of scenic_platform must implement
# a complient version of Scenic.ViewPort. There won't be any conflics
# as by definition, there should be only one platform adapter in the
# deps of any one build-type of a project.


defmodule Scenic.ViewPort.Driver do
  require Logger
  alias Scenic.ViewPort

  @callback set_graph(list, pid) :: atom
  @callback update_graph(list, pid) :: atom
#  @callback driver_cast(any, pid) :: atom

#  @callback handle_set_graph( map ) :: {:noreply, map}
#  @callback handle_update_graph( map ) :: {:noreply, map}
  @callback handle_sync( map ) :: {:noreply, map}


  @sync_message   :timer_sync

  #===========================================================================
  # generic apis for sending a message to the drivers
  #--------------------------------------------------------
  def cast( message ) do
    dispatch( :driver_cast, message )
  end

  #----------------------------------------------
  def set_graph( list ),    do: dispatch( :set_graph, list )
  def update_graph( list ), do: dispatch( :update_graph, list )

  #----------------------------------------------
  defp dispatch( action, data ) do
    # dispatch the call to any listening drivers
    Registry.dispatch(:viewport_registry, action, fn(entries) ->
      for {pid, {module, func}} <- entries do
        try do
          apply(module, func, [data, pid])
        catch
          kind, reason ->
            formatted = Exception.format(kind, reason, System.stacktrace)
            Logger.error "Registry.dispatch/3 failed with #{formatted}"
        end
      end
    end)
    :ok
  end

  #----------------------------------------------
  def send_client_message( message ), do: dispatch( :client_message, message )



  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(use_opts) do
    quote do
      use GenServer
      @behaviour Scenic.ViewPort.Driver

      def init(_),          do: {:ok, nil}

      def sync_interval(),  do: unquote(use_opts[:sync_interval])

#      def send_client_message( message ),
#        do: Scenic.ViewPort.Driver.send_client_message( message )

      def handle_sync( state ),         do: { :noreply, state }





#      def driver_cast( message, pid ) do
#        GenServer.cast( pid, {:driver_cast, message})
#      end

#      def handle_cast({:driver_cast, :identify}, state) do
#        ViewPort.Driver.send_client_message( {:driver_identify, __MODULE__, self()} )
#        {:noreply, state}
#      end




      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        handle_sync:            1,
      ]

    end # quote
  end # defmacro


  #===========================================================================
  # Driver initialization

  #--------------------------------------------------------
  def start_link(module, opts) do
    GenServer.start_link(__MODULE__, {module, opts}, name: opts[:name])
  end

  #--------------------------------------------------------
  def init( {module, opts} ) do
    {:ok, driver_state} = module.init( opts )

    state = %{
      driver_module:  module,
      driver_state:   driver_state,
    }

    state = case module.sync_interval() do
      nil -> state
      interval -> 
        state
        |> Map.put( :last_msg, :os.system_time(:millisecond) )
        |> Map.put( :timer, :timer.send_interval(interval, @sync_message) )
    end

    {:ok, state}
  end

  #--------------------------------------------------------
  # there may be more than one driver sending update messages to the
  # scene. Go no faster than the fastest one
  def handle_info(@sync_message, %{last_msg: last_msg, driver_module: mod, driver_state: d_state} = state) do
    cur_time = :os.system_time(:millisecond)
    case (cur_time - last_msg) > mod.sync_interval() do
      true  ->
        send_client_message( :update )
        { :noreply, d_state } = mod.handle_sync( d_state )
        { :noreply, Map.put(state, :driver_state, d_state) }
      false ->
        { :noreply, state }
    end
  end


end


























