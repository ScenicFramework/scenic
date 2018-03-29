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
  @callback handle_activate(any, any, any) :: {:noreply, any}
  @callback handle_deactivate(any, any) :: {:noreply, any}


  #===========================================================================
  # calls for setting up a scene inside of a supervisor

  def child_spec({ref, scene_module}), do:
    child_spec({ref, scene_module, nil})

  def child_spec({ref, scene_module, args}) do
    %{
      id: ref,
      start: {__MODULE__, :start_link, [{ref, scene_module, args}]},
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

  def terminate( scene_pid ) do
    GenServer.cast(scene_pid, :terminate)
  end

  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Scene

      #--------------------------------------------------------
      # Here so that the scene can override if desired
      def init(_),                                do: {:ok, nil}
      def handle_activate( _id, _args, state ),   do: {:noreply, state}
      def handle_deactivate( _id, state ),        do: {:noreply, state}
 
      def handle_call(_msg, _from, state),        do: {:reply, :err_not_handled, state}
      def handle_cast(_msg, state),               do: {:noreply, state}
      def handle_info(_msg, state),               do: {:noreply, state}

#      def handle_raw_input( event, graph, scene_state ),  do: {:noreply, graph, scene_state}
      def handle_input( event, _, scene_state ),  do: {:noreply, scene_state}
      def filter_event( event, scene_state ),     do: {:continue, event, scene_state}

      def send_event( event, %Scenic.ViewPort.Input.Context{} = context ),
        do: Scenic.Scene.send_event( event, context.event_chain )

      #--------------------------------------------------------
#      add local shortcuts to things like get/put graph and modify element
#      do not add a put element. keep it at modify to stay atomic
      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        handle_activate:        3,
        handle_deactivate:      2,

        handle_call:            3,
        handle_cast:            2,
        handle_info:            2,

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

  def start_link({name, module, args}) when is_atom(name) do
    GenServer.start_link(__MODULE__, {name, module, args}, name: name)
  end

  def start_link({ref, module, args}) when is_reference(ref) do
    GenServer.start_link(__MODULE__, {ref, module, args})
  end

  #--------------------------------------------------------
  def init( {scene_ref, module, args} ) do
    Process.put(:scene_ref, scene_ref)

    GenServer.cast(self(), {:after_init, scene_ref, args})

    state = %{
      scene_module: module
    }

    {:ok, state}
  end



  #--------------------------------------------------------
  def start_dynamic_scene( dynamic_supervisor, ref, mod, opts ) do
    # start the scene supervision tree
    {:ok, scene_super_pid} = DynamicSupervisor.start_child( dynamic_supervisor,
      {Scenic.Scene.Supervisor, {ref, mod, opts}}
    )

    # we want to return the pid of the scene itself. not the supervisor
    scene_pid = get_supervised_scene( scene_super_pid )

    {:ok, scene_pid}
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
  def handle_call({:activate, id, args}, %{
    scene_module: mod,
    scene_state: sc_state,
  } = state) do
    # tell the scene it is being activated
    {:noreply, sc_state} = mod.handle_activate( id, args, sc_state )
    { :noreply, %{state | scene_state: sc_state} }
  end


  #--------------------------------------------------------
  # support for losing focus
  def handle_call({:deactivate, id}, _, %{
    scene_module: mod,
    scene_state: sc_state,
  } = state) do
    # tell the scene it is being deactivated
    {:noreply, sc_state} = mod.handle_deactivate( id, sc_state )
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
  def handle_cast({:after_init, scene_ref, args}, %{ scene_module: module } = state) do

    # get the scene supervisors
    [supervisor_pid | _] = self()
    |> Process.info()
    |> get_in([:dictionary, :"$ancestors"])

    dynamic_children_pid = Supervisor.which_children( supervisor_pid )
    |> Enum.find_value( fn 
      {DynamicSupervisor, pid, :supervisor, [DynamicSupervisor]} -> pid
      _ -> nil
    end)

    # register the scene with the viewport
    ViewPort.register_scene( scene_ref, self(), dynamic_children_pid, supervisor_pid )

    # initialize the scene itself
    {:ok, sc_state} = module.init( args )

    # if this init is recovering from a crash, then the scene_ref will be able to
    # recover a list of graphs associated with it. Activate the ones that are... active
    sc_state = ViewPort.list_scene_activations( scene_ref )
    |> Enum.reduce( sc_state, fn({id,args},ss) ->
      {:noreply, ss} = module.handle_activate( id, args, ss )
      ss
    end)

    state = state
    |> Map.put( :scene_state, sc_state)
    |> Map.put( :supervisor_pid, supervisor_pid)
    |> Map.put( :dynamic_children_pid, dynamic_children_pid)

    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast(:terminate, %{ supervisor_pid: supervisor_pid } = state) do
    Supervisor.stop(supervisor_pid)
    {:noreply, state}
  end

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
  # generic cast. give the scene a chance to handle it
  def handle_cast(msg, %{scene_module: mod, scene_state: sc_state} = state) do
    {:noreply, sc_state} = mod.handle_cast(msg, sc_state)
    {:noreply, %{state | scene_state: sc_state}}
  end

  def handle_cast(msg, state) do
#    pry()
    {:noreply, state}
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

  #--------------------------------------------------------
  # internal utility. Given a pid to a Scenic.Scene.Supervisor
  # return the pid of the scene it supervises
  defp get_supervised_scene( supervisor_pid ) do
    Supervisor.which_children( supervisor_pid )
    |> Enum.find_value( fn 
      {_, pid, :worker, [Scenic.Scene]} ->
        pid
      _ ->
        nil
    end)
  end

end








