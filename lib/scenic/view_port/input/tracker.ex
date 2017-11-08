#
#  Created by Boyd Multerer on 11/06/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


defmodule Scenic.ViewPort.Input.Tracker do
  use GenServer
  alias Scenic.ViewPort.Input
  require Logger

  import IEx

  @tracker_supervisor   :trackers


  #===========================================================================
  defmodule Error do
    defexception [ message: nil ]
  end


  #===========================================================================
  # client apis



  #===========================================================================
  # the using macro for specific trackers to use
  defmacro __using__(_use_opts) do
    quote do
      def init(_),                        do: {:ok, nil}

      # simple, do-nothing default handlers
      def handle_call(msg, from, state),  do: { :noreply, state }
      def handle_cast(msg, state),        do: { :noreply, state }
      def handle_info(msg, state),        do: { :noreply, state }

      def handle_input(event, state),     do: { :noreply, state }

      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        handle_input:           2,
        handle_call:            3,
        handle_cast:            2,
        handle_info:            2,
      ]

    end # quote
  end # defmacro


  #===========================================================================
  # Driver initialization

  # using a simple_one_for_one strategy for in the supervisor as trackers are
  # dynamic in their nature. Thus providing start/stop functions here to make
  # it easy to set up.

  #--------------------------------------------------------
  def start( mod_opts, tracker_opts ) do
    {:ok, _} = Supervisor.start_child(@tracker_supervisor, [mod_opts, tracker_opts])
    :ok
  end

  #--------------------------------------------------------
  def stop( tracker_pid \\ nil )
  def stop( nil ), do: stop( self() )
  def stop( tracker_pid ) do
    Supervisor.terminate_child( @tracker_supervisor, tracker_pid )
  end

  #--------------------------------------------------------
  def start_link({module, opts}, tracker_opts) do
    GenServer.start_link(__MODULE__, {module, tracker_opts}, name: opts[:name])
  end

  #--------------------------------------------------------
  def init( {module, tracker_opts} ) do
    # let the tracker initialize itself
    {:ok, tracker_state} = module.init( tracker_opts )

    state = %{
      tracker_module:  module,
      tracker_state:   tracker_state,
    }

    {:ok, state}
  end

  #============================================================================
  # handle_call

  #--------------------------------------------------------
  # unrecognized message. Let the tracker handle it
  def handle_call(msg, from, %{tracker_module: mod, tracker_state: d_state} = state) do
    case mod.handle_call( msg, from, d_state ) do
      { :noreply, d_state }         ->  { :noreply, Map.put(state, :tracker_state, d_state) }
      { :reply, response, d_state } ->  { :reply, response, Map.put(state, :tracker_state, d_state) }
    end
  end

  #============================================================================
  # handle_cast

  #--------------------------------------------------------
  # input
  def handle_cast({:input, input},
  %{tracker_module: mod, tracker_state: d_state} = state) do
    input = Input.normalize( input )
    { :noreply, d_state } = mod.handle_input( input, d_state )
    { :noreply, Map.put(state, :tracker_state, d_state) }
  end

  #--------------------------------------------------------
  # unrecognized message. Let the tracker handle it
  def handle_cast(msg, %{tracker_module: mod, tracker_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_cast( msg, d_state )
    { :noreply, Map.put(state, :tracker_state, d_state) }
  end

  #============================================================================
  # handle_info

  #--------------------------------------------------------
  # unrecognized message. Let the tracker handle it
  def handle_info(msg, %{tracker_module: mod, tracker_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_info( msg, d_state )
    { :noreply, Map.put(state, :tracker_state, d_state) }
  end

end