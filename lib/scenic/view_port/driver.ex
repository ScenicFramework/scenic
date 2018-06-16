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
  alias Scenic.ViewPort

#  import IEx

  #============================================================================
  # callback definitions

  @callback init( any ) :: {:ok, any}
  @callback handle_call(any, any, any) :: {:reply, any, any} | {:noreply, any}
  @callback handle_cast(any, any) :: {:noreply, any}
  @callback handle_info(any, any) :: {:noreply, any}

  #--------------------------------------------------------
  def start( viewport, %ViewPort.Driver.Config{} = config ) when
  (is_atom(viewport) or is_pid(viewport) ) do
    GenServer.call(viewport, { :start_driver, config })
  end
  def start( viewport, %{} = config ) do
    start( viewport, struct(ViewPort.Driver.Config, config) )
  end

  #--------------------------------------------------------
  # cast stop to driver as the viewport is stored in it's state
  def stop( driver_pid ) when is_pid(driver_pid) do
    GenServer.cast(driver_pid, :stop )
  end

  #===========================================================================
  defmodule Error do
    defexception [ message: nil ]
  end

  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.ViewPort.Driver
      
      def init(_),                        do: {:ok, nil}

      # simple, do-nothing default handlers
      def handle_call(msg, from, state),  do: { :reply, :error_no_impl, state }
      def handle_cast(msg, state),        do: { :noreply, state }
      def handle_info(msg, state),        do: { :noreply, state }

      def child_spec({name, config}) do
        %{
          id: name,
          start: {ViewPort.Driver, :start_link, [{__MODULE__, name, config}]},
          restart: :permanent,
          shutdown: 5000,
          type: :worker
        }
      end

      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        handle_call:            3,
        handle_cast:            2,
        handle_info:            2,
        child_spec:             1
      ]

    end # quote
  end # defmacro


  #===========================================================================
  # Driver initialization


    def child_spec({root_sup, config}) do
    %{
      id: make_ref(),
      start: {__MODULE__, :start_link, [{root_sup, config}]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end


  #--------------------------------------------------------
  def start_link({_, config} = args) do
    case config[:name] do
      nil -> GenServer.start_link(__MODULE__, args)
      name -> GenServer.start_link(__MODULE__, args, name: name)
    end
  end


  #--------------------------------------------------------
  def init( {root_sup, config} ) do
    GenServer.cast(self(), {:after_init, root_sup, config})
    {:ok, nil}
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
  # finish init
  def handle_cast({:after_init, vp_supervisor, config}, _) do
    # find the viewport this driver belongs to
    viewport_pid = vp_supervisor
    |> Supervisor.which_children()
    |> Enum.find_value( fn
      {_, pid, :worker, [Scenic.ViewPort]} -> pid
      _ -> false
    end)    

    # let the driver module initialize itself
    module = config.module
     {:ok, driver_state} = module.init( viewport_pid, config[:opts] || %{} )

    state = %{
      viewport: viewport_pid,
      driver_module:  module,
      driver_state:   driver_state
    }

    { :noreply, state }
  end

  #--------------------------------------------------------
  # tell the viewport to stop this driver
  def handle_cast(:stop, %{viewport: viewport} = state) do
    GenServer.cast(viewport, { :stop_driver, self() })
    { :noreply, state }
  end

  #--------------------------------------------------------
  # set the graph
  # def handle_cast({:set_graph, _} = msg, %{driver_module: mod, driver_state: d_state} = state) do
  #   { :noreply, d_state } = mod.handle_cast( msg, d_state )

  #   state = state
  #   |> Map.put( :driver_state, d_state )
  #   |> Map.put( :last_msg, :os.system_time(:millisecond) )

  #   { :noreply, state }
  # end

  #--------------------------------------------------------
  # update the graph
  # def handle_cast({:update_graph, {_, deltas}} = msg, %{driver_module: mod, driver_state: d_state} = state) do
  #   # don't call handle_update_graph if the list is empty
  #   d_state = case deltas do
  #     []      -> d_state
  #     _  ->
  #       { :noreply, d_state } = mod.handle_cast( msg, d_state )
  #       d_state
  #   end
    
  #   state = state
  #   |> Map.put( :driver_state, d_state )
  #   |> Map.put( :last_msg, :os.system_time(:millisecond) )

  #   { :noreply, state }
  # end

  #--------------------------------------------------------
  # unrecognized message. Let the driver handle it
  def handle_cast(msg, %{driver_module: mod, driver_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_cast( msg, d_state )
    { :noreply, Map.put(state, :driver_state, d_state) }
  end

  #============================================================================
  # handle_info

  #--------------------------------------------------------
  # unrecognized message. Let the driver handle it
  def handle_info(msg, %{driver_module: mod, driver_state: d_state} = state) do
    { :noreply, d_state } = mod.handle_info( msg, d_state )
    { :noreply, Map.put(state, :driver_state, d_state) }
  end



end


























