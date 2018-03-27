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
  alias Scenic.ViewPort.Input.Context
  alias Scenic.Primitive
  require Logger

  import IEx

  @callback init( any ) :: {:ok, any}



  # interacting with the scene's graph
  
  @callback handle_call(any, any, any) :: {:reply, any, any} | {:noreply, any}
  @callback handle_cast(any, any) :: {:noreply, any}
  @callback handle_info(any, any) :: {:noreply, any}

#  @callback handle_raw_input(any, any, any) :: {:noreply, any, any}
  @callback handle_input(any, any, any) :: {:noreply, any, any}

  @callback filter_event( any, any ) :: { :continue, any, any } | {:stop, any}

#  @callback handle_reset(any, any) :: {:noreply, any, any}
#  @callback handle_update(any, any) :: {:noreply, any, any}
  @callback handle_focus_gained(any, any) :: {:noreply, any}
  @callback handle_focus_lost(any) :: {:noreply, any}


  #===========================================================================
  # calls for setting up a scene inside of a supervisor

  def child_spec({super_pid, scene_module, id}), do:
    child_spec({super_pid, scene_module, id, nil})

  def child_spec({super_pid, scene_module, id, args}) do
    %{
      id: id,
      start: {__MODULE__, :start_link, [{super_pid, scene_module, id, args}]},
      type: :worker,
      restart: :permanent,
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


  def send_event( event, event_chain )
  def send_event( event, [] ), do: :ok
  def send_event( event, [scene_pid | tail] ) do
    GenServer.cast(scene_pid, {:event, event, tail})
  end

  def send_event( event, other ) do
    pry()
  end


  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Scene

      #--------------------------------------------------------
      # Here so that the scene can override if desired
 
      def handle_call(_msg, _from, state),        do: {:reply, :err_not_handled, state}
      def handle_cast(_msg, state),               do: {:noreply, state}
      def handle_info(_msg, state),               do: {:noreply, state}

#      def handle_raw_input( event, graph, scene_state ),  do: {:noreply, graph, scene_state}
      def handle_input( event, _, scene_state ),  do: {:noreply, scene_state}
      def filter_event( event, scene_state ),     do: {:continue, event, scene_state}

#      def filter_input( event, graph, scene_state ),    do: {:continue, event, graph, scene_state}

#      def handle_reset(graph, scene_state),             do: Scenic.Scene.handle_reset(graph, scene_state)
#      def handle_update(graph, scene_state),            do: Scenic.Scene.handle_update(graph, scene_state)

#      def graph_set_list(graph, _),                     do: Scenic.Scene.graph_set_list(graph)
#      def graph_delta_list(graph, _),                   do: Scenic.Scene.graph_delta_list(graph)

      def handle_focus_gained( _param, state ),   do: {:noreply, state}
      def handle_focus_lost( state ),             do: {:noreply, state}

      def send_event( event, %Scenic.ViewPort.Input.Context{} = context ),
        do: Scenic.Scene.send_event( event, context.event_chain )

      #--------------------------------------------------------
#      add local shortcuts to things like get/put graph and modify element
#      do not add a put element. keep it at modify to stay atomic
      #--------------------------------------------------------
      defoverridable [
        handle_call:            3,
        handle_cast:            2,
        handle_info:            2,
        handle_focus_gained:    2,
        handle_focus_lost:      1,

        handle_input:           3,
        filter_event:           2,
      ]

    end # quote
  end # defmacro


  #===========================================================================
  # internal code to this module

  #===========================================================================
  # Scene initialization


  #--------------------------------------------------------
#  def start_link(super_pid, ref, module) do
#    name_ref = make_ref()
#    GenServer.start_link(__MODULE__, {ref, module, nil})
#  end

  def start_link({super_pid, name, module, args}) when is_atom(name) do
    GenServer.start_link(__MODULE__, {super_pid, name, module, args}, name: name)
  end

  def start_link({super_pid, ref, module, args}) when is_reference(ref) do
    GenServer.start_link(__MODULE__, {super_pid, ref, module, args})
  end

  #--------------------------------------------------------
  def init( {super_pid, scene_ref, module, opts} ) do
    Process.put(:scene_ref, scene_ref)
    ViewPort.register_scene( scene_ref, self(), super_pid )

    {:ok, scene_state} = module.init(opts)

    state = %{
      scene_module:       module,
      scene_state:        scene_state,
      supervisor:         super_pid
    }
    {:ok, state}
  end

  #--------------------------------------------------------
  def start_dynamic_scene( dynamic_supervisor, ref, mod, opts ) do
    # start the scene's dynamic supervisor
    {:ok, super_pid} = DynamicSupervisor.start_child(
      dynamic_supervisor,
      {DynamicSupervisor, strategy: :one_for_one}
    )
    # start the scene itself
    {:ok, scene_pid} = DynamicSupervisor.start_child(
      super_pid,
      {Scenic.Scene, {super_pid, ref, mod, opts}}
    )
    {:ok, super_pid, scene_pid}
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
  # support for losing focus
  def handle_call(:focus_lost, _, %{scene_module: mod, scene_state: sc_state} = state) do
    # tell the scene it is gaining focus
    {:noreply, sc_state} = mod.handle_focus_lost( sc_state )
    { :reply, :ok, %{state | scene_state: sc_state} }
  end

  #--------------------------------------------------------
  # generic call. give the scene a chance to handle it
  def handle_call(msg, from, %{scene_module: mod, scene_state: sc_state} = state) do
    {:reply, reply, sc_state} = mod.handle_call(msg, from, sc_state)
    {:reply, reply, %{state | scene_state: sc_state}}
  end


  #===========================================================================
  # default cast handlers.

  #--------------------------------------------------------
  def handle_cast({:input, event, context}, 
  %{scene_module: mod, scene_state: sc_state} = state) do
    {:noreply, sc_state} = mod.handle_input(event, context, sc_state )
    {:noreply, %{state | scene_state: sc_state}}
  end


  #--------------------------------------------------------
  def handle_cast({:event, event, event_chain}, 
  %{scene_module: mod, scene_state: sc_state} = state) do

    sc_state = case mod.filter_event(event, sc_state ) do
      { :continue, event, sc_state } ->
        send_event( event, event_chain )
        sc_state

      {:stop, sc_state} ->
        sc_state
    end
    
    {:noreply, %{state | scene_state: sc_state}}
  end

  #--------------------------------------------------------
  def handle_cast({:focus_gained, param}, %{scene_module: mod, scene_state: sc_state} = state) do
    # tell the scene it is gaining focus
    {:noreply, sc_state} = mod.handle_focus_gained( param, sc_state )

    # send self a message to set the graph
#    GenServer.cast( self(), {:set_graph, nil} )

    { :noreply, %{state | scene_state: sc_state} }
  end

  #--------------------------------------------------------
  # generic cast. give the scene a chance to handle it
  def handle_cast(msg, %{scene_module: mod, scene_state: sc_state} = state) do
    {:noreply, sc_state} = mod.handle_cast(msg, sc_state)
    {:noreply, %{state | scene_state: sc_state}}
  end

  def handle_cast(msg, state) do
    pry()
  end

  #===========================================================================
  # info handlers

  #--------------------------------------------------------
  # generic info. give the scene a chance to handle it
  def handle_info(msg, %{scene_module: mod, scene_state: sc_state} = state) do
    {:noreply, sc_state} = mod.handle_info(msg, sc_state)
    {:noreply, %{state | scene_state: sc_state}}
  end

  #============================================================================
  # utilities

#  #--------------------------------------------------------
#  # input has been received. If it has x,y coords, then need to be transformed
#  # into the local coordinate space
#  defp transform_input_local( input, inverse_transform )
#  defp transform_input_local( input, _ ) do
#    input
#  end
#
#  #--------------------------------------------------------
#  # input is continuing on. If it is a standard event with x,y coords it is
#  # in local space. Transform back into global space for the next filter.
#  # can't just pass it along because the previous filter may have transformed
#  # it in some way....
#  defp transform_input_global( input, inverse_transform )
#  defp transform_input_global( input, _ ) do
#    input
#  end
#
#  defp continue_input_filter( _, [] ), do: :ok
#  defp continue_input_filter( input, [pid | tail] ) do
#    GenServer.cast(pid, {:filter_input, input, tail})
#  end
#
#
#  #--------------------------------------------------------
#  def graph_set_list(graph) do
#    Graph.minimal(graph)
#  end
#  def graph_delta_list(graph) do
#    Graph.get_delta_scripts(graph)
#  end
end








