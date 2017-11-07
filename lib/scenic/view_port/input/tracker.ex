#
#  Created by Boyd Multerer on 11/06/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


defmodule Scenic.ViewPort.Input.Tracker do
  use GenServer

  require Logger
#  alias Scenic.ViewPort

  import IEx

  @input_registry     :input_registry


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
#      @behaviour Scenic.ViewPort.Driver

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

  #--------------------------------------------------------
  def start_link({module, opts}) do
    GenServer.start_link(__MODULE__, {module, opts}, name: opts[:name])
  end

  #--------------------------------------------------------
  def init( {module, opts} ) do

    # let the tracker initialize itself
    {:ok, tracker_state} = module.init( opts )

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


























