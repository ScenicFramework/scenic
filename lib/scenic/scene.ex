#
#  Created by Boyd Multerer on 2018-04-07.
#  Heavily reworked by Boyd Multerer on 2021-02-11.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#
# Taking the learnings from several previous versions.

defmodule Scenic.Scene do
  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.Component
  alias Scenic.ViewPort
  alias Scenic.Primitive
  alias Scenic.Math

  alias Scenic.Utilities.Validators

  require Logger

  # import IEx

  @moduledoc """

  ## Overview

  Scenes are the core of the UI model.

  A Scene is a type of GenServer that maintains state, handles input,
  events and other messages, and plays a role managing the supervision of
  components/controls such as buttons and other input.

  ### A brief aside

  Before saying anything else I want to emphasize that the rest of your
  application, meaning device control logic, sensor reading / writing,
  services, whatever, does not need to have anything to do with Scenes.

  In many cases I recommend treating those as separate GenServers in their
  own supervision trees that you maintain. Then your Scenes would query or send
  information to/from them via cast or call messages.

  Part of the point of using Elixir/Erlang/OTP is separating this sort of
  logic into independent trees. That way, an error in one part of your
  application does not mean the rest of it will fail.

  ## Scenes

  Scenes are the core of the UI model. A scene consists of one or more
  graphs, and a set of event handlers and filters to deal with user input
  and other messages.

  Think of a scene as being a little like an HTML page. HTML pages have:

  * Structure (the DOM)
  * Logic (Javascript)
  * Links to other pages.

  A Scene has:

  * Structure (graphs),
  * Logic (event handlers and filters)
  * Transitions to other scenes. Well... it can request the [`ViewPort`](overview_viewport.html)
  to go to a different scene.

  Your application is a collection of scenes that are in use at different times. There
  is only ever **one** scene showing in a [`ViewPort`](overview_viewport.html) at a given
  time. However, scenes can instantiate components, effectively embedding their graphs
  inside the main one. More on that below.


  ### [Graphs](Scenic.Graph.html)

  Each scene should maintain at least one graph. You can build graphs
  at compile time, or dynamically while your scene is running. Building
  them at compile time has two advantages

    1. Performance: It is clearly faster to build the graph once during
    build time than to build it repeatedly during runtime.
    2. Error checking: If your graph has an error in it, it is much
    better to have it stop compilation than cause an error during runtime.

  Example of building a graph during compile time:

      @graph Scenic.Graph.build(font_size: 24)
        |> button({"Press Me", :button_id}, translate: {20, 20})

  Rather than having a single scene maintain a massive graph of UI,
  graphs can reference graphs in other scenes.

  On a typical screen of UI, there is one scene
  that is the root. Each control, is its own scene process with
  its own state. These child scenes can in turn contain other
  child scenes. This allows for strong code reuse, isolates knowledge
  and logic to just the pieces that need it, and keeps the size of any
  given graph to a reasonable size. For example, the
  handlers of a check-box scene don't need to know anything about
  how a slider works, even though they are both used in the same
  parent scene. At best, they only need to know that they
  both conform to the `Component.Input` behavior, and can thus
  query or set each others value. Though it is usually
  the parent scene that does that.

  The application developer is responsible for building and
  maintaining the scene's graph. It only enters the world of the
  `ViewPort` when you call `push_graph`. Once you have called
  `push_graph`, that graph is sent to the drivers and is out of your
  immediate control. You update that graph by calling `push_graph`
  again.


  ## Scene Structure

  The overall structure of a scene has several parts. It is a `GenServer`, which means you
  have an input function and can implement the GenServer callbacks such as
  `handle_info/2`, `handle_cast/2`, `handle_call/3` and any others. The terms
  you return from those callbacks is pretty much what you expect with the requirement that
  the state is always a scene structure.

  The `init/3` callback takes 3 parameters. They are the scene structure (state), params that
  the parent scene set up, and opts, which includes things like the id, theme, and some styles
  that were set on the scene.

  There are several additional callbacks that your scene can support. The main ones are
  `handle_input/2`, and `handle_event/3`. If you are making a Component (a reusable scene), then
  there are additional callbacks that allow it to play nicely with others.


  ## Scene Example

  This example shows a simple scene that contains a button. When the button is clicked, the
  scene increments a counter and displays the number of clicks it has received.

  ```elixir
  defmodule MySimpleScene do
    use Scenic.Scene

    alias Scenic.Graph
    import Scenic.Primitives
    import Scenic.Components

    @initial_count  0

    # This graph is built at compile time so it doesn't do any work at runtime.
    # It could also be built in the init function (or any other) if you want
    # it to be dynamic based on the params or whatever.
    @graph Graph.build()
        |> group( fn graph ->
          graph
          |> text( "Count: " <> inspect(@initial_count), id: :count )
          |> button( "Click Me", id: :btn, translate: {0, 30} )
        end,
        translate: {100, 100}
      )

    # Simple function to return @graph.
    # @graph is built at compile time and stored directly in the BEAM file every
    # time it is used. A simple accessor function will cause it to be stored only once.
    # Do this when you build graphs at compile time to save space in your file.
    defp graph(), do: @graph

    # The Scenic.Scene init function
    @impl Scenic.Scene
    def init(scene, _params, _opts) do
      scene =
        scene
        |> assign( count: @initial_count )
        |> push_graph( graph() )
      {:ok, scene}
    end

    @impl Scenic.Scene
    def handle_event( {:click, :btn}, _, %{assigns: %{count: count}} = scene ) do
      count = count + 1

      # modify the graph to show the current click count
      graph =
        graph()
        |> Graph.modify( :count, &text(&1, "Count: " <> inspect(count)) )

      # update the count and push the modified graph
      scene =
        scene
        |> assign( count: count )
        |> push_graph( graph )

      # return the updated scene
      { :noreply, scene }
    end

  end
  ```

  ## Scene State

  Scenes are just a specialized form of `GenServer`. This means they can react to messages
  and can have state. However, scene state is a bit like socket state in `Phoenix` in that
  It has a strict format, but you can add anything you want into its `:assigns` map.


  #### Multiple Graphs

  Any given scene can maintain multiple graphs and multiple draw scripts.
  They are identified from each other with an id that you attach.

  Normally when you use push_graph, you don't attach an ID. In that case
  the scene's id is used as the graph id.

  The act of pushing a graph to the ViewPort causes it to be compiled into
  a script, which is stored in an ETS table so that the drivers can quickly
  access it. To use a second, or third, graph that you scene has pushed, refer
  to it using a `Scenic.Primitive.Script` primitive.


  ```elixir
  def init( scene, param, opts ) do
    second_graph = Scenic.Graph.build()
      |> text( "Text in the second graph" )

    main_graph = Scenic.Graph.build()
      |> script( "my_fancy_id" )

    scene =
      scene
      |> push_graph( main_graph )
      |> push_graph( second_graph, "my_fancy_id" )

    { :ok, scene }
  end
  ```

  Note that it doesn't matter which graph you push first. They will link to each other
  via the string id that you supply.


  ### Communications

  Scenes are specialized GenServers. As such, they communicate with each other
  (and the rest of your application) through messages. You can receive
  messages with the standard `handle_info`, `handle_cast`, `handle_call` callbacks just
  like any other scene.

  Scenes have two new event handling callbacks that you can *optionally* implement. These
  are about user input vs UI events.


  ## Input vs. Events

  Input is data generated by the drivers and sent up to the scenes
  through `Scenic.ViewPort`. There is a limited set of input types and
  they are standardized so that the drivers can be built independently
  of the scenes. Input follows certain rules about which scene receives them.

  Events are messages that one scene generates for consumption
  by other scenes. For example, a `Scenic.Component.Button` scene would
  generate a `{:click, msg}` event that is sent to its parent
  scene.

  You can generate any message you want, however, the standard
  component libraries follow certain patterns to keep things sensible.

  ## Input Handling

  You handle incoming input events by adding `c:handle_input/3` callback
  functions to your scene. Each `c:handle_input/3` call passes in the input
  message itself, an input context struct, and your scene's state. You can then
  take the appropriate actions, including generating events (below) in response.

  Under normal operation, input that is not position dependent
  (keys, window events, more...) is sent to the root scene. Input
  that does have a screen position (cursor_pos, cursor button
  presses, etc.) is sent to the scene that contains the
  graph that was hit.

  Your scene can "capture" all input of a given type so that
  it is sent to itself instead of the default scene for that type.
  this is how a text input field receives the key input. First,
  the user selects that field by clicking on it. In response
  to the cursor input, the text field captures text input (and
  maybe transforms its graph to show that it is selected).

  Captured input types should be released when no longer
  needed so that normal operation can resume.

  The input messages are passed on to a scene's parent if
  not processed.

  ## Event Filtering

  In response to input, (or anything else... a timer perhaps?),
  a scene can generate an event (any term), which is sent backwards
  up the tree of scenes that make up the current aggregate graph.

  In this way, a `Scenic.Component.Button` scene can generate a `{:click, msg}`
  event that is sent to its parent. If the parent doesn't
  handle it, it is sent to that scene's parent. And so on until the
  event reaches the root scene. If the root scene also doesn't handle
  it then the event is dropped.

  To handle events, you add `c:handle_event/3` functions to your scene.
  This function handles the event, and stops its progress backwards
  up the graph. It can handle it and allow it to continue up the
  graph. Or it can transform the event and pass the transformed
  version up the graph.

  You choose the behavior by returning either

      {:cont, msg, state}

  or

      {:halt, state}

  Parameters passed in to `c:handle_event/3` are the event itself, a
  reference to the originating scene (which you can to communicate
  back to it), and your scene's state.

  A pattern I'm using is to handle an event at the filter and stop
  its progression. It also generates and sends a new event to its
  parent. I do this instead of transforming and continuing when
  I want to change the originating scene.


  ## No children

  There is an optimization you can use. If you know for certain that your component
  will not attempt to use any components, you can set `has_children` to `false` like this.

      use Scenic.Component, has_children: false

  Setting `has_children` to `false` means the scene won't create
  a dynamic supervisor for this scene, which saves some resources and imporoves startup
  time.

  For example, the Button component sets `has_children` to `false`.
  """

  @type t :: %Scene{
          viewport: ViewPort.t(),
          pid: pid,
          module: atom,
          theme: atom | map,
          id: any,
          parent: pid,
          children: nil | map,
          child_supervisor: nil | map,
          assigns: map,
          supervisor: pid,
          stop_pid: pid
        }
  defstruct viewport: nil,
            pid: nil,
            module: nil,
            theme: nil,
            id: nil,
            parent: nil,
            children: nil,
            child_supervisor: nil,
            assigns: %{},
            supervisor: nil,
            stop_pid: nil

  @type response_opts ::
          list(
            timeout()
            | :hibernate
            | {:continue, term}
          )

  defmodule Error do
    @moduledoc false
    defexception message: nil
  end

  # ============================================================================
  # client api - working with the scene

  @doc """
  Convenience function to get an assigned value out of a scene struct.
  """
  @spec get(scene :: Scene.t(), key :: any, default :: any) :: any
  def get(%Scene{assigns: assigns}, key, default \\ nil) do
    Map.get(assigns, key, default)
  end

  @doc """
  Convenience function to fetch an assigned value out of a scene struct.
  """
  @spec fetch(scene :: Scene.t(), key :: any) :: {:ok, any} | :error
  def fetch(%Scene{assigns: assigns}, key) do
    Map.fetch(assigns, key)
  end

  @doc """
  Convenience function to assign a list of values into a scene struct.
  """
  @spec assign(scene :: Scene.t(), key_list :: Keyword.t()) :: Scene.t()
  def assign(%Scene{} = scene, key_list) when is_list(key_list) do
    Enum.reduce(key_list, scene, fn {k, v}, acc -> assign(acc, k, v) end)
  end

  @doc """
  Convenience function to assign a value into a scene struct.
  """
  @spec assign(scene :: Scene.t(), key :: any, value :: any) :: Scene.t()
  def assign(%Scene{assigns: assigns} = scene, key, value) do
    %{scene | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Convenience function to assign a list of new values into a scene struct.

  Only values that do not already exist will be assigned
  """
  @spec assign_new(scene :: Scene.t(), key_list :: Keyword.t()) :: Scene.t()
  def assign_new(%Scene{} = scene, key_list) when is_list(key_list) do
    Enum.reduce(key_list, scene, fn {k, v}, acc -> assign_new(acc, k, v) end)
  end

  @doc """
  Convenience function to assign a new values into a scene struct.

  The value will only be assigned if it does not already exist in the struct.
  """
  @spec assign_new(scene :: Scene.t(), key :: any, value :: any) :: Scene.t()
  def assign_new(%Scene{assigns: assigns} = scene, key, value) do
    %{scene | assigns: Map.put_new(assigns, key, value)}
  end

  @doc """
  Get the `pid` of the scene's parent.
  """
  @spec parent(scene :: Scene.t()) :: {:ok, parent :: pid}
  def parent(%Scene{parent: parent}), do: {:ok, parent}

  @doc """
  Get a list of `{id, pid}` pairs for all the scene's children.
  """
  @spec children(scene :: Scene.t()) ::
          {:ok, [{id :: any, child_pid :: pid}]}
          | {:error, :no_children}
  def children(%Scene{children: nil}), do: {:error, :no_children}

  def children(%Scene{children: children}) do
    {:ok, Enum.map(children, fn {_, {_, pid, id, _param}} -> {id, pid} end)}
  end

  @doc """
  Get the `pid` of the child with the specified id.

  You can specify the same ID to more than one child. This is why the
  return is a list.
  """
  @spec child(scene :: Scene.t(), id :: any) ::
          {:ok, [child_pid :: pid]} | {:error, :no_children}
  def child(%Scene{children: nil}, _), do: {:error, :no_children}

  def child(%Scene{children: children}, id) do
    {
      :ok,
      children
      |> Enum.reduce([], fn
        {_, {_, pid, ^id, _param}}, acc -> [pid | acc]
        _, acc -> acc
      end)
    }
  end

  @doc """
  Get the "value" of the child with the specified id.

  This function is intended to be used to query the current value of a component.
  The component must have implemented the `c:Scenic.Scene.handle_get/2` callback.
  All of the built-in components support this.

  For example, you could use this to query the current value of a checkbox.

  You can specify the same ID to more than one child. This is why the
  return is a list.
  """
  @spec get_child(scene :: Scene.t(), id :: any) ::
          {:ok, [child_pid :: pid]} | {:error, :no_children}
  def get_child(%Scene{children: nil}, _), do: {:error, :no_children}

  def get_child(scene, id) do
    case child(scene, id) do
      {:ok, pids} -> Enum.map(pids, &GenServer.call(&1, :_get_))
      err -> err
    end
  end

  @doc """
  Put the "value" of the child with the specified id.

  This function is intended to be used to change the current value of a component.
  The component must have implemented the `c:Scenic.Scene.handle_put/2` callback.
  All of the built-in components support this.

  For example, you could use this to change the current value of a checkbox.
  In this case, the returned value would be `true` or `false`.

  You can specify the same ID to more than one child. This will cause all the
  components with that id to receive the handle_put call.
  """
  @spec put_child(scene :: Scene.t(), id :: any, value :: any) ::
          :ok | {:error, :no_children}
  def put_child(scene, id, value)
  def put_child(%Scene{children: nil}, _id, _val), do: {:error, :no_children}

  def put_child(%Scene{} = scene, id, value) do
    case child(scene, id) do
      {:ok, pids} ->
        Enum.each(pids, &send(&1, {:_put_, value}))
        :ok

      err ->
        err
    end
  end

  @doc """
  Fetch the "data" of the child with the specified id.

  This function is intended to be used to query the current data of a component.
  The component must have implemented the `c:Scenic.Scene.handle_fetch/2` callback.
  All of the built-in components support this.

  Unlike `get_child`, `fetch_child` returns the full data associated with
  component, not just the current value. For example a checkbox component
  might fetch the value `{"My Checkbox", true}`

  You can specify the same ID to more than one child. This is why the
  return is a list.
  """
  @spec fetch_child(scene :: Scene.t(), id :: any) ::
          {:ok, [child_pid :: pid]} | {:error, :no_children}
  def fetch_child(%Scene{children: nil}, _), do: {:error, :no_children}

  def fetch_child(scene, id) do
    case child(scene, id) do
      {:ok, pids} ->
        {
          :ok,
          Enum.map(pids, fn pid ->
            case GenServer.call(pid, :_fetch_) do
              {:ok, value} -> value
              _ -> :error
            end
          end)
        }

      err ->
        err
    end
  end

  @doc """
  Update the "data" of the child with the specified id.

  This function is intended to be used to update the current data of a component.
  The component must have implemented the `c:Scenic.Scene.handle_update/3` callback.
  All of the built-in components support this.

  Unlike `put_child`, `update_child` effectively re-initializes the component with the
  new data. This would be the same data format you have provided when you created the
  component in the first place. For example, you might update a checkbox component
  with the value `{"New Label", true}`

  You can specify the same ID to more than one child. This will cause all the
  components with that id to receive the handle_put call.
  """
  @spec update_child(scene :: Scene.t(), id :: any, value :: any, opts :: Keyword.t()) ::
          Scene.t()
  def update_child(scene, id, value, opts \\ [])
  def update_child(%Scene{children: nil}, _id, _val, _opts), do: {:error, :no_children}

  def update_child(%Scene{children: children} = scene, id, new_value, new_opts) do
    children =
      children
      |> Enum.reduce(children, fn
        {name, {top, scene_pid, ^id, {mod, _old_value, old_opts}}}, kids ->
          case mod.validate(new_value) do
            {:ok, new_value} ->
              opts = Keyword.merge(old_opts, new_opts)
              new_id = opts[:id]
              send(scene_pid, {:_update_, new_value, opts})
              Map.put(kids, name, {top, scene_pid, new_id, {mod, new_value, opts}})

            _ ->
              # invalid data. log a warning
              Logger.warn(
                "Attempted to update component with invalid data. id: #{inspect(id)}, data: #{inspect(new_value)}"
              )

              kids
          end

        _, kids ->
          # not the right id. do nothing
          kids
      end)

    %{scene | children: children}
  end

  @doc """
  Get the "parent" matrix that positions this scene.

  This matrix can be used to move from scene "local" coordinates to global
  coordinates.
  """
  @spec get_transform(scene :: Scene.t()) :: Math.matrix()
  def get_transform(%Scene{viewport: %ViewPort{pid: pid}, id: id}) do
    case GenServer.call(pid, {:fetch_scene_tx, id}) do
      {:ok, tx} -> tx
      _ -> Math.Matrix.identity()
    end
  end

  @doc """
  Fetch the "parent" matrix that positions this scene.

  This matrix can be used to move from scene "local" coordinates to global
  coordinates.
  """
  @spec fetch_transform(scene :: Scene.t()) ::
          {:ok, Math.matrix()} | {:error, :not_found}
  def fetch_transform(%Scene{viewport: %ViewPort{pid: pid}, id: id}) do
    GenServer.call(pid, {:fetch_scene_tx, id})
  end

  @doc """
  Convert a point in scene local coordinates to global coordinates.
  """
  @spec local_to_global(scene :: Scene.t(), Math.point()) :: Math.point()
  def local_to_global(scene, {x, y}) do
    scene
    |> get_transform()
    |> Scenic.Math.Matrix.project_vector({x, y})
  end

  @doc """
  Convert a point in global coordinates to scene local coordinates.
  """
  @spec global_to_local(scene :: Scene.t(), Math.point()) :: Math.point()
  def global_to_local(scene, {x, y}) do
    scene
    |> get_transform()
    |> Scenic.Math.Matrix.invert()
    |> Scenic.Math.Matrix.project_vector({x, y})
  end

  @doc "Send an event message to a specific scene"
  @spec send_event(pid :: pid, event :: any) :: :ok
  def send_event(pid, event_msg) do
    Process.send(pid, {:_event, event_msg, self()}, [])
  end

  @doc "Send an event message to a scene's parent"
  @spec send_parent_event(scene :: Scene.t(), event :: any) :: :ok
  def send_parent_event(%Scene{parent: parent_pid, pid: scene_pid}, event_msg) do
    Process.send(parent_pid, {:_event, event_msg, scene_pid}, [])
  end

  @doc "Send a message to a scene's parent"
  @spec send_parent(scene :: Scene.t(), msg :: any) :: :ok
  def send_parent(%Scene{parent: pid}, msg) do
    Process.send(pid, msg, [])
  end

  @doc "Cast a message to a scene's parent"
  @spec cast_parent(scene :: Scene.t(), msg :: any) :: :ok
  def cast_parent(%Scene{parent: pid}, msg) do
    GenServer.cast(pid, msg)
  end

  @doc "Cast a message to a scene's children"
  @spec send_children(scene :: Scene.t(), msg :: any) :: :ok | {:error, :no_children}
  def send_children(%Scene{children: nil}, _msg), do: {:error, :no_children}

  def send_children(%Scene{children: kids}, msg) do
    Enum.each(kids, fn {_, {_, pid, _, _param}} -> Process.send(pid, msg, []) end)
  end

  @spec cast_children(scene :: Scene.t(), msg :: any) :: :ok | {:error, :no_children}
  def cast_children(%Scene{children: nil}, _msg), do: {:error, :no_children}

  def cast_children(%Scene{children: kids}, msg) do
    Enum.each(kids, fn {_, {_, pid, _, _param}} -> GenServer.cast(pid, msg) end)
  end

  @doc "Cleanly stop a scene from running"
  @spec stop(scene :: Scene.t()) :: :ok
  def stop(%Scene{supervisor: supervisor, stop_pid: stop_pid}) do
    DynamicSupervisor.terminate_child(supervisor, stop_pid)
  end

  # --------------------------------------------------------
  @doc """
  Request one or more types of input that a scene would otherwise not
  receive if not captured. This is rarely used by scenes and even then
  mostly for things like key events outside of a text field.

  Any input types that were previously requested that are no longer in the
  request list are dropped. Request [] to cancel all input requests.

  returns :ok or an error

  This is intended be called by a Scene process, but doesn't need to be.
  """
  @spec request_input(
          scene :: Scene.t(),
          input_class :: ViewPort.Input.class() | [ViewPort.Input.class()]
        ) :: :ok | {:error, atom}
  def request_input(scene, input_class)
  def request_input(scene, input) when is_atom(input), do: request_input(scene, [input])

  def request_input(%Scene{viewport: vp, pid: pid}, inputs) when is_list(inputs) do
    ViewPort.Input.request(vp, inputs, pid: pid)
  end

  # --------------------------------------------------------
  @doc """
  release all currently requested input.

  This is intended be called by a Scene process, but doesn't need to be.
  """
  @spec unrequest_input(
          scene :: Scene.t(),
          input_class :: ViewPort.Input.class() | [ViewPort.Input.class()] | :all
        ) :: :ok | {:error, atom}
  def unrequest_input(scene, input_class \\ :all)

  def unrequest_input(%Scene{viewport: vp, pid: pid}, input_class) do
    ViewPort.Input.unrequest(vp, input_class, pid: pid)
  end

  # --------------------------------------------------------
  @doc """
  Fetch a list of input requested by the given scene.

  This is intended be called by a Scene process, but doesn't need to be.
  """
  @spec fetch_requests(scene :: Scene.t()) :: {:ok, [ViewPort.Input.class()]} | {:error, atom}
  def fetch_requests(scene)

  def fetch_requests(%Scene{viewport: vp, pid: pid}) do
    ViewPort.Input.fetch_requests(vp, pid)
  end

  # --------------------------------------------------------
  @doc """
  Request one or more types of input that a scene would otherwise not
  receive if not captured. This is rarely used by scenes and even then
  mostly for things like key events outside of a text field.

  Any input types that were previously requested that are no longer in the
  request list are dropped. Request [] to cancel all input requests.

  returns :ok or an error

  This is intended be called by a Scene process, but doesn't need to be.
  """
  @spec capture_input(
          scene :: Scene.t(),
          input_class :: ViewPort.Input.class() | [ViewPort.Input.class()]
        ) :: :ok | {:error, atom}
  def capture_input(scene, input_class)
  def capture_input(scene, input) when is_atom(input), do: capture_input(scene, [input])

  def capture_input(%Scene{viewport: vp, pid: pid}, inputs) when is_list(inputs) do
    ViewPort.Input.capture(vp, inputs, pid: pid)
  end

  # --------------------------------------------------------
  @doc """
  release all currently requested input.

  This is intended be called by a Scene process, but doesn't need to be.
  """
  @spec release_input(
          scene :: Scene.t(),
          input_class :: ViewPort.Input.class() | [ViewPort.Input.class()] | :all
        ) :: :ok | {:error, atom}
  def release_input(scene, input_class \\ :all)

  def release_input(%Scene{viewport: vp, pid: pid}, input_class) do
    ViewPort.Input.release(vp, input_class, pid: pid)
  end

  # --------------------------------------------------------
  @doc """
  Fetch a list of input captured by the given scene.

  This is intended be called by a Scene process, but doesn't need to be.
  """
  @spec fetch_captures(scene :: Scene.t()) :: {:ok, [ViewPort.Input.class()]} | {:error, atom}
  def fetch_captures(scene)

  def fetch_captures(%Scene{viewport: vp, pid: pid}) do
    ViewPort.Input.fetch_captures(vp, pid)
  end

  # --------------------------------------------------------
  @doc "Push a named script to the scene's ViewPort."
  @spec push_script(
          scene :: Scene.t(),
          script :: Scenic.Script.t(),
          name :: String.t(),
          opts :: Keyword.t()
        ) :: Scene.t()
  def push_script(%Scene{viewport: vp} = scene, script, name, opts \\ [])
      when is_bitstring(name) do
    ViewPort.put_script(vp, name, script, opts)
    scene
  end

  # --------------------------------------------------------
  @doc """
  Push a graph to the scene's ViewPort.

  This function compiles a graph into a script, registers any requested inputs and stores
  it all in the ViewPort's ETS tables.

  Any components that are created or removed from the scene are
  started/stopped/updated as appropriate.
  """
  @spec push_graph(scene :: Scene.t(), graph :: Graph.t(), name :: String.t() | nil) :: Scene.t()
  def push_graph(scene, graph, id \\ nil)

  def push_graph(%Scene{id: id} = scene, %Graph{} = graph, nil) do
    push_graph(scene, graph, id)
  end

  def push_graph(
        %Scene{
          viewport: viewport,
          theme: theme,
          children: children
        } = scene,
        %Graph{} = graph,
        id
      )
      when is_bitstring(id) do
    # if the graph does not have a theme set at the root, then
    # set the default theme for this scene automatically
    graph =
      case graph.primitives[0].styles[:theme] do
        nil ->
          Graph.modify(graph, :_root_, &Primitive.merge_opts(&1, theme: theme))

        _ ->
          graph
      end

    # put the graph to the ViewPort
    ViewPort.put_graph(viewport, id, graph)

    # manage the child components
    case children do
      nil -> scene
      %{} -> %{scene | children: manage_children(graph, id, scene)}
    end
  end

  # manage the components running on a scene
  # meant to be called internally
  @doc false
  defp manage_children(
         %Graph{} = graph,
         graph_name,
         %Scene{
           viewport: viewport,
           children: children,
           child_supervisor: child_supervisor
         }
       ) do
    # scan the graph and extract a list of component data
    components =
      Graph.reduce(graph, [], fn
        %{module: Primitive.Component, data: {mod, param, name}, opts: opts} = p, acc ->
          # special case theme. Is the only style that inherits down to components
          # this is tricky as it could, in turn be inherited by a parent
          opts =
            case find_theme(graph, p) do
              {:ok, theme} -> Keyword.put(opts, :theme, theme)
              _ -> opts
            end
            |> Keyword.put(:id, Map.get(p, :id))

          [{name, {mod, param}, Map.get(p, :id), opts} | acc]

        _, acc ->
          acc
      end)

    # the currently running children could have come from multiple graphs.
    # extract the ones that relate to this graph.
    running_children = Enum.filter(children, fn {{gname, _}, _} -> gname == graph_name end)

    # find the components that are not already running
    start_children =
      Enum.reject(components, fn {sn, _, _, _} ->
        Enum.any?(running_children, fn {{_, rn}, _} -> rn == sn end)
      end)

    # find components that are running, but are no longer in the graph
    stop_children =
      Enum.reject(running_children, fn {{_, rn}, _} ->
        Enum.any?(components, fn {sn, _, _, _} -> rn == sn end)
      end)

    modify_children =
      Enum.reduce(running_children, [], fn {{rg, rn}, {_, _, _, {mod, rp, ro}}}, acc ->
        Enum.find_value(components, fn
          # no change
          {^rn, {_, ^rp}, _id, ^ro} -> :no_change
          # yes change
          {^rn, {^mod, cp}, _id, co} -> {:changed, {{rg, rn}, {mod, cp, co}}}
          # not relevant
          _ -> nil
        end)
        |> case do
          nil -> acc
          :no_change -> acc
          {:changed, data} -> [data | acc]
        end
      end)

    # modify the components that are dirty
    children =
      Enum.reduce(modify_children, children, fn {key, {mod, param, opts}}, acc ->
        id =
          case Keyword.fetch(opts, :id) do
            {:ok, id} -> id
            _ -> nil
          end

        {:ok, {top_pid, scene_pid, _, _}} = Map.fetch(acc, key)
        send(scene_pid, {:_update_, param, opts})
        Map.put(acc, key, {top_pid, scene_pid, id, {mod, param, opts}})
      end)

    # start the components that need to be started
    children =
      Enum.reduce(start_children, children, fn {name, {mod, param}, id, opts}, acc ->
        opts =
          opts
          |> Component.filter_opts()

        opts =
          case id do
            nil -> opts
            id -> Keyword.put(opts, :id, id)
          end

        {:ok, top, scene} =
          Scene.start(
            name: name,
            module: mod,
            parent: self(),
            param: param,
            viewport: viewport,
            root_sup: child_supervisor,
            opts: opts
          )

        Map.put(acc, {graph_name, name}, {top, scene, id, {mod, param, opts}})
      end)

    # stop the components that need to be stopped
    # returns the updated children
    Enum.reduce(stop_children, children, fn {key, {pid, _, _, _}}, acc ->
      DynamicSupervisor.terminate_child(child_supervisor, pid)
      Map.delete(acc, key)
    end)
  end

  # ============================================================================
  # callback definitions

  @doc """
  Invoked when the `Scene` receives input from a driver.

  Input is messages sent directly from a driver, usually based on some action by the user.
  This is opposed to "events", which are generated by other scenes.

  When input arrives at a scene, you can consume it, or pass it along to the scene above
  you in the ViewPort's supervision structure.

  To consume the input and have processing stop afterward, return either a `{:halt, ...}` or
  `{:noreply, ...}` value. They are effectively the same thing.

  To allow the scene's parent to process the input, return `{:cont, input, state, ...}`. Note
  that you can pass along the input unchanged or transform it in the process if you wish.

  The callback supports all the return values of the
  [`init`](https://hexdocs.pm/elixir/GenServer.html#c:handle_cast/2)
  callback in [`Genserver`](https://hexdocs.pm/elixir/GenServer.html).

  In addition to the normal return values defined by GenServer, a `Scene` can
  add an optional `{push: graph}` term, which pushes the graph to the viewport.

  This has replaced push_graph() as the preferred way to push a graph.
  """
  @callback handle_input(input :: Scenic.ViewPort.Input.t(), id :: any, scene :: Scene.t()) ::
              {:noreply, scene}
              | {:noreply, scene}
              | {:noreply, scene, timeout}
              | {:noreply, scene, :hibernate}
              | {:noreply, scene, opts :: response_opts()}
              | {:halt, scene}
              | {:halt, scene, timeout}
              | {:halt, scene, :hibernate}
              | {:halt, scene, opts :: response_opts()}
              | {:cont, input, scene}
              | {:cont, input, scene, timeout}
              | {:cont, input, scene, :hibernate}
              | {:cont, input, scene, opts :: response_opts()}
              | {:stop, reason, scene}
            when scene: Scene.t(), reason: term, input: term

  @doc """
  Invoked when the `Scene` receives an event from another scene.

  Events are messages generated by a scene, that are passed backwards up the ViewPort's
  scene supervision tree. This is opposed to "input", which comes directly from the drivers.

  When an event arrives at a scene, you can consume it, or pass it along to the scene above
  you in the ViewPort's supervision structure.

  To consume the input and have processing stop afterward, return either a `{:halt, ...}` or
  `{:noreply, ...}` value. They are effectively the same thing.

  To allow the scene's parent to process the input, return `{:cont, event, state, ...}`. Note
  that you can pass along the event unchanged or transform it in the process if you wish.

  The callback supports all the return values of the
  [`init`](https://hexdocs.pm/elixir/GenServer.html#c:handle_cast/2)
  callback in [`Genserver`](https://hexdocs.pm/elixir/GenServer.html).

  In addition to the normal return values defined by GenServer, a `Scene` can
  add an optional `{push: graph}` term, which pushes the graph to the viewport.

  This has replaced push_graph() as the preferred way to push a graph.
  """
  @callback handle_event(event :: term, from :: pid, scene :: Scene.t()) ::
              {:noreply, scene}
              | {:noreply, scene}
              | {:noreply, scene, timeout}
              | {:noreply, scene, :hibernate}
              | {:noreply, scene, opts :: response_opts()}
              | {:halt, scene}
              | {:halt, scene, timeout}
              | {:halt, scene, :hibernate}
              | {:halt, scene, opts :: response_opts()}
              | {:cont, event, scene}
              | {:cont, event, scene, timeout}
              | {:cont, event, scene, :hibernate}
              | {:cont, event, scene, opts :: response_opts()}
              | {:stop, reason, scene}
            when scene: Scene.t(), reason: term, event: term

  @doc """
  Invoked when the `Scene` is started.

  `args` is the argument term you passed in via config or ViewPort.set_root.

  `options` is a list of information giving you context about the environment
  the scene is running in. If an option is not in the list, then it should be
  treated as nil.
    * `:viewport` - This is the pid of the ViewPort that is managing this dynamic scene.
      It will be not set, or nil, if you are managing the Scene in a static
      supervisor yourself.
    * `:styles` - This is the map of styles that your scene can choose to inherit
      (or not) from its parent scene. This is typically used by a child control that
      wants to visually fit into its parent's look.
    * `:id` - This is the :id term that the parent set a component when it was invoked.

  The callback supports all the return values of the
  [`init`](https://hexdocs.pm/elixir/GenServer.html#c:init/1)
  callback in [`Genserver`](https://hexdocs.pm/elixir/GenServer.html).

  In addition to the normal return values defined by GenServer, a `Scene` can
  return two new ones that push a graph to the viewport

  Returning `{:ok, state, push: graph}` will push the indicated graph
  to the ViewPort. This is preferable to the old push_graph() function.
  """

  @callback init(scene :: Scene.t(), args :: term(), options :: Keyword.t()) ::
              {:ok, scene}
              | {:ok, scene, timeout :: non_neg_integer}
              | {:ok, scene, :hibernate}
              | {:ok, scene, opts :: response_opts()}
              | :ignore
              | {:stop, reason}
            when scene: Scene.t(), reason: term()

  @doc """
  Get the current \"value\" associated with the scene and return it to the caller.

  If this callback is not implemented, the caller with receive nil.
  """
  @callback handle_get(from :: GenServer.from(), scene :: Scene.t()) ::
              {:reply, reply, scene}
              | {:reply, reply, scene, timeout() | :hibernate | {:continue, term()}}
            when reply: term(), scene: Scene.t()

  @doc """
  Put the current \"value\" associated with the scene .

  Does nothing if this callback is not implemented.
  """
  @callback handle_put(value :: any, scene :: Scene.t()) ::
              {:noreply, scene}
              | {:noreply, scene, timeout() | :hibernate | {:continue, term()}}
            when scene: Scene.t()

  @doc """
  Retrieve the current data associated with the scene and return it to the caller.

  If this callback is not implemented, the caller with get an {:error, :not_implemented}.
  """
  @callback handle_fetch(from :: GenServer.from(), scene :: Scene.t()) ::
              {:reply, reply, scene}
              | {:reply, reply, scene, timeout() | :hibernate | {:continue, term()}}
            when reply: term(), scene: Scene.t()

  @doc """
  Update the data and options of a scene. Usually implemented by Components.

  If this callback is not implemented, then changes to the component in the parent's
  graph will have no affect.
  """
  @callback handle_update(data :: any, opts :: Keyword.t(), scene :: Scene.t()) ::
              {:noreply, scene}
              | {:noreply, scene, timeout() | :hibernate | {:continue, term()}}
            when scene: Scene.t()

  @optional_callbacks handle_event: 3,
                      handle_input: 3,
                      handle_get: 2,
                      handle_put: 2,
                      handle_fetch: 2,
                      handle_update: 3

  # ============================================================================
  # using macro

  # ===========================================================================
  # the using macro for scenes adopting this behavior
  defmacro __using__(using_opts \\ []) do
    quote do
      use GenServer
      @behaviour Scenic.Scene

      import Scenic.Scene,
        only: [
          get: 2,
          get: 3,
          fetch: 2,
          assign: 2,
          assign: 3,
          assign_new: 2,
          assign_new: 3,
          parent: 1,
          children: 1,
          child: 2,
          get_child: 2,
          put_child: 3,
          fetch_child: 2,
          update_child: 3,
          update_child: 4,
          get_transform: 1,
          fetch_transform: 1,
          local_to_global: 2,
          global_to_local: 2,
          send_event: 2,
          send_parent_event: 2,
          send_parent: 2,
          cast_parent: 2,
          send_children: 2,
          cast_children: 2,
          stop: 1,
          request_input: 2,
          unrequest_input: 1,
          unrequest_input: 2,
          fetch_requests: 1,
          capture_input: 2,
          release_input: 1,
          release_input: 2,
          fetch_captures: 1,
          push_script: 3,
          push_script: 4,
          push_graph: 2,
          push_graph: 3
        ]

      if Module.defines?(__MODULE__, {:filter_event, 3}) do
        raise """
        #{__MODULE__} defines filter_event/3, which is now deprecated.

        It should replaced with handle_event/3, with the same parameters.

        This is more consistent with other Elixir packages.
        """
      end

      def _has_children?() do
        unquote(
          case using_opts[:has_children] do
            false -> false
            _ -> true
          end
        )
      end

      @doc false
      def init(_param), do: :ignore

      # quote
    end

    # defmacro
  end

  # ===========================================================================
  # calls for setting up a scene inside of a supervisor

  #  def child_spec({ref, scene_module}), do:
  #    child_spec({ref, scene_module, nil})

  @doc false
  def child_spec(opts) do
    # if function_exported?(scene_module, :child_spec, 1) do
    #   scene_module.child_spec({args, opts})
    # else
    %{
      id: make_ref(),
      start: {__MODULE__, :start_link, opts},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }

    # end
  end

  # ============================================================================
  # internal server api
  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  # --------------------------------------------------------
  @doc false
  def init(opts) do
    vp = opts[:viewport]

    GenServer.cast(
      vp.pid,
      {:register_scene, self(), opts[:name], opts[:parent], opts[:module]}
    )

    {:ok, nil, {:continue, {:_init, opts}}}
  end

  # ============================================================================
  # terminate

  def terminate(reason, %Scene{module: module} = scene) do
    case Kernel.function_exported?(module, :terminate, 2) do
      true -> module.terminate(reason, scene)
      false -> nil
    end
  end

  def terminate(reason, _other), do: reason

  # ============================================================================
  # handle_continue

  # --------------------------------------------------------
  def handle_continue({:_init, opts}, nil) do
    module = opts[:module]
    has_children = module._has_children?()
    viewport = opts[:viewport]
    param = opts[:param]
    id = opts[:name]

    theme =
      with {:ok, st} <- Keyword.fetch(opts, :opts),
           {:ok, theme} <- Keyword.fetch(st, :theme) do
        theme
      else
        err -> raise "Theme not set on scene. Should not happen. #{inspect(err)}"
      end

    # set up the state that is always set
    scene = %Scene{
      viewport: viewport,
      parent: opts[:parent],
      pid: self(),
      module: module,
      theme: theme,
      id: id,
      supervisor: opts[:root_sup],
      stop_pid: opts[:stop_pid] || self()
    }

    # if this scene as children, find the child supervisor
    scene =
      case has_children do
        true ->
          [_, {_, child_sup, :supervisor, [DynamicSupervisor]}] =
            opts[:supervisor]
            |> Supervisor.which_children()

          %{scene | children: %{}, child_supervisor: child_sup}

        false ->
          scene
      end

    # start up the scene
    case module.init(scene, param, opts[:opts] || []) do
      {:ok, %Scene{} = state} ->
        GenServer.cast(viewport.pid, {:scene_complete, id})
        {:noreply, state}

      {:ok, _other} ->
        raise "Invalid response from #{module}.init/3 State must be a %Scene{}"

      {:ok, %Scene{} = state, opt} ->
        GenServer.cast(viewport.pid, {:scene_complete, id})
        {:noreply, state, opt}

      {:ok, _other, _opt} ->
        raise "Invalid response from #{module}.init/3 State must be a %Scene{}"

      :ignore ->
        :ignore

      {:stop, reason} ->
        {:stop, reason}
    end
  end

  # --------------------------------------------------------
  # generic handle_continue. give the scene a chance to handle it
  @doc false
  def handle_continue(msg, %Scene{module: module} = scene) do
    case module.handle_continue(msg, scene) do
      {:noreply, %Scene{} = scene} -> {:noreply, scene}
      {:noreply, %Scene{} = scene, opts} -> {:noreply, scene, opts}
      response -> response
    end
  end

  # ============================================================================
  # handle_info

  # --------------------------------------------------------
  def handle_info(
        {:_input, input, raw_input, id},
        %Scene{module: module, viewport: %{pid: vp_pid}} = scene
      ) do
    case Kernel.function_exported?(module, :handle_input, 3) do
      true ->
        case module.handle_input(input, id, scene) do
          {:noreply, %Scene{} = scene} ->
            {:noreply, scene}

          {:noreply, %Scene{} = scene, opts} ->
            {:noreply, scene, opts}

          {:halt, %Scene{} = scene} ->
            {:noreply, scene}

          {:halt, %Scene{} = scene, opts} ->
            {:noreply, scene, opts}

          {:cont, scene} ->
            GenServer.cast(vp_pid, {:continue_input, raw_input})
            {:noreply, scene}

          {:cont, scene, opts} ->
            GenServer.cast(vp_pid, {:continue_input, raw_input})
            {:noreply, scene, opts}

          response ->
            response
        end

      false ->
        {:noreply, scene}
    end
  end

  # --------------------------------------------------------
  def handle_info({:_event, event, from}, %Scene{module: module, parent: parent} = scene) do
    case Kernel.function_exported?(module, :handle_event, 3) do
      true ->
        case module.handle_event(event, from, scene) do
          {:noreply, %Scene{} = scene} ->
            {:noreply, scene}

          {:noreply, %Scene{} = scene, opts} ->
            {:noreply, scene, opts}

          {:halt, %Scene{} = scene} ->
            {:noreply, scene}

          {:halt, %Scene{} = scene, opts} ->
            {:noreply, scene, opts}

          {:cont, event, %Scene{parent: parent} = scene} ->
            Process.send(parent, {:_event, event, from}, [])
            {:noreply, scene}

          {:cont, event, %Scene{parent: parent} = scene, opts} ->
            Process.send(parent, {:_event, event, from}, [])
            {:noreply, scene, opts}

          response ->
            response
        end

      false ->
        Process.send(parent, {:_event, event, from}, [])
        {:noreply, scene}
    end
  end

  def handle_info({:_put_, param}, %Scene{module: module} = scene) do
    case Kernel.function_exported?(module, :handle_put, 2) do
      true ->
        case module.handle_put(param, scene) do
          {:ok, %Scene{} = scene} -> {:noreply, scene}
          {:noreply, %Scene{} = scene} -> {:noreply, scene}
          {:noreply, %Scene{} = scene, opts} -> {:noreply, scene, opts}
        end

      false ->
        {:noreply, scene}
    end
  end

  def handle_info({:_update_, param, opts}, %Scene{module: module} = scene) do
    case Kernel.function_exported?(module, :handle_update, 3) do
      true ->
        case module.handle_update(param, opts, scene) do
          {:ok, %Scene{} = scene} -> {:noreply, scene}
          {:noreply, %Scene{} = scene} -> {:noreply, scene}
          {:noreply, %Scene{} = scene, opts} -> {:noreply, scene, opts}
        end

      false ->
        # the default behaviour is to call the scene's init function
        {:ok, scene} = module.init(scene, param, opts)
        {:noreply, scene}
    end
  end

  # --------------------------------------------------------
  # generic handle_info. give the scene a chance to handle it
  @doc false
  def handle_info(msg, %Scene{module: module} = scene) do
    case module.handle_info(msg, scene) do
      {:noreply, %Scene{} = scene} -> {:noreply, scene}
      {:noreply, %Scene{} = scene, opts} -> {:noreply, scene, opts}
      response -> response
    end
  end

  # ============================================================================
  # handle_call

  # --------------------------------------------------------
  # A way to test for alive?, but also to force synchronization
  def handle_call(:_ping_, _from, %Scene{} = scene) do
    {:reply, :_pong_, scene}
  end

  def handle_call(:_get_, from, %Scene{module: module} = scene) do
    case Kernel.function_exported?(module, :handle_get, 2) do
      true -> module.handle_get(from, scene)
      false -> {:reply, nil, scene}
    end
  end

  def handle_call(:_fetch_, from, %Scene{module: module} = scene) do
    case Kernel.function_exported?(module, :handle_fetch, 2) do
      true -> module.handle_fetch(from, scene)
      false -> {:reply, {:error, :not_implemented}, scene}
    end
  end

  # --------------------------------------------------------
  # generic handle_call. give the scene a chance to handle it
  def handle_call(msg, from, %Scene{module: module} = scene) do
    case module.handle_call(msg, from, scene) do
      {:noreply, %Scene{} = scene} -> {:noreply, scene}
      {:noreply, %Scene{} = scene, opts} -> {:noreply, scene, opts}
      {:reply, reply, %Scene{} = scene} -> {:reply, reply, scene}
      {:reply, reply, %Scene{} = scene, opts} -> {:reply, reply, scene, opts}
      response -> response
    end
  end

  # ============================================================================
  # handle_cast

  @doc false

  # --------------------------------------------------------
  # generic handle_cast. give the scene a chance to handle it
  def handle_cast(msg, %Scene{module: module} = scene) do
    case module.handle_cast(msg, scene) do
      {:noreply, %Scene{} = scene} -> {:noreply, scene}
      {:noreply, %Scene{} = scene, opts} -> {:noreply, scene, opts}
      response -> response
    end
  end

  # ============================================================================
  # Scene management

  @start_schema [
    name: [required: true, type: :any],
    module: [required: true, type: :atom],
    parent: [required: true, type: :pid],
    viewport: [required: true, type: {:custom, Validators, :validate_vp, [:viewport]}],
    root_sup: [required: true, type: :pid],
    stop_pid: [type: :pid],
    param: [type: :any, default: nil],
    child_supervisor: [type: {:or, [:pid, :atom]}, default: nil],
    opts: [type: :keyword_list, default: []]
  ]

  # --------------------------------------------------------
  # this a root-level dynamic scene
  @doc false
  def start(opts) do
    opts = Enum.into(opts, [])

    root_sup = opts[:root_sup]

    # make invalid opts really obvious by crashing
    opts =
      case NimbleOptions.validate(opts, @start_schema) do
        {:ok, opts} -> opts
        {:error, error} -> raise Exception.message(error)
      end

    # signal the VP that the scene is starting up
    vp = opts[:viewport]
    GenServer.cast(vp.pid, {:scene_start, opts[:name]})

    module = opts[:module]

    try do
      module._has_children?()
    rescue
      UndefinedFunctionError ->
        raise "Attempted to start uncompiled scene: #{inspect(module)}"
    end
    # start a supervisor - or not - depending on if there are children
    |> case do
      # has children. Start intermediate fixed supervisor
      true ->
        {:ok, sup} = DynamicSupervisor.start_child(root_sup, {Scene.Supervisor, [opts]})
        # find the pid of the actual scene and return it with the direct supervisor
        pid =
          sup
          |> Supervisor.which_children()
          |> Enum.find_value(fn
            {_, pid, :worker, [Scene]} -> pid
            _ -> false
          end)

        # the immediate child is the new supervisor, the pid is the scene
        {:ok, sup, pid}

      # no children, start it directly
      false ->
        {:ok, pid} = DynamicSupervisor.start_child(root_sup, {Scene, [opts]})
        # there is no supervisor, so pid and child are the same thing
        {:ok, pid, pid}
    end
  end

  defp find_theme(_g, %Primitive{styles: %{theme: theme}}), do: {:ok, theme}
  defp find_theme(_, %Primitive{parent_uid: -1}), do: {:error, :not_found}

  defp find_theme(g, %Primitive{parent_uid: p_uid}) do
    # try the parent
    find_theme(g, g.primitives[p_uid])
  end
end
