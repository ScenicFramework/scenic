#
#  Created by Boyd Multerer on 04/07/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# Taking the learnings from several previous versions.

defmodule Scenic.Scene do
  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort
  alias Scenic.Primitive
  alias Scenic.Utilities

  import IEx

  @moduledoc """
  
  ## Overview

  Scenes are the core of the UI model.

  A `Scene` has two jobs.
  1) Build and maintain a graph of UI primitives that gets drawn
  to the screen.
  2) Handle input and events related to that graph.

  Before saying anything else I want to emphasize that the rest of your
  application, meaining device control logic, sensor reading / writing,
  services, whatever, do not need to have anything to do with Scenes.
  Would recommend treating those these as seperate servers in their
  own supervision trees. Then the UI Scenes would query or send
  information to/from them via cast or call messages.

  ## Scenes

  So.. scenes are the core of the UI model. A scene consists of a
  graph, which is a set of primitives that can be drawn to a screen,
  and a set of event handlers.

  Scene's can reference other scenes from the graphs. Typically,
  this means that on a typical screen of UI, there is one scene
  that is the root. Each control, it it's own scene process with
  it's own state. These child scenes can in turn contain other
  child scenes. This allows for strong code reuse, isolates knowledge
  and logic to just the pieces that need it, and keeps the size of any
  given graph to a reasonable size. For example, The graph
  hand handlers of a checkbox don't need to know anything about
  how a slider works, even though they are both used in the same
  parent scene. At best, they only need to know that they
  both conform to the `Component.Input` behaviour, and can thus
  query or set each other's value. Though it is usually
  the parent scene that does that.

  The application developer is responsible for building and
  maintaining the scene's graph. It only enters the world of the
  `ViewPort` when you call `push_graph`. Once you have called
  `push_graph`, that graph is sent to the drivers and is out of your
  immediate control. You update that graph by either calling
  `push_graph` again, or cleaning it up via `release_graph`.

  This does mean you could maintain two seperate graphs
  and rapidly switch back and forth between them via push_graph.
  I have not yet hit a good usecase for that.

  ### Graph ID.

  This is an advanced feature...

  Each scene has a default graph id of nil. When you send a graph
  to the ViewPort by calling `push_graph(graph)`, you are really
  sending it with a sub-id of nil. This encourages thinking that
  scenes and graphs have a 1:1 relationship. There are, however,
  times that you want a single scene to host multiple graphs that
  can refer to each other via sub-ids. You would push them
  like this: `push_graph(graph, id)`. Where the id is any term you
  would like to use as a key.

  There are several use cases where this makes sense.
  1) You have a complex tree (perhaps a lot of text) that you want
  to animate. Rather than re-rendering the text (relatively expensive)
  every time you simply transform a rotation matrix, you could place
  the text into it's own static sub-graph and then refer to it
  from the primary. This will save energy as you animate.

  2) Both the Remote and Recording clients make heavy use of sub-ids
  to make sense of the graph being replayed.

  The downside of using graph_ids comes with input handling.
  because you have a single scene handling the input events for
  multiple graphs, you will need to take extra care to correctly
  handle position-dependent events, which may not be projected
  into the coordinate space you think they are. The Remote and
  Recording clients deal with this by rendering a single, completely
  transparent rect above all the sub scenes. This invisible, yet
  present rect hits all the position dependent events and makes
  sure they are sent to the scene projected in to the main
  (id is nil) graph's coordinate space.

  ## Input vs. Events

  Input is data generated at the drivers and sent up to the scenes
  through the `ViewPort`. There is a limited set of input types and
  they are standardized so that the drivers can be built independantly
  of the scenes. Input follows certain rules about which scene receives them

  Events are messages that one scene generates for consumption
  by other scenes. For example, a `Component.Button` scene would
  generate a `{:click, msg}` event that is sent to it's parent
  scene.

  You can generate any message you want, however, the standard
  component libraries follow certain patterns to keep things sensible.

  ## Input Handling

  You handle incoming input events by adding `handle_input/3` functions
  to your scene. Each `handle_input/3` call passes in the input message
  itself, an input context struct, and your scene's state. You can
  then take the appropriate actions, including generating events
  (below) in response.

  Under normal operation, input that is not position dependent
  (keys, window events, more...) is sent to the root scene. Input
  that does have a screen position (cursor_pos, cursor button
  presses, etc...) Is sent to the scene that contains the
  graph that was hit.

  Your scene can "capture" all input of a given type so that
  it is sent to itself instead of the default scene for that type.
  this is how a text input field receives the key input. First,
  the user selects that field by clicking on it. In response
  to the cursor input, the text field captures text input (and
  maybe transforms it's graph to show that it is selected).

  Captured input types are should be released when no longer
  needed so that normal operation can resume.

  The input messages re not passed on to other scene if
  the first one doesn't handle it.

  ## Event Filtering

  In response to input, (or anything else... a timer perhaps?),
  a scene can generate an event (any term), which is sent backwards
  up the tree of scenes that make up the current aggregate graph.

  In this way, a `Component.Button` scene can generate a`{:click, msg}`
  event that is sent to it's parent. If the parent doesn't
  handle it, it is sent to that scene's parent. And so on util the
  event reaches the root scene. If the root scene doesn't handle
  it either then the event is dropped.

  To handle events, you add `filter_event/3` functions to your scene.
  This function handle the event, and stop it's progress backwards
  up the graph. It can handle it and allow it to continue up the
  graph. Or it can transform the event and pass the transformed
  version up the graph.

  You choose the behavior by returning either

    {:continue, msg, state}

  or

    {:stop, state}

  Parameters passed in to `filter_event/3` are the event itself, a
  reference to the originating scene (which you can to communicate
  back to it), and your scene's state.

  A pattern I'm using is to handle and event at the filter and stop
  it's progression. It also generates and sends new event to its
  parent. I do this instead of transforming and continuing when
  I want to change the originating scene.

  """


  @viewport             :viewport
  @not_activated        :__not_activated__

  #============================================================================
  # client api - working with the scene


  @doc """
  send a filterable event to a scene.

  This is very similar in feel to casting a message to a GenServer. However,
  This message will be handled by the Scene's `filter_event\3` function. If the 
  Scene returns `{:continue, msg, state}` from `filter_event\3`, then the event
  will also be sent to the scene's parent. This will continue until the message
  reaches the root scene or some other permananently supervised scene.

  Typically, when a scene wants to initiate an event, it will call `send_event/1`
  which is a private function injected into the scene during `use Scenic.Scene`

  This private version of send_event will take care of the housekeeping of
  tracking the parent's pid. It will, in turn, call this function on the main
  Scene module to send the event on it's way.

      def handle_input( {:cursor_button, {:left, :release, _, _}}, _, %{msg: msg} = state ) do
        send_event( {:click, msg} )
        {:noreply, state}
      end

  On the other hand, if you know you want to send the event to a named scene
  that you supervise yourself, then you would use `Scenic.Scene.send_event/2`

      def handle_input( {:cursor_button, {:left, :release, _, _}}, _, %{msg: msg} = state ) do
        Scenic.Scene.send_event( :some_scene, {:click, msg} )
        {:noreply, state}
      end

  Be aware that named scenes that your supervise yourself are unable to continue
  the event to their parent in the graph becuase they could be referenced by
  multiple graphs making the continuation ambiguous.
  """

  def send_event( scene_pid, event_msg ) do
    GenServer.cast(scene_pid, {:event, event_msg, self()})
  end


  def cast( scene_or_graph_key, msg ) do
    with {:ok, pid} <- ViewPort.Tables.get_scene_pid(scene_or_graph_key) do
      GenServer.cast( pid, msg )
    end
  end

  #============================================================================
  # callback definitions

  @callback init( any ) :: {:ok, any}
  @callback handle_call(any, any, any) :: {:reply, any, any} | {:noreply, any}
  @callback handle_cast(any, any) :: {:noreply, any}
  @callback handle_info(any, any) :: {:noreply, any}

  @callback handle_input(any, any, any) :: {:noreply, any, any}
  @callback filter_event( any, any, any ) :: { :continue, any, any } | {:stop, any}

  @callback handle_set_root( pid, any, any ) :: {:noreply, any}
  @callback handle_lose_root( pid, any ) :: {:noreply, any}

  #============================================================================
  # using macro

  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(opts) do
    quote do
      @behaviour Scenic.Scene

      @default_has_children__  true

      #--------------------------------------------------------
      # Here so that the scene can override if desired
      def init(_),                                    do: {:ok, nil}
      def handle_set_root( _vp, _args, state ),       do: {:noreply, state}
      def handle_lose_root( _vp, state ),             do: {:noreply, state}
 
      def handle_call(_msg, _from, state),            do: {:reply, :err_not_handled, state}
      def handle_cast(_msg, state),                   do: {:noreply, state}
      def handle_info(_msg, state),                   do: {:noreply, state}

#      def handle_raw_input( event, graph, scene_state ),  do: {:noreply, graph, scene_state}
      def handle_input( event, _, scene_state ),      do: {:noreply, scene_state}
      def filter_event( event, _from, scene_state ),  do: {:continue, event, scene_state}

      def start_dynamic_scene( supervisor, parent, args ) do
        has_children = case unquote(opts[:has_children]) do
          nil -> @default_has_children__
          true -> true
          false -> false
        end
        Scenic.Scene.start_dynamic_scene(
          supervisor, parent, __MODULE__,
          args, has_children
        )
      end

      defp send_event( event_msg ) do
        case Process.get(:parent_pid) do
          nil ->
            {:error, :no_parent}
          pid ->
            GenServer.cast(pid, {:event, event_msg, self()})
        end
      end

      defp push_graph( graph, sub_id \\ nil, manage_dynamic_children \\ true ) do
        GenServer.cast( self(), {:push_graph, graph, sub_id, manage_dynamic_children} )
        # return the graph so this can be pipelined
        graph
      end

      #--------------------------------------------------------
#      add local shortcuts to things like get/put graph and modify element
#      do not add a put element. keep it at modify to stay atomic
      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        handle_set_root:        3,
        handle_lose_root:       2,

        handle_call:            3,
        handle_cast:            2,
        handle_info:            2,

        handle_input:           3,
        filter_event:           3,

        start_dynamic_scene:    3
      ]

    end # quote
  end # defmacro


  #===========================================================================
  # calls for setting up a scene inside of a supervisor

#  def child_spec({ref, scene_module}), do:
#    child_spec({ref, scene_module, nil})

  def child_spec({scene_module, args, opts}) do
    %{
      id: make_ref(),
      start: {__MODULE__, :start_link, [scene_module, args, opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end


  #============================================================================
  # internal server api
  @doc false
  def start_link(scene_module, args, opts \\ []) do
    init_data = {scene_module, args, opts}
    case opts[:name] do
      nil ->
        GenServer.start_link(__MODULE__, init_data)
      name ->
        GenServer.start_link(__MODULE__, init_data, name: name)
    end    
  end

  #--------------------------------------------------------
  @doc false
  def init( {scene_module, args, opts} ) do
    scene_ref = opts[:scene_ref] || opts[:name]
    Process.put(:scene_ref, scene_ref)

    # interpret the options
    {parent_pid, graph_id, uid} = case opts[:parent] do
      nil -> {nil, nil, nil}
      {parent_pid, graph_id, uid} ->
        # stash the parent pid away in the process dictionary. This
        # is for fast lookup during the injected send_event/1 in the
        # client module
        Process.put(:parent_pid, parent_pid)
        {parent_pid, graph_id, uid}
    end

    # some setup needs to happen after init - must be before the scene_module init
    GenServer.cast(self(), {:after_init, args})

    # tell the viewport to start monitoring this scene
    # this is required to clean up the graph when this scene goes DOWN
    GenServer.cast(@viewport, {:monitor, self()})

    # tell the parent that this scene is alive and assocated with the given graph/uid.
    # Obvs don't do this if a root scene (no parent)
#    if parent_pid, do: GenServer.cast(parent_pid, {:put_child, graph_id, uid, self()})

    # if this scene is named... Meaning it is supervised by the app and is not a
    # dyanimic scene, then we need monitor the ViewPort. If the viewport goes
    # down while this scene is activated, the scene will need to be able to
    # deactivate itself while the viewport is recovering. This is especially
    # true since the viewport may recover to a different default scene than this.
    if opts[:name], do: Process.monitor( Scenic.ViewPort.Tables )


    # initialize the scene itself
    {:ok, sc_state} = scene_module.init( args )

    # build up the state
    state = %{
      raw_scene_refs: %{},      
      dyn_scene_pids: %{},
      dyn_scene_keys: %{},
      static_ref_names: %{},

#      viewport: {viewport_pid, viewport_tid},
      parent_pid: parent_pid,
      children: %{},

      scene_module: scene_module,

      scene_state: sc_state,
      scene_ref: scene_ref,
      supervisor_pid: nil,
      dynamic_children_pid: nil,
      activation: @not_activated
    }

    {:ok, state}
  end


  #============================================================================
  # handle_info

  #--------------------------------------------------------
  # The viewport has gone down. Deactivate this scene.
  # Note: the viewport is only monitored by this scene if it is a named scene.
  # dynamic scenes rely on their parent (or the viewport supervisor itself)
  # to take care of this for them.
  def handle_info({:DOWN, _monitor_ref, :process, pid, reason}, state) do
    state = case Process.whereis(@viewport) do
      ^pid ->
        { :reply, :ok, state } = handle_call( :deactivate, pid,  state )
      _ ->
        state
    end
    {:noreply, state}
  end

  #--------------------------------------------------------
  # generic handle_info. give the scene a chance to handle it
  def handle_info(msg, %{scene_module: mod, scene_state: sc_state} = state) do
    {:noreply, sc_state} = mod.handle_info(msg, sc_state)
    {:noreply, %{state | scene_state: sc_state}}
  end


  #============================================================================
  # handle_call


  #--------------------------------------------------------
  # The scene is losing activation. This is done syncronously (call) as the
  # next thing to happen might be process termination. This makes sure the
  # scene has a chance to clean itself up before it goes away.

  def handle_call(:lose_root, from, %{
    scene_module: mod,
    scene_state: sc_state
  } = state) do
    # tell the scene it is being deactivated
    {:noreply, sc_state} = mod.handle_lose_root( from, sc_state )
    { :reply, :ok, %{state | scene_state: sc_state, activation: @not_activated} }
  end

  def handle_call({:set_root, args}, from, %{
    scene_module: mod,
    scene_state: sc_state
  } = state) do
    # tell the scene it is being activated
    {:noreply, sc_state} = mod.handle_set_root( from, args, sc_state )
    { :reply, :ok, %{state | scene_state: sc_state, activation: args} }
  end



  #--------------------------------------------------------
#  def handle_call({:activate, args}, _, %{
#    scene_module: mod,
#    scene_state: sc_state,
#    dynamic_children_pid: nil
#  } = state) do
#IO.puts "activating childless scene"
#    # tell the scene it is being deactivated
#    {:noreply, sc_state} = mod.handle_activation( args, sc_state )
#    { :reply, :ok, %{state | scene_state: sc_state, activation: args} }
#  end
#
#  def handle_call({:activate, args}, _, %{
#    scene_module: mod,
#    scene_state: sc_state,
#    dynamic_children_pid: dyn_sub
#  } = state) do
#IO.puts "start activate call"
#
#    # activate the dynamic children
##    call_children(dyn_sub, {:activate, args})
#    cast_children(dyn_sub, {:activate, args})
#
#
#    # tell the scene it is being deactivated
#    {:noreply, sc_state} = mod.handle_activation( args, sc_state )
#
#IO.puts "end activate call"
#    { :reply, :ok, %{state | scene_state: sc_state, activation: args} }
#  end
#
#  def handle_call({:activate, args}, _, state ) do
#    pry()
#  end


  #--------------------------------------------------------
  # generic handle_call. give the scene a chance to handle it
  def handle_call(msg, from, %{scene_module: mod, scene_state: sc_state} = state) do
IO.puts"-=-=-=-=-=-=-=- unhandled scene call #{inspect(msg)} -=-=-=-=-=-=-=-"
    {:reply, reply, sc_state} = mod.handle_call(msg, from, sc_state)
    {:reply, reply, %{state | scene_state: sc_state}}
  end

  #============================================================================
  # handle_cast


  def handle_cast({:set_root, args, vp}, %{
    scene_module: mod,
    scene_state: sc_state
  } = state) do
    # tell the scene it is being activated
    {:noreply, sc_state} = mod.handle_set_root( vp, args, sc_state )
    { :noreply, %{state | scene_state: sc_state, activation: args} }
  end


  #--------------------------------------------------------
  def handle_cast({:after_init, args}, %{
    scene_module: mod,
    scene_ref: scene_ref
  } = state ) do
    # get the scene supervisors
    [supervisor_pid | _] = self()
    |> Process.info()
    |> get_in([:dictionary, :"$ancestors"])

    # make sure it is a pid and not a name
    supervisor_pid = case supervisor_pid do
      name when is_atom(name) -> Process.whereis(name)
      pid when is_pid(pid) -> pid
    end

    # make sure this is a Scene.Supervisor, not something else
    {supervisor_pid, dynamic_children_pid} = case Process.info(supervisor_pid) do
      nil -> {nil, nil}
      info ->
        case get_in( info, [:dictionary, :"$initial_call"] ) do
          {:supervisor, Scene.Supervisor, _} ->
            supervisor_pid
            dynamic_children_pid = Supervisor.which_children( supervisor_pid )
            |> Enum.find_value( fn 
              {DynamicSupervisor, pid, :supervisor, [DynamicSupervisor]} -> pid
              _ -> nil
            end)
            {supervisor_pid, dynamic_children_pid}

          _ ->
            {nil, nil}
        end
    end

    # register the scene in the scenes ets table
    Scenic.ViewPort.Tables.register_scene(
      scene_ref,
      {self(), dynamic_children_pid, supervisor_pid}
    )

    state = state
#    |> Map.put( :scene_state, sc_state)
    |> Map.put( :supervisor_pid, supervisor_pid)
    |> Map.put( :dynamic_children_pid, dynamic_children_pid)

    { :noreply, state }
  end


  #--------------------------------------------------------
#  def handle_cast({:activate, args}, %{
#    scene_module: mod,
#    scene_state: sc_state,
#  } = state) do
#    # tell the scene it is being activated
#    {:noreply, sc_state} = mod.handle_activation( args, sc_state )
#    { :noreply, %{state | scene_state: sc_state, activation: args} }
#  end

  #--------------------------------------------------------
  def handle_cast({:input, event, context}, 
  %{scene_module: mod, scene_state: sc_state} = state) do
    {:noreply, sc_state} = mod.handle_input(event, context, sc_state )
    {:noreply, %{state | scene_state: sc_state}}
  end

  #--------------------------------------------------------
  def handle_cast({:event, event, from_pid},  %{
    parent_pid: parent_pid,
    scene_module: mod,
    scene_state: sc_state
  } = state) do
    sc_state = case mod.filter_event(event, from_pid, sc_state ) do
      { :continue, event, sc_state } ->
        GenServer.cast(parent_pid, {:event, event, from_pid})
        sc_state

      {:stop, sc_state} ->
        sc_state
    end
    
    {:noreply, %{state | scene_state: sc_state}}
  end








  #--------------------------------------------------------
  # not set up for dynamic children. Take the fast path
  def handle_cast({:push_graph, graph, sub_id, false},  %{
    scene_ref: scene_ref
  } = state ) do
    graph_key = {:graph, scene_ref, sub_id}

    # TEMPORARY HACK
    # reduce the incoming graph to it's minimal form
    min_graph = Enum.reduce( graph.primitive_map, %{}, fn({uid, p}, g) ->
      Map.put( g, uid, Primitive.minimal(p) )
    end)

    # write the graph into the ets table
    ViewPort.Tables.insert_graph( graph_key, self(), graph, %{})

    # notify the drivers of the updated graph
    ViewPort.driver_cast( {:push_graph, graph_key} )

    { :noreply, state }
  end

  #--------------------------------------------------------
  # push a graph to the ets table and manage embedded dynamic child scenes
  # to the reader: You have no idea how difficult this was to get right.
  def handle_cast({:push_graph, graph, sub_id, true},  %{
    scene_ref: scene_ref,
    raw_scene_refs: raw_scene_refs,
    dyn_scene_pids: dyn_scene_pids,
    dyn_scene_keys: dyn_scene_keys,
    dynamic_children_pid: dyn_sup,
    activation: args
  } = state ) do

    # reduce the incoming graph to it's minimal form
    # while simultaneously extracting the SceneRefs
    # this should be the only full scan when pushing a graph
    {graph, all_keys, new_raw_refs} = Enum.reduce( graph.primitive_map, {%{}, %{}, %{}}, fn
      # named reference
      ({uid, %{module: Primitive.SceneRef, data: name} = p},
      {g, all_refs, dyn_refs}) when is_atom(name) ->
        g = Map.put( g, uid, Primitive.minimal(p) )
        all_refs = Map.put( all_refs, uid, {:graph, name, nil} )
        {g, all_refs, dyn_refs}

      # explicit reference
      ({uid, %{module: Primitive.SceneRef, data: {:graph,_,_} = ref} = p},
      {g, all_refs, dyn_refs}) ->
        g = Map.put( g, uid, Primitive.minimal(p) )
        all_refs = Map.put( all_refs, uid, ref )
        {g, all_refs, dyn_refs}

      # dynamic reference
      # don't add to all_refs yet. Will add after it is started (or not)
      ({uid, %{module: Primitive.SceneRef, data: {_,_} = ref} = p},
      {g, all_refs, dyn_refs}) ->
        g = Map.put( g, uid, Primitive.minimal(p) )
        dyn_refs = Map.put( dyn_refs, uid, ref )
        {g, all_refs, dyn_refs}

      # all non-SceneRef primitives
      ({uid, p}, {g, all_refs, dyn_refs}) ->
        {Map.put( g, uid, Primitive.minimal(p) ), all_refs, dyn_refs}
    end)

    # get the old refs
    old_raw_refs =  Map.get( raw_scene_refs, sub_id, %{} )
    old_dyn_pids =  Map.get( dyn_scene_pids, sub_id, %{} )
    old_dyn_keys =  Map.get( dyn_scene_keys, sub_id, %{} )

    # get the difference script between the raw and new dynamic refs
    raw_diff = Utilities.Map.difference( old_raw_refs, new_raw_refs )

    # Use the difference script to determine what to start or stop.
    {new_dyn_pids, new_dyn_keys} = Enum.reduce(raw_diff, {old_dyn_pids, old_dyn_keys}, fn
      {:put, uid, {mod, init_data}}, {old_pids, old_keys} ->  # start this dynamic scene

        unless dyn_sup do
          raise "You have set a dynamic SceneRef on a graph in a scene where has_children is false"
        end

        # start the dynamic scene
        parent = {self(), sub_id, uid}
        {:ok, pid, ref} = mod.start_dynamic_scene( dyn_sup, parent, init_data )

        # if this scene is activated, activate the new one too
#        unless args == @not_activated do
#IO.puts "::::::::: trying to cast activate a dynamic child during put_graph:::::::::"
##          GenServer.call(pid, {:activate, args})
##          GenServer.cast(pid, {:activate, args})
#        end

        # add the this dynamic child scene to tracking
        {
          Map.put(old_pids, uid, pid),
          Map.put(old_keys, uid, {:graph, ref, nil})
        }

      {:del, uid}, {old_pids, old_keys} ->  # stop this dynaic scene
        # get the old dynamic graph reference
        pid = old_pids[uid]

        # send the optional deactivate message and terminate. ok to be async
        Task.start fn ->
          GenServer.call(pid, :deactivate)
          GenServer.cast(pid, {:stop, dyn_sup})
        end

        # remove old pid and key
        {Map.delete(old_pids, uid), Map.delete(old_keys, uid)}
    end)

    # update the static ref names
    static_ref_names = Enum.reduce(all_keys, [], fn
      {:graph, name, nil}, names when is_atom(name) -> [name | names]
      _, names -> names
    end)

    # merge all_refs with the managed dyanmic keys
    all_keys = Map.merge( all_keys, new_dyn_keys )

    graph_key = {:graph, scene_ref, sub_id}

    # insert the proper graph keys back into the graph to finish normalizing
    # it for the drivers. Yes, the driver could do this from the all_keys term
    # that is also being written into the ets table, but it gets done all the
    # time for each reader and when consuming input, so it is better to do it
    # once here. Note that the all_keys term is still being written becuase
    # otherwise the drivers would need to do a full graph scan in order to prep
    # whatever translators they need. Again, the info has already been
    # calculated here, so just pass it along without throwing it out.
    graph = Enum.reduce(all_keys, graph, fn({uid, key}, g)->
      put_in(g, [uid, :data], {Scenic.Primitive.SceneRef, key})
    end)

    # write the graph into the ets table
    ViewPort.Tables.insert_graph( graph_key, self(), graph, all_keys)

    # store the refs for next time
    state = state
    |> put_in( [:raw_scene_refs, sub_id], new_raw_refs )
    |> put_in( [:dyn_scene_pids, sub_id], new_dyn_pids )
    |> put_in( [:dyn_scene_keys, sub_id], new_dyn_keys )
    |> put_in( [:static_ref_names, sub_id], static_ref_names )

    { :noreply, state }
  end








  #--------------------------------------------------------
  # generic handle_cast. give the scene a chance to handle it
  def handle_cast({:stop, dyn_sup}, %{supervisor_pid: nil} = state) do
    DynamicSupervisor.terminate_child( dyn_sup, self() )
    {:noreply, state}
  end

  #--------------------------------------------------------
  # generic handle_cast. give the scene a chance to handle it
  def handle_cast({:stop, dyn_sup}, %{supervisor_pid: supervisor_pid} = state) do
    DynamicSupervisor.terminate_child( dyn_sup, supervisor_pid )
    {:noreply, state}
  end



  #--------------------------------------------------------
  # generic handle_cast. give the scene a chance to handle it
  def handle_cast(msg, %{scene_module: mod, scene_state: sc_state} = state) do
    {:noreply, sc_state} = mod.handle_cast(msg, sc_state)
    {:noreply, %{state | scene_state: sc_state}}
  end






  #============================================================================
  # Scene managment


  #--------------------------------------------------------
  # this a root-level dynamic scene
  @doc false
  def start_dynamic_scene( dynamic_supervisor, parent, mod, args, has_children ) do
    ref = make_ref()
    has_children = case has_children do
      nil -> @children_default
      true -> true
      false -> false
    end
    do_start_child_scene( dynamic_supervisor, parent, ref, mod, args, has_children )
  end

  #--------------------------------------------------------
  defp do_start_child_scene( dynamic_supervisor, parent, ref, mod, args, true ) do
    # start the scene supervision tree
    {:ok, supervisor_pid} = DynamicSupervisor.start_child( dynamic_supervisor,
      {Scenic.Scene.Supervisor, {mod, args, [parent: parent, scene_ref: ref]}}
    )

    # we want to return the pid of the scene itself. not the supervisor
    scene_pid = Supervisor.which_children( supervisor_pid )
    |> Enum.find_value( fn 
      {_, pid, :worker, [Scenic.Scene]} ->
        pid
      _ ->
        nil
    end)

    {:ok, scene_pid, ref}
  end

  #--------------------------------------------------------
  defp do_start_child_scene( dynamic_supervisor, parent, ref, mod, args, false ) do
    {:ok, pid} = DynamicSupervisor.start_child(
      dynamic_supervisor,
      {Scenic.Scene, {mod, args, [parent: parent, scene_ref: ref]}}
    )
    {:ok, pid, ref}
  end


  #============================================================================
  # internal utilities

  #--------------------------------------------------------
  defp cast_children(dyn_supervisor, msg) do
    with {:ok, pids} <- child_pids( dyn_supervisor ) do
      Enum.each(pids, &GenServer.cast(&1, msg))
    end
  end

  #--------------------------------------------------------
  defp call_children(dyn_supervisor, msg) do
    IO.puts "------------------------------------------------"
    IO.inspect child_pids( dyn_supervisor )

    with {:ok, pids} <- child_pids( dyn_supervisor ) do
      Enum.reduce(pids, [], fn(pid, tasks)->
        task = Task.async( fn ->
IO.puts "Calling child #{inspect(pid)} with #{inspect(msg)}"
          GenServer.call(pid, msg)
        end)
        [task | tasks]
      end)
      |> Enum.reduce( [], fn(task, responses) ->
        [Task.await(task) | responses]
      end)
IO.puts "Done Calling child with #{inspect(msg)}"

    end
  end

  #--------------------------------------------------------
  defp child_pids( nil ), do: {:ok, []}
  defp child_pids( dyn_supervisor ) do
    pids = DynamicSupervisor.which_children( dyn_supervisor )
    |> Enum.reduce( [], fn
      {_, pid, :worker, [Scene]}, acc -> 
        # easy case. scene is the direct child
        [ pid | acc ]

      {_, pid, :supervisor, [Scene.Supervisor]}, acc ->
        # harder case. the child scene is under it's own supervisor
        Supervisor.which_children( pid )
        |> Enum.reduce( [], fn
          {_, pid, :worker, [Scene]}, acc -> [ pid | acc ]
          _, acc -> acc
        end)
    end)
    {:ok, pids}
  end




end






















