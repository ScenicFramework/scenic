#
#  Created by Boyd Multerer on 2018-04-07.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# Taking the learnings from several previous versions.

defmodule Scenic.ViewPort do
  use GenServer
  alias Scenic.Math
  alias Scenic.ViewPort
  alias Scenic.Primitive
  alias Scenic.ViewPort.Context

  @moduledoc """

  ## Overview

  The job of the `ViewPort` is to coordinate the flow of information between
  the scenes and the drivers. Scene's and Drivers should not know anything
  about each other. An app should work identically from its point of view
  no matter if there is one, multiple, or no drivers currently running.

  Drivers are all about rendering output and collecting input from a single
  source. Usually hardware, but can also be the network or files. Drivers
  only care about graphs and should not need to know anything about the
  logic or state encapsulated in Scenes.

  The goal is to isolate app data & logic from render data & logic. The
  ViewPort is the choke point between them that makes sense of the flow
  of information.

  ## OUTPUT

  Practically speaking, the `ViewPort` is the owner of the ETS tables that
  carry the graphs (and any other necessary support info). If the VP
  crashes, then all that information needs to be rebuilt. The VP monitors
  all running scenes and does the appropriate cleanup when any of them
  goes DOWN.

  The scene is responsible for generating graphs and writing them to
  the graph ETS table. (Also tried casting the graph to the ViewPort
  so that the table could be non-public, but that had issues)

  The drivers should only read from the graph tables.

  ## INPUT

  When user input happens, the drivers send it to the `ViewPort`.
  Input that does not depend on screen position (key presses, audio
  window events, etc...) Are sent to the root scene unless some other
  scene has captured that type of input (see captured input) below.

  If the input event does depend on position (cursor position, cursor
  button presses, scrolling, etc...) then the ViewPort needs to
  scan the hierarchical graph of graphs, to find the correct
  scene, and the item in that scene that was "hit". The ViewPort
  then sends the event to that scene, with the position projected
  into the scene's local coordinate space (via the built-up stack
  of matrix transformations)

  ## CAPTURED INPUT

  A scene can request to "capture" all input events of a certain type.
  this means that all events of that type are sent to a certain
  scene process regardless of position or root. In this way, a
  text input scene nested deep in the tree can capture key presses.
  Or a button can capture cursor_pos events after it has been pressed.

  if a scene has "captured" a position dependent input type, that
  position is projected into the scene's coordinate space before
  sending the event. Note that instead of walking the graph of graphs,
  the transforms provided in the input "context" field are used. You
  could, in theory change that to something else before capturing,
  but I wouldn't really recommend it.

  Any scene can cancel the current capture. This would probably
  leave the scene that thinks it has "captured" the input in a
  weird state, so I wouldn't recommend it.

  """

  @viewports :scenic_dyn_viewports

  # @type input ::
  # {:codepoint, {codepoint :: integer, mods :: integer}} |
  # {:key, {key :: String.t, :press | :release, mods :: integer}} |
  # {:cursor_button, {:left | :center | :right, :press | :release, mods :: integer, position :: Math.point}} |
  # {:cursor_scroll, {offset :: Math.point, position :: Math.point}} |
  # {:cursor_pos, position :: Math.point} |
  # {:viewport_enter, position :: Math.point} |
  # {:viewport_exit, position :: Math.point}

  @type event :: {event :: atom, data :: any}

  # ============================================================================
  # client api

  # --------------------------------------------------------
  @doc """
  Start a new viewport
  """
  @spec start(config :: map) :: {:ok, pid}
  def start(%ViewPort.Config{} = config) do
    # start the viewport's supervision tree
    {:ok, sup_pid} =
      DynamicSupervisor.start_child(
        @viewports,
        {ViewPort.Supervisor, config}
      )

    # we want to return the pid of the viewport itself
    viewport_pid =
      sup_pid
      |> Supervisor.which_children()
      |> Enum.find_value(fn
        {_, pid, :worker, [ViewPort]} -> pid
        _ -> false
      end)

    # return the pid to the viewport itself
    {:ok, viewport_pid}
  end

  def start(%{} = config) do
    start(struct(ViewPort.Config, config))
  end

  # --------------------------------------------------------
  @doc """
  Stop a running viewport
  """
  @spec stop(viewport :: GenServer.server()) :: :ok
  def stop(viewport)

  def stop(viewport) when is_atom(viewport) and not is_nil(viewport) do
    Process.whereis(viewport) |> stop()
  end

  def stop(viewport) when is_pid(viewport) do
    # dynamic viewports are actually supervised by their own supervisor.
    # so first we have to get that, which is what we actually stop
    [supervisor_pid | _] =
      viewport
      |> Process.info()
      |> get_in([:dictionary, :"$ancestors"])

    DynamicSupervisor.terminate_child(@viewports, supervisor_pid)
  end

  # --------------------------------------------------------
  @doc """
  query the last recorded viewport status
  """
  @spec info(viewport :: GenServer.server()) :: {:ok, ViewPort.Status.t()}
  def info(viewport)

  def info(viewport) when is_atom(viewport) or is_pid(viewport) do
    GenServer.call(viewport, :query_info)
  end

  # --------------------------------------------------------
  @doc """
  Set a the root scene/graph of the ViewPort.
  """
  @spec set_root(
          viewport :: GenServer.server(),
          scene :: atom | {atom, any},
          args :: any
        ) :: :ok
  def set_root(viewport, scene, args \\ nil)

  def set_root(viewport, scene, args)
      when (is_pid(viewport) or is_atom(viewport)) and is_atom(scene) do
    GenServer.cast(viewport, {:set_root, scene, args})
  end

  def set_root(viewport, {mod, init_data}, args)
      when (is_pid(viewport) or is_atom(viewport)) and is_atom(mod) do
    GenServer.cast(viewport, {:set_root, {mod, init_data}, args})
  end

  # --------------------------------------------------------
  @doc """
  Request that a `{:set_root, ...}` message is sent to the caller.

  `request_root` is primarily used by drivers and is of little use to anything
  else.

  When a driver starts up, it will need to get the root scene of the viewport,
  which may already be up and running. By calling `request_root`, the driver
  can request that the viewport send it a `{:set_root, ...}` message as if
  the root scene had just changed.

  ### Params:

  * `viewport` The viewport to request the message from.
  * `send_to` The driver to send the message to. If `send_to` is nil, the message
  will be sent to the calling process.
  """

  @spec request_root(
          viewport :: GenServer.server(),
          send_to :: nil | GenServer.server()
        ) :: :ok
  def request_root(viewport, send_to \\ nil)

  def request_root(viewport, nil) do
    request_root(viewport, self())
  end

  def request_root(viewport, to)
      when (is_pid(viewport) or is_atom(viewport)) and (is_pid(to) or is_atom(to)) do
    GenServer.cast(viewport, {:request_root, to})
  end

  # --------------------------------------------------------
  @spec input(
          viewport :: GenServer.server(),
          input :: ViewPort.Input.t()
        ) :: :ok
  def input(viewport, input_event) do
    GenServer.cast(viewport, {:input, input_event})
  end

  @spec input(
          viewport :: GenServer.server(),
          input :: ViewPort.Input.t(),
          context :: Context.t()
        ) :: :ok
  def input(viewport, input_event, context) do
    GenServer.cast(viewport, {:input, input_event, context})
  end

  # --------------------------------------------------------
  @spec reshape(viewport :: GenServer.server(), size :: Math.point()) :: :ok
  def reshape(viewport, size) do
    GenServer.cast(viewport, {:reshape, size})
  end

  # --------------------------------------------------------
  @doc """
  Capture one or more types of input.

  This must be called by a Scene process.
  """

  @spec capture_input(
          context :: Context.t(),
          input_class :: ViewPort.Input.class() | list(ViewPort.Input.class())
        ) :: :ok
  def capture_input(context, input_types)

  def capture_input(context, input_type) when is_atom(input_type) do
    capture_input(context, [input_type])
  end

  def capture_input(%Context{viewport: pid} = context, input_types)
      when is_list(input_types) do
    GenServer.cast(pid, {:capture_input, context, input_types})
  end

  # --------------------------------------------------------
  @doc """
  release an input capture.

  This is intended be called by a Scene process, but doesn't need to be.
  """
  def release_input(context_or_viewport, input_types)

  def release_input(%Context{viewport: pid}, input_types) do
    release_input(pid, input_types)
  end

  def release_input(vp, types) when (is_pid(vp) or is_atom(vp)) and is_list(types) do
    GenServer.cast(vp, {:release_input, types})
  end

  def release_input(vp, input_type) when not is_list(input_type),
    do: release_input(vp, [input_type])

  # --------------------------------------------------------
  @doc """
  Cast a message to all active drivers listening to a viewport.
  """
  def driver_cast(viewport, msg) do
    GenServer.cast(viewport, {:driver_cast, msg})
  end

  # ============================================================================
  # internal server api
  @doc false
  def child_spec(args) do
    %{
      id: make_ref(),
      start: {__MODULE__, :start_link, [args]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  # --------------------------------------------------------
  @doc false
  def start_link({_, config} = args) do
    case config.name do
      nil -> GenServer.start_link(__MODULE__, args)
      name -> GenServer.start_link(__MODULE__, args, name: name)
    end
  end

  # --------------------------------------------------------
  @doc false
  def init({vp_sup, config}) do
    GenServer.cast(self(), {:delayed_init, vp_sup, config})
    {:ok, nil}
  end

  # ============================================================================
  # handle_info

  # when a scene goes down, clean it up
  #  def handle_info({:DOWN, _monitor_ref, :process, pid, reason}, state) do
  #    {:noreply, state}
  #  end

  # ============================================================================
  # handle_call

  # --------------------------------------------------------
  def handle_call(
        {:start_driver, config},
        _,
        %{
          supervisor: vp_supervisor,
          dynamic_supervisor: dyn_sup,
          size: size
        } = state
      ) do
    {
      :reply,
      DynamicSupervisor.start_child(
        dyn_sup,
        {Scenic.ViewPort.Driver, {vp_supervisor, size, config}}
      ),
      state
    }
  end

  # --------------------------------------------------------
  # query the status of the viewport
  def handle_call(
        :query_info,
        _,
        %{
          driver_registry: driver_registry,
          root_config: root_config,
          root_scene_pid: root_scene_pid,
          root_graph_key: root_graph_key,
          size: size,
          master_styles: styles,
          master_transforms: transforms
        } = state
      ) do
    status = %ViewPort.Status{
      root_scene_pid: root_scene_pid,
      root_config: root_config,
      root_graph: root_graph_key,
      drivers: driver_registry,
      size: size,
      styles: styles,
      transforms: transforms
    }

    {:reply, {:ok, status}, state}
  end

  # ============================================================================
  # handle_cast

  def handle_cast({:delayed_init, vp_supervisor, config}, _) do
    # find the viewport and associated pids this driver belongs to
    dyn_sup_pid =
      vp_supervisor
      |> Supervisor.which_children()
      |> Enum.find_value(fn
        {DynamicSupervisor, pid, :supervisor, [DynamicSupervisor]} -> pid
        _ -> false
      end)

    # get the on_close flag or function
    on_close =
      case config.on_close do
        nil ->
          :stop_system

        :stop_system ->
          :stop_system

        :stop_viewport ->
          :stop_viewport
          # func when is_function(func, 1) -> func
      end

    # extract the viewport global styles. Do this by reusing tools in Primitive.
    p =
      Primitive.merge_opts(
        %Primitive{module: Primitive.Group},
        Map.get(config, :opts, [])
      )
      |> Primitive.minimal()

    styles = Map.get(p, :styles, %{})
    transforms = Map.get(p, :transforms, %{})

    # build the master graph, which will act as the real root graph
    # this gives us something to hang global transforms off of.
    # the master graph starts in the minimal primitive-only form
    master_graph_key = {:graph, make_ref(), nil}

    master_graph = %{
      0 => %{data: {Primitive.Group, [1]}, transforms: transforms},
      1 => %{data: {Primitive.SceneRef, nil}}
    }

    # set up the initial state
    state = %{
      size: config.size,
      root_graph_key: nil,
      root_scene_pid: nil,
      dynamic_root_pid: nil,
      root_config: nil,
      input_captures: %{},
      hover_primitve: nil,
      drivers: [],
      driver_registry: %{},
      supervisor: vp_supervisor,
      dynamic_supervisor: dyn_sup_pid,
      max_depth: config.max_depth,
      on_close: on_close,
      master_styles: styles,
      master_transforms: transforms,
      master_graph: master_graph,
      master_graph_key: master_graph_key
    }

    # set the initial scene as the root
    case config.default_scene do
      nil ->
        :ok

      scene ->
        GenServer.cast(
          self(),
          {:set_root, scene, config.default_scene_activation}
        )
    end

    {:noreply, state}
  end

  # --------------------------------------------------------
  # def handle_cast( {:init_pids, sup_pid, ds_pid}, state ) do
  #   {:noreply, %{state | immediate_supervisor: sup_pid, dynamic_supervisor: ds_pid}}
  # end

  # --------------------------------------------------------
  def handle_cast(
        {:set_root, scene, args},
        %{
          dynamic_root_pid: old_dynamic_root_scene,
          dynamic_supervisor: dyn_sup,
          master_styles: styles,
          master_graph: master_graph,
          master_graph_key: master_graph_key
        } = state
      ) do
    # prep state, which is mostly about resetting input
    state =
      state
      |> Map.put(:hover_primitve, nil)
      |> Map.put(:input_captures, %{})

    # fetch the dynamic supervisor
    # dyn_sup =
    #   case dyn_sup do
    #     nil -> find_dyn_supervisor()
    #     dyn_sup -> dyn_sup
    #   end

    # if the scene being set is dynamic, start it up
    {scene_pid, scene_ref, dynamic_scene} =
      case scene do
        # dynamic scene
        {mod, init_data} ->
          # start the dynamic scene
          {:ok, pid, ref} =
            mod.start_dynamic_scene(
              dyn_sup,
              nil,
              init_data,
              vp_dynamic_root: self(),
              viewport: self(),
              styles: styles
            )

          {pid, ref, pid}

        # app supervised scene - mark dynamic root as nil
        scene when is_atom(scene) ->
          {scene, scene, nil}
      end

    graph_key = {:graph, scene_ref, nil}

    # update the master graph
    master_graph = put_in(master_graph, [1, :data], {Primitive.SceneRef, graph_key})
    # insert the updated master graph
    ViewPort.Tables.insert_graph(
      master_graph_key,
      self(),
      master_graph,
      %{1 => graph_key}
    )

    # tell the drivers about the new root
    driver_cast(self(), {:set_root, master_graph_key})

    # clean up the old root graph. Can be done async so long as
    # terminating the dynamic scene (if set) is after deactivation
    Task.start(fn ->
      if old_dynamic_root_scene do
        GenServer.cast(old_dynamic_root_scene, {:stop, dyn_sup})
      end
    end)

    state =
      state
      |> Map.put(:root_graph_key, graph_key)
      |> Map.put(:root_scene_pid, scene_pid)
      |> Map.put(:dynamic_root_pid, dynamic_scene)
      |> Map.put(:root_config, {scene, args})
      |> Map.put(:master_graph, master_graph)

    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_cast(
        {:dyn_root_up, scene_ref, scene_pid},
        %{
          root_graph_key: {:graph, root_scene_ref, _}
        } = state
      )
      when root_scene_ref == scene_ref do
    {:noreply, %{state | root_scene_pid: scene_pid, dynamic_root_pid: scene_pid}}
  end

  def handle_cast({:dyn_root_up, _, _}, state) do
    # ignore stale root_up messages
    {:noreply, state}
  end

  # ==================================================================
  # casts about drivers

  # --------------------------------------------------------
  def handle_cast(
        {:stop_driver, driver_pid},
        %{
          drivers: drivers,
          dynamic_supervisor: dyn_sup,
          driver_registry: registry
        } = state
      ) do
    DynamicSupervisor.terminate_child(dyn_sup, driver_pid)
    drivers = Enum.reject(drivers, fn pid -> pid == driver_pid end)
    registry = Map.delete(registry, driver_pid)
    {:noreply, %{state | drivers: drivers, driver_registry: registry}}
  end

  # --------------------------------------------------------
  def handle_cast({:driver_cast, msg}, %{drivers: drivers} = state) do
    # relay the graph_key to all listening drivers
    Enum.each(drivers, &GenServer.cast(&1, msg))
    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_cast(
        {:driver_ready, driver_pid},
        %{
          drivers: drivers,
          master_graph_key: master_graph_key
        } = state
      ) do
    drivers = [driver_pid | drivers] |> Enum.uniq()
    GenServer.cast(driver_pid, {:set_root, master_graph_key})
    {:noreply, %{state | drivers: drivers}}
  end

  # --------------------------------------------------------
  # def handle_cast(
  #       {:driver_stopped, driver_pid},
  #       %{
  #         drivers: drivers,
  #         driver_registry: registry
  #       } = state
  #     ) do
  #   drivers = Enum.reject(drivers, fn d -> d == driver_pid end)
  #   registry = Map.delete(registry, driver_pid)
  #   {:noreply, %{state | drivers: drivers, driver_registry: registry}}
  # end

  # --------------------------------------------------------
  # def handle_cast({:request_root, to_pid}, %{root_graph_key: root_key} = state) do
  def handle_cast({:request_root, to_pid}, %{master_graph_key: master_key} = state) do
    GenServer.cast(to_pid, {:set_root, master_key})
    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_cast({:driver_register, %ViewPort.Driver.Info{pid: pid} = driver}, state) do
    {:noreply, put_in(state, [:driver_registry, pid], driver)}
  end

  # --------------------------------------------------------
  def handle_cast(:user_close, %{on_close: on_close, supervisor: vp_sup} = state) do
    case on_close do
      :stop_viewport ->
        DynamicSupervisor.terminate_child(@viewports, vp_sup)

      #   :ok -> :ok
      #   {:error, :not_found} -> Process.exit(vp_sup, :shutdown)
      # end

      # func when is_function(func, 1) ->
      #   func.(self())

      :stop_system ->
        System.stop(0)
    end

    {:noreply, state}
  end

  # --------------------------------------------------------
  # def handle_cast(:user_close, state) do
  #   case DynamicSupervisor.terminate_child(@viewports, self()) do
  #     :ok ->
  #       :ok

  #     {:error, :not_found} ->
  #       # Process.exit(self(), :normal)
  #       # exit(:shutdown)
  #       System.stop(0)
  #   end

  #   {:noreply, state}
  # end

  # ==================================================================
  # management casts from scenes

  # --------------------------------------------------------
  # ignore input until a scene has been set
  def handle_cast(msg, state) do
    ViewPort.Input.handle_cast(msg, state)
  end

  # ============================================================================
  # internal utilities

  # defp do_driver_cast(driver_pids, msg) do
  #   Enum.each(driver_pids, &GenServer.cast(&1, msg))
  # end

  # defp find_dyn_supervisor() do
  #   # get the scene supervisors
  #   [supervisor_pid | _] =
  #     self()
  #     |> Process.info()
  #     |> get_in([:dictionary, :"$ancestors"])

  #   # make sure it is a pid and not a name
  #   supervisor_pid =
  #     case supervisor_pid do
  #       name when is_atom(name) -> Process.whereis(name)
  #       pid when is_pid(pid) -> pid
  #     end

  #   case Process.info(supervisor_pid) do
  #     nil ->
  #       nil

  #     info ->
  #       case get_in(info, [:dictionary, :"$initial_call"]) do
  #         {:supervisor, Scenic.ViewPort.Supervisor, _} ->
  #           Supervisor.which_children(supervisor_pid)
  #           # credo:disable-for-next-line Credo.Check.Refactor.Nesting
  #           |> Enum.find_value(fn
  #             {DynamicSupervisor, pid, :supervisor, [DynamicSupervisor]} -> pid
  #             _other -> nil
  #           end)

  #         _other ->
  #           nil
  #       end
  #   end
  # end
end
