#
#  Created by Boyd Multerer on 04/07/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# Taking the learnings from several previous versions.

defmodule Scenic.Scene3 do
  alias Scenic.Scene3, as: Scene
  alias Scenic.ViewPort3, as: ViewPort

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







  # ets table names
  @ets_graphs_table     ViewPort.graphs_table()




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

  #============================================================================
  # callback definitions

  @callback init( any ) :: {:ok, any}
  @callback handle_call(any, any, any) :: {:reply, any, any} | {:noreply, any}
  @callback handle_cast(any, any) :: {:noreply, any}
  @callback handle_info(any, any) :: {:noreply, any}

  @callback handle_input(any, any, any) :: {:noreply, any, any}
  @callback filter_event( any, any, any ) :: { :continue, any, any } | {:stop, any}

  @callback handle_activate(any, any) :: {:noreply, any}
  @callback handle_deactivate(any) :: {:noreply, any}

  #============================================================================
  # using macro

  #===========================================================================
  # the using macro for scenes adopting this behavioiur
  defmacro __using__(opts) do
    quote do
      @behaviour Scenic.Scene

      #--------------------------------------------------------
      # Here so that the scene can override if desired
      def init(_),                                    do: {:ok, nil}
      def handle_activate( _args, state ),            do: {:noreply, state}
      def handle_deactivate( state ),                 do: {:noreply, state}
 
      def handle_call(_msg, _from, state),            do: {:reply, :err_not_handled, state}
      def handle_cast(_msg, state),                   do: {:noreply, state}
      def handle_info(_msg, state),                   do: {:noreply, state}

#      def handle_raw_input( event, graph, scene_state ),  do: {:noreply, graph, scene_state}
      def handle_input( event, _, scene_state ),      do: {:noreply, scene_state}
      def filter_event( event, _from, scene_state ),  do: {:continue, event, scene_state}

      def start_child_scene( parent_scene, ref, args ) do
        Scenic.Scene.start_child_scene(
          parent_scene, ref, __MODULE__,
          args, unquote(opts[:has_children])
        )
      end

      defp send_event( event_msg ) do
        case Process.get(:parent_pid) do
          nil ->
            {:error, :no_parent}
          pid ->
            GenServer.cast(pid, {:event, event_msg})
        end
      end

      defp push_graph( graph, sub_id \\ nil ) do
        Scenic.Scene.push_graph( graph, sub_id )
      end

      #--------------------------------------------------------
#      add local shortcuts to things like get/put graph and modify element
#      do not add a put element. keep it at modify to stay atomic
      #--------------------------------------------------------
      defoverridable [
        init:                   1,
        handle_activate:        2,
        handle_deactivate:      1,

        handle_call:            3,
        handle_cast:            2,
        handle_info:            2,

        handle_input:           3,
        filter_event:           3,

        start_child_scene:      3
      ]

    end # quote
  end # defmacro



  #============================================================================
  # internal server api
  @doc false
  def start_link(viewport_pid, module, args, opts \\ []) do
    init_data = {viewport_pid, module, args, opts}
    case opts[:name] do
      nil ->
        GenServer.start_link(__MODULE__, init_data)
      name ->
        GenServer.start_link(__MODULE__, init_data, name: name)
    end    
  end

  #--------------------------------------------------------
  @doc false
  def init( {viewport_pid, module, args, opts} ) do

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

    # only fetch the tid from the viewport if it wasn't supplied
    viewport_tid = case opts[:viewport_tid] do
      nil ->
        {:ok, viewport_table} = GenServer.call(viewport_pid, :get_graph_table)
        viewport_table
      tid -> tid
    end

    # there should always be a tid. Stash that away in the process dictionary
    # so that it can be quickly used by the injected push_graph function
    Process.put(:viewport_tid, viewport_tid)

    # initialize the scene itself
    {:ok, sc_state} = module.init( args )

    # tell the viewport to start monitoring this scene
    GenServer.cast(viewport_pid, {:monitor_scene, self()})

    # some setup needs to happen after init
    GenServer.cast(self(), :after_init)

    # tell the parent that this scene is ready and assocated with the given graph/uid.
    # Obvs don't do this if a root scene (no parent)
    if parent_pid, do: GenServer.cast(parent_pid, {:put_child, graph_id, uid, self()})

    # build up the state
    state = %{
      viewport_pid: viewport_pid,
      viewport_tid: viewport_tid,
      parent_pid: parent_pid,
      children: %{},
      activation: :__not_set__,

      scene_state: sc_state,
      scene_module: module
    }

    {:ok, state}
  end

  #============================================================================
  # handle_call


  #--------------------------------------------------------
  # The scene is losing activation. This is done syncronously (call) as the
  # next thing to happen might be process termination. This makes sure the
  # scene has a chance to clean itself up before it goes away.

  def handle_call(:deactivate, _, %{
    scene_module: mod,
    scene_state: sc_state,
  } = state) do
    # tell the scene it is being deactivated
    {:noreply, sc_state} = mod.handle_deactivate( sc_state )
    { :reply, :ok, %{state | scene_state: sc_state, activation: :__not_set__} }
  end

  #--------------------------------------------------------
  # generic handle_call. give the scene a chance to handle it
  def handle_call(msg, from, %{scene_module: mod, scene_state: sc_state} = state) do
    {:reply, reply, sc_state} = mod.handle_call(msg, from, sc_state)
    {:reply, reply, %{state | scene_state: sc_state}}
  end

  #============================================================================
  # handle_cast

  #--------------------------------------------------------
#  def handle_cast(:after_init, state ) do
#  end

  #--------------------------------------------------------
  def handle_cast({:put_child, graph_id, uid, child_pid}, %{
    activation: args
  } = state ) do
    {:noreply, put_in( state, [:children, graph_id, uid], child_pid ) }
  end

  #--------------------------------------------------------
  def handle_cast({:activate, args, activation_ref}, %{
    viewport_pid: viewport_pid,
    scene_module: mod,
    scene_state: sc_state,
  } = state) do
#    ViewPort.register_activation( scene_ref, args )

    # tell the scene it is being activated
    {:noreply, sc_state} = mod.handle_activate( args, sc_state )

    # have the ViewPort activate the children
    #GenServer.call(viewport_pid, {:activate_children, scene_ref, args, activation_root})

    # tell the ViewPort this activation is complete (if a secquence is requested)
    if activation_ref do
      GenServer.cast(viewport_pid, {:activation_complete, self, activation_ref})
    end

    { :noreply, %{state | scene_state: sc_state, activation: args} }
  end


# activation: :__not_set__

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
  # generic handle_cast. give the scene a chance to handle it
  def handle_cast(msg, %{scene_module: mod, scene_state: sc_state} = state) do
    {:noreply, sc_state} = mod.handle_cast(msg, sc_state)
    {:noreply, %{state | scene_state: sc_state}}
  end

  #============================================================================
  # handle_info

  #--------------------------------------------------------
  # generic handle_info. give the scene a chance to handle it
  def handle_info(msg, %{scene_module: mod, scene_state: sc_state} = state) do
    {:noreply, sc_state} = mod.handle_info(msg, sc_state)
    {:noreply, %{state | scene_state: sc_state}}
  end




  #============================================================================
  # internal utilities

  # not documented as it should be called via the push_graph/2 that in injected
  # into the scene module
  # push_graph adds the graph to the viewport's graph ets table. This could
  # live in viewport, which would receive the graph via cast. However, the
  # graph could be big and it seems better to avoid the cast.
  @doc false
  def push_graph( scene, sub_id, graph ) do
    tid = case Process.get(:viewport_tid) do
      nil ->
        raise "push_graph must be called from a scene process"
      tid ->
        tid
    end

    # build the key for the graph table
    key = {:graph, id, sub_id}

  end


end






















