#
#  Created by Boyd Multerer on 2021-02-06
#  Heavily updated from the previous version
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#
# Taking the learnings from several previous versions.

defmodule Scenic.ViewPort do
  use GenServer

  alias Scenic.Script
  alias Scenic.ViewPort
  alias Scenic.Driver
  alias Scenic.Math
  alias Scenic.Scene
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Graph.Compiler, as: GraphCompiler

  # alias Scenic.Utilities
  alias Scenic.Utilities.Validators
  alias Scenic.Primitive.Style.Theme

  require Logger

  # import IEx

  @moduledoc """

  ## Overview

  The job of the `ViewPort` is to coordinate the flow of information between
  the scenes and the drivers. Scenes and Drivers should not know anything
  about each other. An app should work identically from its point of view
  no matter if there is one, multiple, or no drivers currently running.

  Drivers are all about rendering output and collecting input from a single
  source. Usually hardware, but can also be the network or files. Drivers
  only care about graphs and should not need to know anything about the
  logic or state encapsulated in Scenes.

  The goal is to isolate app data and logic from render data and logic. The
  ViewPort is the connection between them that makes sense of the flow
  of information.

  ## OUTPUT

  Practically speaking, the `ViewPort` is the owner of the ETS tables that
  carry the graphs (and any other necessary support info). If the ViewPort
  crashes, then all that information needs to be rebuilt. The ViewPort monitors
  all running scenes and does the appropriate cleanup when any of them
  goes DOWN.

  The scene is responsible for generating graphs and writing them to
  the graph ETS table. (**Note:** We also tried casting the graph to the ViewPort
  so that the table could be non-public, but that had issues)

  The drivers should only read from the graph tables.

  ## INPUT

  When user input happens, the drivers send it to the `ViewPort`.
  Input that does not depend on screen position (key presses, audio
  window events, etc.) is sent to the root scene unless some other
  scene has captured that type of input (see captured input below).

  If the input event does depend on position (cursor position, cursor
  button presses, scrolling, etc.) then the ViewPort needs to
  scan the hierarchical graph of graphs, to find the correct
  scene, and the item in that scene that was "hit". The ViewPort
  then sends the event to that scene, with the position projected
  into the scene's local coordinate space (via the built-up stack
  of matrix transformations)

  ## CAPTURED INPUT

  A scene can request to "capture" all input events of a certain type.
  This means that all events of that type are sent to a certain
  scene process regardless of position or root. In this way, a
  text input scene nested deep in the tree can capture key presses.
  Or a button can capture cursor_pos events after it has been pressed.

  If a scene has "captured" a position dependent input type, that
  position is projected into the scene's coordinate space before
  sending the event. Note that instead of walking the graph of graphs,
  the transforms provided in the input "context" field are used. You
  could, in theory change that to something else before capturing,
  but I wouldn't really recommend it.

  Any scene can cancel the current capture. This would probably
  leave the scene that thinks it has "captured" the input in an inconsistent
  state, so this is not recommended.

  """

  @type t :: %ViewPort{
          name: atom,
          pid: pid,
          # name_table: reference,
          script_table: reference,
          size: {number, number}
        }
  defstruct name: nil,
            pid: nil,
            # name_table: nil,
            script_table: nil,
            size: nil

  @viewports :scenic_viewports

  @type event :: {event :: atom, data :: any}

  @opts_schema [
    name: [type: :atom],
    title: [type: :string],
    size: [required: true, type: {:custom, Validators, :validate_wh, [:size]}],
    default_scene: [
      required: true,
      type: {:custom, Validators, :validate_scene, [:default_scene]}
    ],
    theme: [type: {:custom, Theme, :validate, []}, default: :dark],
    drivers: [type: {:custom, Driver, :validate, []}, default: []],
    input_filter: [type: {:custom, __MODULE__, :validate_input_filter, []}, default: :all],
    opts: [
      type: :keyword_list,
      keys: Scenic.Primitive.Style.opts_schema() ++ Scenic.Primitive.Transform.opts_schema()
    ]
  ]

  @main_id "_main_"
  @root_id "_root_"

  @put_scripts :_put_scripts_
  @del_scripts :_del_scripts_
  @request_input :_request_input_
  @reset_scene :_reset_scene_
  @gate_start :_gate_start_
  @gate_complete :_gate_complete_
  @clear_color :_clear_color_

  @first_open_graph_id 2

  @input_types [
    :cursor_button,
    :cursor_scroll,
    :cursor_pos,
    :codepoint,
    :key,
    :viewport
  ]

  @doc false
  def msg_put_scripts(), do: @put_scripts

  @doc false
  def msg_del_scripts(), do: @del_scripts

  @doc false
  def msg_request_input(), do: @request_input

  @doc false
  def msg_reset_scene(), do: @reset_scene

  @doc false
  def msg_gate_start(), do: @gate_start

  @doc false
  def msg_gate_complete(), do: @gate_complete

  @doc false
  def msg_clear_color(), do: @clear_color

  @doc false
  def validate_input_filter(:all), do: {:ok, :all}

  def validate_input_filter(input) when is_list(input) do
    valid_input = input_types()

    case Enum.all?(input, &Enum.member?(valid_input, &1)) do
      true -> {:ok, input}
      false -> {:error, :invalid}
    end
  end

  @doc false
  def opts_schema(), do: @opts_schema

  @doc """
  Returns a list of the valid input types
  """
  def input_types(), do: @input_types

  @doc """
  Returns the id of the first script in the drawing tree

  Used by drivers
  """
  @spec root_id() :: String.t()
  def root_id(), do: @root_id

  @doc false
  def main_id(), do: @main_id

  # ============================================================================
  # client api

  # --------------------------------------------------------
  @doc """
  Start a new ViewPort
  """
  # the ViewPort has it's own supervision tree under the ViewPorts node
  # first create it's dynamic supervisor. Then start the ViewPort
  # process underneath, passing it's supervisor in as an parameter.
  @spec start(opts :: Keyword.t()) :: {:ok, ViewPort.t()}
  def start(opts) do
    opts = Enum.into(opts, [])

    with {:ok, opts} <- NimbleOptions.validate(opts, opts_schema()),
         {:ok, pid} <- DynamicSupervisor.start_child(@viewports, {ViewPort, opts}) do
      GenServer.call(pid, :query_info)
    else
      {:error, error} -> raise Exception.message(error)
    end
  end

  # --------------------------------------------------------
  @doc """
  Stop a running viewport
  """
  @spec stop(viewport :: ViewPort.t()) :: :ok
  def stop(%ViewPort{pid: pid}) do
    DynamicSupervisor.terminate_child(@viewports, pid)
  end

  # --------------------------------------------------------
  @doc """
  Retrieve a %ViewPort{} struct given just the viewport's pid
  """
  @spec info(pid :: ViewPort.t() | GenServer.server()) :: map
  def info(%ViewPort{pid: pid}), do: info(pid)

  def info(pid) when is_pid(pid) or is_atom(pid) do
    GenServer.call(pid, :query_info)
  end

  # --------------------------------------------------------
  @doc """
  Retrieve a script
  """
  @spec get_script(viewport :: ViewPort.t(), name :: any) ::
          {:ok, Script.t()} | {:error, :not_found}
  def get_script(%ViewPort{script_table: script_table}, name) do
    case :ets.lookup(script_table, name) do
      [{_, bin, _}] -> {:ok, bin}
      [] -> {:error, :not_found}
    end
  end

  @doc false
  defp put_x_opts_schema() do
    [owner: [type: :pid, default: self()]]
  end

  @doc """
  Put a script by name.

  returns {:ok, id}
  """
  @spec put_script(
          viewport :: ViewPort.t(),
          name :: any,
          script :: Script.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, non_neg_integer} | {:error, atom}
  def put_script(
        %ViewPort{pid: pid, script_table: script_table},
        name,
        script,
        opts \\ []
      )
      when is_list(script) do
    opts =
      opts
      |> Enum.into([])
      |> NimbleOptions.validate(put_x_opts_schema())
      |> case do
        {:ok, opts} -> opts
        {:error, error} -> raise Exception.message(error)
      end

    owner = opts[:owner]

    case :ets.lookup(script_table, name) do
      # do nothing if the script is in the table and has not changed
      [{_, ^script, ^owner}] ->
        :no_change

      # it isn't there or has changed
      _ ->
        true = :ets.insert(script_table, {name, script, owner})
        GenServer.cast(pid, {:put_scripts, [name], owner})
        {:ok, name}
    end
  end

  @doc """
  Delete a script by name.

  Also unregisters the name/id pairing
  """
  @spec del_script(viewport :: ViewPort.t(), name :: any) :: :ok | {:error, :not_found}
  def del_script(viewport, name)

  def del_script(%ViewPort{pid: pid}, name) do
    GenServer.cast(pid, {:del_script, name})
  end

  @doc """
  Retrieves a list of all registered script ids.
  """
  @spec all_script_ids(viewport :: ViewPort.t()) :: list
  def all_script_ids(%ViewPort{script_table: table}) do
    do_all_script_ids(table, :ets.first(table))
  end

  defp do_all_script_ids(table, id, ids \\ [])
  defp do_all_script_ids(_, :"$end_of_table", ids), do: ids

  defp do_all_script_ids(table, id, ids) do
    do_all_script_ids(table, :ets.next(table, id), [id | ids])
  end

  @doc """
  Put a graph by name.

  This compiles the graph to a collection of scripts
  """
  @spec put_graph(
          viewport :: ViewPort.t(),
          name :: any,
          graph :: Graph.t(),
          opts :: Keyword.t()
        ) :: {:ok, name :: any}
  def put_graph(%ViewPort{pid: pid} = viewport, name, %Graph{} = graph, opts \\ []) do
    opts =
      opts
      |> Enum.into([])
      |> NimbleOptions.validate(put_x_opts_schema())
      |> case do
        {:ok, opts} -> opts
        {:error, error} -> raise Exception.message(error)
      end

    with {:ok, script} <- GraphCompiler.compile(graph),
         {:ok, input_list} <- compile_input(graph) do
      # write the script - but only if it has actually changed
      case get_script(viewport, name) do
        {:ok, ^script} ->
          # no change
          :ok

        _ ->
          owner = opts[:owner]

          # write the script to the table
          # this notifies the drivers...
          put_script(viewport, name, script, owner: owner)

          # send the input list to the viewport
          GenServer.cast(pid, {:input_list, input_list, name, owner})
      end

      {:ok, name}
    else
      err -> err
    end
  end

  @doc """
  Delete a graph by name.

  Same as del_script/2
  """
  @spec del_graph(viewport :: ViewPort.t(), name :: any) :: :ok
  def del_graph(%ViewPort{} = viewport, name), do: del_script(viewport, name)

  # --------------------------------------------------------
  @doc """
  Set the root theme for the ViewPort.

  WARNING: this will restart the current root scene
  """
  @spec set_theme(viewport :: ViewPort.t(), theme :: atom | map) :: :ok
  def set_theme(viewport, theme)

  def set_theme(%ViewPort{pid: pid}, theme) do
    case Theme.validate(theme) do
      # {:ok, theme} -> GenServer.cast( pid, {:set_theme, theme} )
      {:ok, theme} -> GenServer.call(pid, {:set_theme, theme})
      err -> err
    end
  end

  # --------------------------------------------------------
  @doc """
  Set the root scene/graph of the ViewPort.

  This will stop the currently running scene, including all of it's child components.
  Then it starts the new scene including all of it's child components.
  """
  @spec set_root(
          viewport :: ViewPort.t(),
          scene :: atom,
          args :: any
        ) :: :ok
  def set_root(viewport, scene, args \\ nil)

  def set_root(%ViewPort{pid: pid}, scene, args) when is_atom(scene) do
    GenServer.call(pid, {:set_root, scene, args})
  end

  def set_root(_, %Scene{} = scene, _) do
    raise "You must pass the module that represents the scene you want to switch to here, not a `%Scenic.Scene{}`"
  end

  # --------------------------------------------------------
  @doc """
  Send raw input to a viewport.

  This is used primarily by drivers to send raw user input to the viewport. Having said that,
  nothing stops a scene from using it to send input into the system. There are a few cases
  where that is useful.

  See the [input docs](Scenic.ViewPort.Input.html#t:t/0) for the input formats you can send.
  """
  @spec input(
          viewport :: ViewPort.t(),
          input :: ViewPort.Input.t()
        ) :: :ok | {:error, atom}
  defdelegate input(vp, input_event), to: ViewPort.Input, as: :send

  # --------------------------------------------------------
  @doc """
  Find a scene_pid/primitive under the given point in global coordinates
  """
  @spec find_point(viewport :: ViewPort.t(), global_point :: Scenic.Math.point()) ::
          {:ok, scene_pid :: pid, id :: any} | {:error, :not_found}
  def find_point(%ViewPort{pid: pid}, global_point) do
    GenServer.call(pid, {:find_point, global_point})
  end

  @spec start_driver(
          viewport :: ViewPort.t(),
          opts :: list
        ) :: {:ok, pid :: GenServer.server()} | :error
  def start_driver(%ViewPort{pid: pid}, opts) when is_list(opts) do
    GenServer.call(pid, {:start_driver, opts})
  end

  @spec stop_driver(
          viewport :: ViewPort.t(),
          driver_pid :: GenServer.server()
        ) :: :ok
  def stop_driver(%ViewPort{pid: pid}, driver_pid) do
    GenServer.call(pid, {:stop_driver, driver_pid})
  end

  # --------------------------------------------------------
  @doc false
  def start_link(opts) do
    case opts[:name] do
      nil -> GenServer.start_link(__MODULE__, opts)
      name -> GenServer.start_link(__MODULE__, opts, name: name)
    end
  end

  # --------------------------------------------------------
  @doc false
  def init(opts) do
    # IO.inspect(self(), label: "ViewPort")

    # name_table = :ets.new( make_ref(), [:protected] )
    # script_table = :ets.new( make_ref(), [:public, {:read_concurrency, true}] )
    # name_table = :ets.new(:_vp_name_table_, [:protected])
    script_table = :ets.new(:_vp_script_table_, [:public, {:read_concurrency, true}])

    state = %{
      # simple metadata about the ViewPort
      name: opts[:name],
      size: opts[:size],
      theme: opts[:theme],

      # a list of all the pids for currently running drivers. Is used to broadcast
      # messages to drivers. Example: :put_scripts
      driver_pids: [],

      # track the running scenes. We want to quickly access by both pid and id
      scenes_by_pid: %{},
      scenes_by_id: %{},

      # References for all the processes this view port is monitoring. This is used
      # to make sure pids that need to get clean up when they go down are monitored,
      # but only monitored once.
      monitors: %{},

      # when switching to a new scene, we want to be able to signal the drivers that
      # the scene bring-up process has started, and then signal again when it has ended.
      # this allows the driver to pause refreshing the screen as cascade of new scripts
      # arrives. This is tricky tho as the ViewPort doesn't know which, how even how
      # many scenes will be created in total. This term tracks scenes as they are started
      # and as they complete. It is set to a list when the root is reset. When it goes to
      # empty, then the process is complete. If it is nil, then we are not in a reset
      starting_scenes: [],
      next_id: @first_open_graph_id,
      # ets table for scripts. Public. Readable and Writable by others. The intended
      # use is that Scenes compile graphs in their own process and insert the scripts
      # in parallel to each other. (Trying to avoid serializing the VP on large messages)
      # containing either script of graph data. The scripts can be read by multiple 
      # drivers at the same time, so is read parallel optimized. If the public write
      # becomes problematic, the next step is to have the scripts compile, then send
      # finished scripts to the VP for writing.
      script_table: script_table,

      # state related to input from drivers to scenes
      # input lists are generated when a scene pushes a graph. Primitives
      # that have input: true assigned to them end up in these lists which
      # are then used to determine what was clicked on by the user.
      input_lists: %{},
      input_positional: [],
      scene_transforms: %{},

      # input captures track when a scene has requested that it receive input
      # that it would otherwise not get under normal operation. Example, the
      # user has pressed down in a button. It is only a "click" if they also
      # release in the button. But, if they drag out of the button and then
      # release, the scene would not get that event as it isn't over an input.
      # the capture allows the scene to get that message anyway
      # input_captures: {[], nil, nil},
      _input_captures: %{},

      # input_requests is used to track which inputs are the collection of
      # all currently running scenes interested in receiving. This effectively
      # defines the normal, non-captured, input policy. The goal is to only
      # send/receive/process the minimum input that is desired. Anything more
      # is extra traffic and work that doesn't need to happen.
      # internally, this field is a map where the keys are the currently requested
      # input types and the values are a list of the scene pids requesting them.
      # this makes it very easy to filter incoming input and to know where to
      # route them, although that routing depends on the input type.
      # input_requests: %{},
      _input_requests: %{},

      # Keep track of the pid for the current root scene
      # this is used to shutdown the current scene when a new one is set
      root_pid: nil
    }

    # in case of an error starting a new root scene, we want to be able to go back to the default
    state =
      case opts[:default_scene] do
        {mod, param} ->
          state
          |> Map.put(:default_scene, mod)
          |> Map.put(:default_param, param)

        mod when is_atom(mod) ->
          state
          |> Map.put(:default_scene, mod)
          |> Map.put(:default_param, nil)
      end

    {:ok, state, {:continue, {:init, opts}}}
  end

  # --------------------------------------------------------
  @doc false
  def handle_continue({:init, opts}, state) do
    # create the supervisor for the drivers - this is expected to work
    {:ok, driver_sup} = DynamicSupervisor.start_link(strategy: :one_for_one)
    state = Map.put(state, :driver_sup, driver_sup)

    # create the supervisor for the scenes - this is expected to work
    {:ok, scene_sup} = DynamicSupervisor.start_link(strategy: :one_for_one)
    state = Map.put(state, :scene_sup, scene_sup)

    # start the drivers
    Enum.each(opts[:drivers], &do_start_driver(&1, state))

    # build the main graph. The graph itself doesn't need to be saved in state
    main_graph =
      Graph.build(opts[:opts] || [])
      # not a real component. never managed by a scene
      # this is to get input to hook up correctly to the root scene
      # needs to be a Component and NOT a Script so that it shows up in the main input list
      |> Scenic.Primitive.Component.add_to_graph({@main_id, nil, @main_id})

    # record the root transform of the main graph
    main_tx =
      main_graph.primitives[0].transforms
      |> Scenic.Primitive.Transform.combine()

    state = Map.put(state, :main_tx, main_tx || Math.Matrix.identity())

    # put the main graph. This compiles it and adds it's input list to state
    state = internal_put_graph(main_graph, @root_id, state)

    # start the default scene
    scene =
      case opts[:default_scene] do
        scene when is_atom(scene) ->
          GenServer.cast(self(), {:set_root, scene, nil})
          {scene, nil}

        {scene, param} when is_atom(scene) ->
          GenServer.cast(self(), {:set_root, scene, param})
          {scene, param}
      end

    # save the various info
    state =
      state
      |> Map.put(:main_graph, main_graph)
      |> Map.put(:scene, scene)

    {:noreply, state}
  end

  # ============================================================================
  # handle_info

  @doc false
  # when a scene or a driver goes down, clean it up
  def handle_info(
        {:DOWN, _monitor_ref, :process, pid, reason},
        %{
          driver_pids: driver_pids,
          input_lists: input_lists,
          scene_transforms: scene_transforms,
          script_table: script_table,
          scenes_by_pid: scenes_by_pid,
          scenes_by_id: scenes_by_id,
          starting_scenes: starting_scenes,
          monitors: monitors
        } = old_state
      ) do
    # cleanup scripts & names tables
    :ets.match_delete(script_table, {:_, :_, pid})

    # clean up any input requested by the pid
    state = input_pid_down(pid, old_state)

    # remove from driver list (does nothing it if isn't a driver)
    driver_pids = Enum.reject(driver_pids, &Kernel.==(&1, pid))
    state = %{state | driver_pids: driver_pids}

    # remove from tracked scenes
    state =
      case Map.fetch(scenes_by_pid, pid) do
        :error ->
          state

        {:ok, {id, _parent, mod}} ->
          # make sure the drivers are not gated on a scene that crashed.
          starting_scenes =
            case Enum.member?(starting_scenes, id) do
              false ->
                starting_scenes

              true ->
                Logger.error("""
                Scene exited or crashed before it was done initializing.
                pid: #{inspect(pid)}, reason: #{inspect(reason)}
                module: #{inspect(mod)}, id: #{inspect(id)}
                """)

                case Enum.reject(starting_scenes, &Kernel.==(&1, id)) do
                  [] ->
                    # starting_scenes has gone to an empty list. We are done.
                    # tell the drivers the reset is complete
                    cast_drivers(state, @gate_complete)
                    []

                  starting_scenes ->
                    starting_scenes
                end
            end

          # cleanup that always happens
          state =
            state
            |> Map.put(:scenes_by_pid, Map.delete(scenes_by_pid, pid))
            |> Map.put(:starting_scenes, starting_scenes)

          # make sure the id hasn't been claimed by a new scene
          # if not, clean up scenes_by_id, input lists, etc...
          case Map.fetch(scenes_by_id, id) do
            {:ok, {^pid, _}} ->
              state
              |> Map.put(:scenes_by_id, Map.delete(scenes_by_id, id))
              |> Map.put(:input_lists, Map.delete(input_lists, id))
              |> Map.put(:scene_transforms, Map.delete(scene_transforms, id))

            _ ->
              state
          end
      end
      |> update_positional_input()

    # if the requests changed, then tell the remaining drivers.
    do_update_driver_input(old_state, state)

    # clean up the monitor tracker
    state = %{state | monitors: Map.delete(monitors, pid)}

    {:noreply, state}
  end

  # quietly drop unhandled _input messages that make it to the ViewPort
  def handle_info({:_input, _, _, _}, state) do
    {:noreply, state}
  end

  # quietly unhandled drop events that make it to the ViewPort
  def handle_info({:_event, _, _}, state) do
    {:noreply, state}
  end

  def handle_info(invalid, %{name: name} = state) do
    Logger.error("""
    ViewPort #{inspect(name || self())} ignored bad info
    message: #{inspect(invalid)}
    """)

    {:noreply, state}
  end

  # ============================================================================
  # handle_cast
  @doc false
  # --------------------------
  # casts from scenes

  # a new scene has come up
  def handle_cast(
        {:register_scene, pid, id, parent_pid, mod},
        %{scenes_by_pid: sbp, scenes_by_id: sbi} = state
      ) do
    # monitor the scene
    state = ensure_monitor(pid, state)

    # get the parent's id from the parent_pid
    parent_id =
      case Map.fetch(sbp, parent_pid) do
        {:ok, {_id, parent_id, _mod}} -> parent_id
        :error -> nil
      end

    # track the scene
    sbp = Map.put(sbp, pid, {id, parent_id, mod})
    sbi = Map.put(sbi, id, {pid, parent_pid})

    {:noreply, %{state | scenes_by_pid: sbp, scenes_by_id: sbi}}
  end

  def handle_cast(
        {:input_list, {input, types}, name, caller},
        %{input_lists: lists, scene_transforms: txs} = old_state
      ) do
    input_lists = Map.put(lists, name, {input, types, caller})

    # scan the incoming input list and extract any scene transforms
    txs =
      Enum.reduce(input, txs, fn
        {Scenic.Primitive.Component, script_id, local_tx, _pid, _uid, _local_id}, acc ->
          Map.put(acc, script_id, {local_tx, name})

        _, acc ->
          acc
      end)

    new_state =
      old_state
      |> Map.put(:input_lists, input_lists)
      |> Map.put(:scene_transforms, txs)
      |> update_positional_input()

    do_update_driver_input(old_state, new_state)

    {:noreply, new_state}
  end

  def handle_cast({:put_scripts, ids, owner}, state) do
    # tell the drivers
    cast_drivers(state, {@put_scripts, ids})
    {:noreply, ensure_monitor(owner, state)}
  end

  def handle_cast(
        {:del_script, name},
        %{
          # name_table: name_table,
          script_table: script_table,
          input_lists: ils
        } = old_state
      ) do
    state =
      case :ets.lookup(script_table, name) do
        [_] ->
          cast_drivers(old_state, {@del_scripts, [name]})
          :ets.delete(script_table, name)

          # make sure the input list is cleaned up
          %{old_state | input_lists: Map.delete(ils, name)}
          |> update_positional_input()

        _ ->
          old_state
      end

    # if the requests changed, then tell the remaining drivers.
    do_update_driver_input(old_state, state)

    {:noreply, state}
  end

  # --------------------------
  # casts from drivers

  # a new driver has come up
  def handle_cast(
        {:register_driver, pid},
        %{
          driver_pids: driver_pids,
          _input_requests: reqs,
          _input_captures: capts,
          theme: theme
        } = state
      ) do
    # monitor the driver
    state = ensure_monitor(pid, state)

    # track the driver pid
    driver_pids = [pid | driver_pids]

    # send the driver the theme background as the clear_color
    # get the background from the theme
    background =
      theme
      |> Theme.normalize()
      |> Map.get(:background)

    send(pid, {@clear_color, background})

    # send the driver all the current script ids
    ids = all_script_ids(gen_info(state))
    # GenServer.cast(pid, {:put_scripts, ids})
    send(pid, {@put_scripts, ids})

    # send the driver all the current requested inputs
    input_keys =
      (Map.keys(capts) ++ Map.keys(reqs))
      |> Enum.uniq()
      |> Enum.sort()

    send(pid, {@request_input, input_keys})

    {:noreply, %{state | driver_pids: driver_pids}}
  end

  # --------------------------
  # change the main theme
  def handle_cast(
        {:set_theme, theme},
        %{scene: {scene, param}} = state
      ) do
    state = do_set_theme(theme, state)
    handle_cast({:set_root, scene, param}, state)
  end

  # --------------------------
  # start a new root scene
  def handle_cast({:set_root, scene, param}, state) do
    {:ok, state} = do_set_root(scene, param, state)
    {:noreply, state}
  end

  def handle_cast({:scene_start, scene_id}, %{starting_scenes: []} = state) do
    cast_drivers(state, @gate_start)
    {:noreply, %{state | starting_scenes: [scene_id]}}
  end

  def handle_cast({:scene_start, scene_id}, %{starting_scenes: starting_scenes} = state) do
    starting_scenes = [scene_id | starting_scenes] |> Enum.uniq()
    {:noreply, %{state | starting_scenes: starting_scenes}}
  end

  def handle_cast({:scene_complete, _}, %{starting_scenes: []} = state) do
    {:noreply, state}
  end

  def handle_cast({:scene_complete, scene_id}, %{starting_scenes: starting_scenes} = state) do
    starting_scenes =
      case Enum.reject(starting_scenes, &Kernel.==(&1, scene_id)) do
        [] ->
          # starting_scenes has gone to an empty list. We are done.
          # tell the drivers the reset is complete
          cast_drivers(state, @gate_complete)
          []

        scenes_ids ->
          scenes_ids
      end

    {:noreply, %{state | starting_scenes: starting_scenes}}
  end

  # --------------------------
  # input handlint

  def handle_cast({:input, input}, state) do
    handle_input(input, state)
  end

  def handle_cast({:continue_input, raw_input}, state) do
    handle_continue_input(raw_input, state)
  end

  def handle_cast({:_capture_input, inputs, caller}, state) do
    handle_capture(inputs, caller, state)
  end

  def handle_cast({:_release_input, inputs, caller}, state) do
    handle_release(inputs, caller, state)
  end

  def handle_cast({:_release_input!, inputs}, state) do
    handle_release!(inputs, state)
  end

  def handle_cast({:_request_input, inputs, caller}, state) do
    handle_request(inputs, caller, state)
  end

  def handle_cast({:_unrequest_input, inputs, caller}, state) do
    handle_unrequest(inputs, caller, state)
  end

  def handle_cast(invalid, %{name: name} = state) do
    Logger.error("""
    ViewPort #{inspect(name || self())} ignored bad cast
    message: #{inspect(invalid)}
    """)

    {:noreply, state}
  end

  # ============================================================================
  # handle_call
  @doc false

  # query metadata about the ViewPort
  def handle_call(:query_info, _from, state) do
    {:reply, {:ok, gen_info(state)}, state}
  end

  def handle_call(
        {:script_id, name, caller},
        _from,
        %{name_table: name_table, next_id: next_id} = state
      ) do
    case :ets.lookup(name_table, name) do
      # if the script_id exists, return the numerical id
      [{_, id, ^caller}] ->
        {:reply, {:ok, id}, state}

      # if the script_id is not there, register it
      [] ->
        :ets.insert(name_table, {name, next_id, caller})
        {:reply, {:ok, next_id}, %{state | next_id: next_id + 1}}
    end
  end

  # --------------------------------------------------------
  def handle_call({:find_point, {x, y}}, _from, %{input_lists: ils} = state)
      when is_number(x) and is_number(y) do
    hit =
      case input_find_hit(ils, :any, @root_id, {x, y}) do
        {:ok, pid, _xy, _inv_tx, id} -> {:ok, pid, id}
        _ -> {:error, :not_found}
      end

    {:reply, hit, state}
  end

  # --------------------------------------------------------
  def handle_call({:fetch_scene_tx, scene_id}, _, state) do
    {:reply, scene_tx(scene_id, state), state}
  end

  # --------------------------------------------------------
  def handle_call({:set_root, scene, param}, _from, state) do
    {:ok, state} = do_set_root(scene, param, state)
    {:reply, :ok, state}
  end

  # --------------------------------------------------------
  def handle_call(
        {:set_theme, theme},
        from,
        %{scene: {scene, param}} = state
      ) do
    state = do_set_theme(theme, state)
    # restart the current scene directly
    handle_call({:set_root, scene, param}, from, state)
  end

  # --------------------------
  # start drivers cleanly
  def handle_call({:start_driver, opts}, _from, state) do
    {:reply, do_start_driver(opts, state), state}
  end

  # --------------------------
  # stop drivers cleanly
  def handle_call(
        {:stop_driver, driver_pid},
        _from,
        %{driver_sup: driver_sup} = state
      ) do
    # drivers are monitored, so that will do the rest of the cleanup work.
    {
      :reply,
      DynamicSupervisor.terminate_child(driver_sup, driver_pid),
      state
    }
  end

  def handle_call({:_fetch_input_captures, from}, _, state) do
    handle_fetch_captures(from, state)
  end

  def handle_call(:_fetch_input_captures!, _, state) do
    handle_fetch_captures!(state)
  end

  def handle_call({:_fetch_input_requests, from}, _, state) do
    handle_fetch_requests(from, state)
  end

  def handle_call(:_fetch_input_requests!, _, state) do
    handle_fetch_requests!(state)
  end

  # --------------------------------------------------------
  # A way to test for alive?, but also to force synchronization
  def handle_call(:_ping_, _from, scene) do
    {:reply, :_pong_, scene}
  end

  def handle_call(invalid, from, %{name: name} = state) do
    Logger.error("""
    ViewPort #{inspect(name || self())} ignored bad call
    message: #{inspect(invalid)},
    from: #{inspect(from)}
    """)

    {:noreply, state}
  end

  # --------------------------------------------------------
  defp scene_tx(scene_pid, %{scenes_by_pid: sbp} = state) when is_pid(scene_pid) do
    case Map.fetch(sbp, scene_pid) do
      :error -> {:error, :not_found}
      {:ok, {id, _parent_id, _mod}} -> scene_tx(id, state)
    end
  end

  defp scene_tx(:_root_, %{main_tx: main_tx}) do
    {:ok, main_tx}
  end

  defp scene_tx(scene_id, %{scene_transforms: txs}) do
    case Map.fetch(txs, scene_id) do
      :error -> {:error, :not_found}
      {:ok, {tx, parent_id}} -> {:ok, do_scene_tx(parent_id, txs, [tx])}
    end
  end

  defp do_scene_tx(parent_id, txs, tx_list) do
    case Map.fetch(txs, parent_id) do
      {:ok, {tx, parent_id}} ->
        do_scene_tx(parent_id, txs, [tx | tx_list])

      :error ->
        # there that was the last one
        Scenic.Math.Matrix.mul(tx_list)
    end
  end

  # ==================================================================
  # do set the root

  defp do_set_root(
         scene,
         param,
         %{
           theme: theme,
           scene_sup: scene_sup,
           root_pid: old_root,
           input_lists: ils
         } = state
       ) do
    # tell the drivers to reset the scene
    cast_drivers(state, @reset_scene)

    # if there is already a root running, kill it and reset the tables
    case old_root do
      nil ->
        :ok

      pid when is_pid(pid) ->
        DynamicSupervisor.terminate_child(scene_sup, old_root)
    end

    # start the new scene
    {:ok, new_pid, _} =
      Scene.start(
        name: @main_id,
        module: scene,
        parent: self(),
        param: param,
        viewport: gen_info(state),
        root_sup: scene_sup,
        opts: [theme: theme]
      )

    # update state
    state =
      state
      |> Map.put(:root_pid, new_pid)
      |> Map.put(:scene, {scene, param})
      |> Map.put(:input_lists, %{@root_id => ils[@root_id]})
      |> Map.put(:next_id, @first_open_graph_id)

    {:ok, state}
  end

  # ============================================================================
  # internal utilities

  defp gen_info(%{
         name: name,
         # name_table: name_table,
         script_table: script_table,
         size: size
       }) do
    %ViewPort{
      pid: self(),
      name: name,
      # name_table: name_table,
      script_table: script_table,
      size: size
    }
  end

  # --------------------------
  # start drivers cleanly
  defp do_start_driver(opts, %{driver_sup: driver_sup, theme: theme} = state) do
    info = gen_info(state)

    background =
      theme
      |> Theme.normalize()
      |> Map.get(:background)

    case DynamicSupervisor.start_child(driver_sup, {Driver, {info, opts}}) do
      {:ok, pid} ->
        send(pid, {@clear_color, background})
        {:ok, pid}

      err ->
        err
    end
  end

  defp do_set_theme(theme, state) do
    # get the background from the theme
    background =
      theme
      |> Theme.normalize()
      |> Map.get(:background)

    # tell the drivers the background changed
    cast_drivers(state, {@clear_color, background})

    # update the state
    %{state | theme: theme}
  end

  defp cast_drivers(%{driver_pids: pids}, msg) do
    Enum.each(pids, &send(&1, msg))
  end

  # only called from inside the viewport
  defp internal_put_graph(
         %Graph{} = graph,
         name,
         %{input_lists: ils, script_table: script_table} = state
       ) do
    state =
      with {:ok, script} <- GraphCompiler.compile(graph),
           {:ok, {input_list, input_types}} <- compile_input(graph) do
        # write the script to the table
        case :ets.lookup(script_table, name) do
          # do nothing if the script is in the table and has not changed
          [{_, ^script, :viewport}] ->
            :no_change

          # it isn't there or has changed
          _ ->
            true = :ets.insert(script_table, {name, script, :viewport})
            :ok
        end

        # add the input list to the state
        state
        |> Map.put(:input_lists, Map.put(ils, name, {input_list, input_types, nil}))
        |> update_positional_input()
      else
        _ -> state
      end

    state
  end

  # ============================================================================
  # ============================================================================
  # ============================================================================
  # input handling

  # if the requested input changed, then tell the drivers. BUT...
  # we aren't comparing the whole map. just the keys. Did
  # the keys change? That's what triggers a driver update
  # defp do_update_driver_input( %{} = old_reqs, %{_input_requests: new_reqs} = state ) do
  defp do_update_driver_input(
         %{_input_requests: old_reqs, _input_captures: old_capts, input_positional: old_pos},
         %{_input_requests: new_reqs, _input_captures: new_capts, input_positional: new_pos} =
           state
       ) do
    old_keys =
      (Map.keys(old_capts) ++ Map.keys(old_reqs) ++ old_pos)
      |> Enum.uniq()
      |> Enum.sort()

    new_keys =
      (Map.keys(new_capts) ++ Map.keys(new_reqs) ++ new_pos)
      |> Enum.uniq()
      |> Enum.sort()

    if Enum.sort(new_keys) != Enum.sort(old_keys) do
      cast_drivers(state, {@request_input, new_keys})
    end
  end

  # --------------------------------------------------------
  defp handle_capture(inputs, caller, old_state) do
    new_state =
      Enum.reduce(inputs, old_state, fn input, %{_input_captures: capts} = st ->
        with {:ok, pids} <- Map.fetch(capts, input),
             nil <- Enum.find(pids, &Kernel.==(&1, caller)) do
          do_capture(input, caller, st)
        else
          :error -> do_capture(input, caller, st)
          _ -> st
        end
      end)

    # if the requests changed, then tell the drivers.
    do_update_driver_input(old_state, new_state)

    {:noreply, ensure_monitor(caller, new_state)}
  end

  defp do_capture(input, caller, %{_input_captures: captures} = state) do
    pids = [caller | Map.get(captures, input, [])]
    captures = Map.put(captures, input, pids)
    %{state | _input_captures: captures}
  end

  # --------------------------------------------------------
  defp handle_release([:all], caller, %{_input_captures: captures} = state) do
    captures
    |> Map.keys()
    |> handle_release(caller, state)
  end

  defp handle_release(inputs, caller, old_state) do
    new_state = Enum.reduce(inputs, old_state, &do_release(&1, caller, &2))

    # if the requests changed, then tell the drivers.
    do_update_driver_input(old_state, new_state)

    {:noreply, new_state}
  end

  defp do_release(input, caller, %{_input_captures: captures} = state) do
    case Map.fetch(captures, input) do
      :error ->
        state

      {:ok, [^caller]} ->
        captures = Map.delete(captures, input)
        %{state | _input_captures: captures}

      {:ok, pids} ->
        captures = Map.put(captures, input, List.delete(pids, caller))
        %{state | _input_captures: captures}
    end
  end

  # --------------------------------------------------------
  defp handle_release!([:all], %{_input_captures: captures} = state) do
    captures
    |> Map.keys()
    |> handle_release!(state)
  end

  defp handle_release!(inputs, old_state) do
    new_state = Enum.reduce(inputs, old_state, &do_release!(&1, &2))

    # if the requests changed, then tell the drivers.
    do_update_driver_input(old_state, new_state)

    {:noreply, new_state}
  end

  defp do_release!(input, %{_input_captures: captures} = state) do
    case Map.fetch(captures, input) do
      {:ok, _pids} ->
        captures = Map.delete(captures, input)
        %{state | _input_captures: captures}

      :error ->
        state
    end
  end

  # --------------------------------------------------------
  defp handle_fetch_captures(pid, %{_input_captures: captures} = state) do
    inputs =
      Enum.reduce(captures, [], fn {inpt, pids}, acc ->
        case Enum.member?(pids, pid) do
          true -> [inpt | acc]
          false -> acc
        end
      end)

    {:reply, {:ok, inputs}, state}
  end

  # --------------------------------------------------------
  defp handle_fetch_captures!(%{_input_captures: captures} = state) do
    {:reply, {:ok, Map.keys(captures)}, state}
  end

  # --------------------------------------------------------
  defp handle_request(inputs, caller, old_state)
       when is_list(inputs) do
    new_state = Enum.reduce(inputs, old_state, &do_request(&1, caller, &2))

    # if the requests changed, then tell the drivers.
    do_update_driver_input(old_state, new_state)

    {:noreply, ensure_monitor(caller, new_state)}
  end

  defp do_request(input, caller, %{_input_requests: requests} = state) do
    pids = [caller | Map.get(requests, input, [])] |> Enum.uniq()
    requests = Map.put(requests, input, pids)
    %{state | _input_requests: requests}
  end

  # --------------------------------------------------------
  defp handle_unrequest([:all], caller, %{_input_requests: old_reqs} = state) do
    old_reqs
    |> Map.keys()
    |> handle_unrequest(caller, state)
  end

  defp handle_unrequest(inputs, caller, old_state) do
    new_state = Enum.reduce(inputs, old_state, &do_unrequest(&1, caller, &2))

    # if the requests changed, then tell the drivers.
    do_update_driver_input(old_state, new_state)

    {:noreply, new_state}
  end

  defp do_unrequest(input, caller, %{_input_requests: requests} = state) do
    requests =
      case Map.fetch(requests, input) do
        :error -> requests
        {:ok, [^caller]} -> Map.delete(requests, input)
        {:ok, pids} -> Map.put(requests, input, List.delete(pids, caller))
      end

    %{state | _input_requests: requests}
  end

  # --------------------------------------------------------
  defp handle_fetch_requests(pid, %{_input_requests: requests} = state) do
    inputs =
      Enum.reduce(requests, [], fn {inpt, pids}, acc ->
        case Enum.member?(pids, pid) do
          true -> [inpt | acc]
          false -> acc
        end
      end)

    {:reply, {:ok, inputs}, state}
  end

  # --------------------------------------------------------
  defp handle_fetch_requests!(%{_input_requests: requests} = state) do
    {:reply, {:ok, Map.keys(requests)}, state}
  end

  # --------------------------------------------------------
  # receive input from a driver and cast it to a scene
  defp handle_input(
         {input_type, _} = input,
         %{
           _input_captures: captures,
           _input_requests: requests,
           input_positional: input_positional
         } = state
       ) do
    case Map.fetch(captures, input_type) do
      {:ok, pids} ->
        do_captured_input(input, pids, state)

      :error ->
        if Enum.member?(input_positional, input_type) do
          do_listed_input(input, state)
        end

        case Map.fetch(requests, input_type) do
          {:ok, pids} -> do_requested_input(input, pids, state)
          :error -> :ok
        end
    end

    {:noreply, state}
  end

  # --------------------------------------------------------
  # a scene decided to let others continue processing the input
  def handle_continue_input(raw_input, state) do
    handle_input(raw_input, state)
  end

  # --------------------------------------------------------
  # captured should always be sent to the capturing scene
  # in the coordinate space of that scene. Also want to indicate if it is over an
  # item in that scene. This requires several steps.
  # 1: transform the gxy into the coordinates of the scene
  # 2: find out if there it is over an item
  # 3: send the event with the local coords and the found item

  defp do_captured_input({:cursor_button, {button, action, mods, gxy}} = input, [pid | _], state) do
    # prep the gxy. Throw away the input if it doesn't succeed
    with {:ok, xy, id} <- prep_gxy_input(gxy, :any, pid, state) do
      send(pid, {:_input, {:cursor_button, {button, action, mods, xy}}, input, id})
    end
  end

  defp do_captured_input({:cursor_scroll, {delta, gxy}} = input, [pid | _], state) do
    case prep_gxy_input(gxy, :any, pid, state) do
      {:ok, xy, id} -> send(pid, {:_input, {:cursor_scroll, {delta, xy}}, input, id})
      _ -> send(pid, {:_input, {:cursor_scroll, {delta, gxy}}, input, nil})
    end
  end

  defp do_captured_input({:cursor_pos, gxy} = input, [pid | _], state) do
    case prep_gxy_input(gxy, :any, pid, state) do
      {:ok, xy, id} -> send(pid, {:_input, {:cursor_pos, xy}, input, id})
      _ -> send(pid, {:_input, {:cursor_pos, gxy}, input, nil})
    end
  end

  defp do_captured_input(input, [pid | _], _state) do
    Process.send(pid, {:_input, input, input, nil}, [])
  end

  # --------------------------------------------------------
  defp do_requested_input({:cursor_button, {button, action, mods, gxy}} = input, pids, state) do
    # send the input to each requesting pid. But... needs to be in the local
    # coord space and indicate if it was over an input
    Enum.each(pids, fn pid ->
      case prep_gxy_input(gxy, :any, pid, state) do
        {:ok, xy, id} ->
          send(pid, {:_input, {:cursor_button, {button, action, mods, xy}}, input, id})

        _ ->
          send(pid, {:_input, {:cursor_button, {button, action, mods, gxy}}, input, nil})
      end
    end)
  end

  defp do_requested_input({:cursor_scroll, {delta, gxy}} = input, pids, state) do
    # send the input to each requesting pid. But... needs to be in the local
    # coord space and indicate if it was over an input
    Enum.each(pids, fn pid ->
      case prep_gxy_input(gxy, :any, pid, state) do
        {:ok, xy, id} -> send(pid, {:_input, {:cursor_scroll, {delta, xy}}, input, id})
        _ -> send(pid, {:_input, {:cursor_scroll, {delta, gxy}}, input, nil})
      end
    end)
  end

  defp do_requested_input({:cursor_pos, gxy} = input, pids, state) do
    # send the input to each requesting pid. But... needs to be in the local
    # coord space and indicate if it was over an input
    Enum.each(pids, fn pid ->
      case prep_gxy_input(gxy, :any, pid, state) do
        {:ok, xy, id} -> send(pid, {:_input, {:cursor_pos, xy}, input, id})
        _ -> send(pid, {:_input, {:cursor_pos, gxy}, input, nil})
      end
    end)
  end

  defp do_requested_input(input, pids, _state) do
    Enum.each(pids, &Process.send(&1, {:_input, input, input, nil}, []))
  end

  # --------------------------------------------------------
  defp do_listed_input(
         {:cursor_button, {button, action, mods, gxy}} = input,
         %{input_lists: ils}
       ) do
    with {:ok, pid, xy, _inv_tx, id} <- input_find_hit(ils, :cursor_button, @root_id, gxy) do
      send(pid, {:_input, {:cursor_button, {button, action, mods, xy}}, input, id})
    end
  end

  defp do_listed_input({:cursor_scroll, {delta, gxy}} = input, %{input_lists: ils}) do
    with {:ok, pid, xy, _inv_tx, id} <- input_find_hit(ils, :cursor_scroll, @root_id, gxy) do
      send(pid, {:_input, {:cursor_scroll, {delta, xy}}, input, id})
    end
  end

  defp do_listed_input({:cursor_pos, gxy} = input, %{input_lists: ils}) do
    with {:ok, pid, xy, _inv_tx, id} <- input_find_hit(ils, :cursor_pos, @root_id, gxy) do
      send(pid, {:_input, {:cursor_pos, xy}, input, id})
    end
  end

  # --------------------------------------------------------
  defp prep_gxy_input(gxy, input_type, pid, %{input_lists: ils} = state) do
    case input_find_hit(ils, input_type, @root_id, gxy) do
      {:ok, ^pid, xy, _inv_tx, id} ->
        {:ok, xy, id}

      _ ->
        case scene_tx(pid, state) do
          {:ok, tx} ->
            scene_tx(pid, state)
            # project gxy into local coordinate space
            xy =
              tx
              |> Math.Matrix.invert()
              |> Math.Matrix.project_vector(gxy)

            {:ok, xy, nil}

          err ->
            err
        end
    end
  end

  # --------------------------------------------------------
  # a monitored pid has gone down. Clean up any input in state for it
  defp input_pid_down(pid, %{_input_captures: captures, _input_requests: requests} = state) do
    state =
      captures
      |> Map.keys()
      |> Enum.reduce(state, &do_release(&1, pid, &2))

    requests
    |> Map.keys()
    |> Enum.reduce(state, &do_unrequest(&1, pid, &2))
  end

  # --------------------------------------------------------
  defp ensure_monitor(pid, %{monitors: monitors} = state) do
    case Map.fetch(monitors, pid) do
      :error ->
        monitors = Map.put(monitors, pid, Process.monitor(pid))
        %{state | monitors: monitors}

      _ ->
        state
    end
  end

  # ============================================================================
  # ============================================================================
  # ============================================================================
  alias Scenic.Primitive.Transform

  # compile the input list for a graph

  # compile a graph into a list of input directives -> [{id,script}|...]
  # the output is already a reversed list.
  # i.e. the last thing draw, is the first thing tested
  @spec compile_input(graph :: Graph.t()) ::
          {:ok, {binary, types :: [ViewPort.Input.positional()]}}
  defp compile_input(graph)

  defp compile_input(%Graph{primitives: primitives}) do
    input = comp_input_prim([], 0, primitives[0], primitives, Math.Matrix.identity())

    # compile the requested input types
    types =
      Enum.reduce(input, [], fn {_mod, _name, _tx, _pid, types, _id}, acc ->
        [types | acc]
      end)
      |> List.flatten()
      |> Enum.uniq()

    {:ok, {input, types}}
  end

  defp comp_input_prim(input, uid, primitive, primitives, tx)

  # skip anything hidden
  defp comp_input_prim(input, _uid, %Primitive{styles: %{hidden: true}}, _, _tx), do: input

  # skip script primitives - no input handlers there
  defp comp_input_prim(input, _uid, %Primitive{module: Primitive.Script}, _, _tx), do: input

  # it is a group. Calc the local transform if there one, but doesn't go into the 
  # list as a component itself...
  defp comp_input_prim(
         input,
         _uid,
         %Primitive{module: Primitive.Group, data: ids, transforms: txs},
         primitives,
         tx
       ) do
    # calculate the graph-local transform
    local_tx = local_tx(txs, tx)
    # reduce the group
    Enum.reduce(ids, input, fn id, inpt ->
      comp_input_prim(inpt, id, primitives[id], primitives, local_tx)
    end)
  end

  # components get a call out to another input list
  defp comp_input_prim(
         input,
         _uid,
         %Primitive{module: Primitive.Component, data: {_, _, name}, transforms: txs},
         _,
         tx
       ) do
    # calculate the graph-local transform
    local_tx = local_tx(txs, tx)
    [{Primitive.Component, name, local_tx, self(), [], nil} | input]
  end

  defp comp_input_prim(
         input,
         _uid,
         %Primitive{
           id: id,
           module: module,
           data: data,
           transforms: txs,
           styles: %{input: input_types}
         },
         _,
         tx
         # ) when is_list(input_types) do
       ) do
    # calculate the graph-local transform
    local_tx = local_tx(txs, tx)
    [{module, data, local_tx, self(), input_types, id} | input]
  end

  # primitives that don't have input set are skipped
  defp comp_input_prim(input, _uid, _primitive, _, _tx), do: input

  defp local_tx(txs, tx_parent) do
    cond do
      txs == %{} ->
        # there is no local transform set
        tx_parent

      txs ->
        # multiply the local txs into the tx_parent
        Math.Matrix.mul(tx_parent, Transform.combine(txs))
    end
  end

  # coalesce the requested positional input into a single simple list
  defp update_positional_input(%{input_lists: input_lists} = state) do
    input_positional =
      input_lists
      |> Enum.reduce([], fn {_, {_, types, _}}, acc ->
        [types, acc]
      end)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()

    %{state | input_positional: input_positional}
  end

  # ============================================================================
  # walk an input list and look for hits
  @doc false
  defp input_find_hit(lists, input_type, name, global_point, parent_tx \\ nil)

  defp input_find_hit(lists, input_type, name, global_point, nil) do
    input_find_hit(lists, input_type, name, global_point, Math.Matrix.identity())
  end

  defp input_find_hit(lists, input_type, name, global_point, parent_tx) do
    case Map.fetch(lists, name) do
      {:ok, {in_list, _, _}} ->
        do_find_hit(in_list, input_type, global_point, lists, name, parent_tx)

      _ ->
        :not_found
    end
  end

  defp do_find_hit(input_list, input_type, global_point, lists, name, parent_tx)
  defp do_find_hit([], _, _, _, _, _), do: :not_found

  # components recurse
  defp do_find_hit(
         [{Primitive.Component, data, local_tx, _pid, _uid, _id} | tail],
         input_type,
         global_point,
         lists,
         name,
         parent_tx
       ) do
    # calculate the local matrix, which becomes the parent of the component
    local_tx = Math.Matrix.mul(parent_tx, local_tx)

    # recurse to test the component
    case input_find_hit(lists, input_type, data, global_point, local_tx) do
      {:ok, _, _, _, _} = hit ->
        # Rhere was a hit inside the component. Return result as we are done.
        hit

      :not_found ->
        # if not found, keep going
        do_find_hit(tail, input_type, global_point, lists, name, parent_tx)
    end
  end

  # actual thing to test against
  defp do_find_hit(
         [{module, data, local_tx, pid, types, id} | tail],
         input_type,
         {gx, gy} = gp,
         lists,
         name,
         parent_tx
       ) do
    # calculate the inverse maxtrix of parent_tx x local_tx
    local_tx = Math.Matrix.mul(parent_tx, local_tx)
    invert_tx = Math.Matrix.invert(local_tx)

    # project the global point by the inverse matrix
    {x, y} = Math.Vector2.project({gx, gy}, invert_tx)

    # for this to be a yet, it must be both a valid input type on the primitive
    # AND in the primitive itself.
    with true <- input_type == :any || Enum.member?(types, input_type),
         true <- module.contains_point?(data, {x, y}) do
      # return the xy in parent coordinate space
      inv = Math.Matrix.invert(parent_tx)
      pxy = Math.Vector2.project({gx, gy}, inv)

      {
        :ok,
        pid,
        pxy,
        inv,
        id
      }
    else
      false ->
        # No hit here. Keep going
        do_find_hit(tail, input_type, gp, lists, name, parent_tx)
    end
  end
end
