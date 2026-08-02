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

  ## Dynamically Creating View Ports

  Pass in the same set of opts that you would use when starting `Scenic` in your
  supervision tree. For example:

      # Assuming you use the default view port name from the generator
      {:ok, view_port} = Scenic.ViewPort.info(:main_viewport)

      opts = [
        module: Scenic.Driver.Local,
        window: [resizeable: false, title: "My Example Scenic App"],
        on_close: :stop_system
      ]

      {:ok, [opts]} = Scenic.Driver.validate([opts])
      Scenic.ViewPort.start_driver(view_port, opts)
  """

  @type t :: %ViewPort{
          name: atom,
          pid: pid,
          # name_table: reference,
          script_table: reference,
          semantic_table: reference,
          semantic_index: reference | nil,
          semantic_enabled: boolean(),
          scene_script_table: reference,
          size: {number, number}
        }
  defstruct name: nil,
            pid: nil,
            # name_table: nil,
            script_table: nil,
            semantic_table: nil,
            semantic_index: nil,
            semantic_enabled: false,
            scene_script_table: nil,
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
  Start a new ViewPort process.

  Creates a new ViewPort that coordinates between scenes and drivers. The ViewPort
  manages ETS tables for scripts, handles input routing, and provides the central
  coordination point for Scenic applications.

  ## Options

  - `:name` - Optional atom name to register the ViewPort process
  - `:size` - Required `{width, height}` tuple defining the viewport dimensions
  - `:default_scene` - Required scene module or `{module, args}` tuple for the root scene
  - `:theme` - Theme configuration (defaults to `:dark`)
  - `:drivers` - List of driver configurations to start automatically
  - `:input_filter` - Filter for input types (defaults to `:all`)
  - `:opts` - Additional style and transform options for the root graph

  ## Returns

  - `{:ok, %ViewPort{}}` - ViewPort struct containing process info and ETS table references
  - Raises exception on configuration errors

  ## Examples

      # Basic viewport
      {:ok, vp} = ViewPort.start([
        name: :main_viewport,
        size: {800, 600},
        default_scene: MyApp.MainScene
      ])

      # With driver and theme
      {:ok, vp} = ViewPort.start([
        size: {1024, 768},
        default_scene: {MyApp.Scene.Dashboard, %{user_id: 123}},
        theme: :light,
        drivers: [
          [module: Scenic.Driver.Local, window: [title: "My App"]]
        ]
      ])

  ## Notes

  The ViewPort creates its own supervision tree and manages scene/driver lifecycles.
  If the ViewPort crashes, all associated scenes and scripts will need to be rebuilt.
  """
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
  Retrieve a `%ViewPort{}` struct given just the viewport's pid
  """
  @spec info(pid :: ViewPort.t() | GenServer.server()) :: {:ok, map}
  def info(%ViewPort{pid: pid}), do: info(pid)

  def info(pid) when is_pid(pid) or is_atom(pid) do
    GenServer.call(pid, :query_info)
  end

  # --------------------------------------------------------
  @doc """
  Retrieve a compiled script by name from the ViewPort's ETS table.

  Scripts are the compiled, optimized rendering instructions that drivers use to
  draw graphics. This function allows drivers and debugging tools to access
  stored scripts directly.

  ## Parameters

  - `viewport` - The ViewPort struct containing the script table reference
  - `name` - The unique identifier for the script (can be any term)

  ## Returns

  - `{:ok, script}` - The compiled script as a list of drawing commands
  - `{:error, :not_found}` - If no script exists with the given name

  ## Examples

      # Retrieve a script by name
      case ViewPort.get_script(viewport, "my_button") do
        {:ok, script} ->
          # Process or inspect the script
          IO.inspect(script, label: "Button script")
        {:error, :not_found} ->
          Logger.warn("Script 'my_button' not found")
      end

  ## Notes

  This function reads directly from the ETS table without going through the
  ViewPort process, making it very fast for concurrent access by multiple drivers.
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
  Store a compiled script in the ViewPort's ETS table and notify drivers.

  This is the primary mechanism for publishing rendering instructions to drivers.
  Scripts are stored with change detection - if the same script content is
  submitted again, drivers won't be notified unnecessarily.

  ## Parameters

  - `viewport` - The ViewPort struct containing the script table reference
  - `name` - Unique identifier for the script (can be any term)
  - `script` - Compiled script as a list of drawing commands
  - `opts` - Optional configuration (see options below)

  ## Options

  - `:owner` - Process pid that owns the script (defaults to `self()`)

  ## Returns

  - `{:ok, name}` - Script successfully stored and drivers notified
  - `:no_change` - Script content unchanged, no driver notification sent
  - `{:error, atom}` - Error during script validation or storage

  ## Examples

      # Store a manually created script
      script = Script.start()
      |> Script.fill_color({255, 0, 0, 255})
      |> Script.draw_rect({100, 50})
      |> Script.finish()

      case ViewPort.put_script(viewport, "red_button", script) do
        {:ok, _} -> Logger.info("Script stored successfully")
        :no_change -> Logger.debug("Script unchanged")
      end

      # Store with custom owner (useful for cleanup tracking)
      ViewPort.put_script(viewport, "component_1", script, owner: component_pid)

  ## Notes

  - Scripts are automatically cleaned up when the owning process crashes
  - Change detection prevents unnecessary driver updates for identical scripts
  - Multiple drivers can read the same script concurrently from the ETS table
  - The function will notify all connected drivers about the script update
  """
  @spec put_script(
          viewport :: ViewPort.t(),
          name :: any,
          script :: Script.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, any} | :no_change | {:error, atom}
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
  Compile a graph into a script and store it in the ViewPort.

  This is the primary mechanism scenes use to publish their UI for rendering.
  The graph is compiled into an optimized script using `Scenic.Graph.Compiler`,
  stored in the ViewPort's ETS table, and drivers are notified to update their
  rendering. Input handling data is also extracted and registered.

  ## Parameters

  - `viewport` - The ViewPort struct containing the script table reference
  - `name` - Unique identifier for the graph/script (can be any term)
  - `graph` - The Graph struct containing primitives, styles, and transforms
  - `opts` - Optional configuration (see options below)

  ## Options

  - `:owner` - Process pid that owns the graph (defaults to `self()`)

  ## Returns

  - `{:ok, name}` - Graph successfully compiled, stored, and drivers notified
  - `{:error, reason}` - Compilation or storage error

  ## Examples

      # Basic graph publishing from a scene
      graph = Graph.build()
      |> rectangle({100, 50}, fill: :blue, translate: {10, 20})
      |> text("Click me", translate: {15, 35})

      {:ok, _} = ViewPort.put_graph(viewport, :my_scene, graph)

      # With input handling
      graph = Graph.build()
      |> button("Submit", id: :submit_btn, translate: {100, 100})
      |> text("Status: Ready", id: :status, translate: {100, 150})

      ViewPort.put_graph(viewport, :form_scene, graph)

      # Scene-owned graph (typical pattern)
      ViewPort.put_graph(viewport, scene_id, graph, owner: self())

  ## Compilation Process

  1. Graph traversed depth-first to collect primitives
  2. Transforms and styles calculated and inherited
  3. Drawing commands generated for each primitive
  4. Input handling data extracted for clickable elements
  5. Script optimized and stored with change detection
  6. Drivers notified if script content changed
  7. Input routing tables updated in ViewPort

  ## Performance Notes

  - Compilation is expensive - avoid frequent graph rebuilds when possible
  - Change detection prevents unnecessary driver updates
  - Input data compilation enables efficient hit testing
  - Large graphs should consider breaking into smaller, reusable scripts

  ## Error Handling

  Compilation can fail if the graph contains:
  - Invalid primitive data
  - Malformed transforms or styles
  - Circular script references
  - Resource references that can't be resolved
  """
  @spec put_graph(
          viewport :: ViewPort.t(),
          name :: any,
          graph :: Graph.t(),
          opts :: Keyword.t()
        ) :: {:ok, name :: any} | {:error, atom}
  def put_graph(%ViewPort{pid: pid, semantic_table: semantic_table, scene_script_table: scene_script_table} = viewport, name, %Graph{} = graph, opts \\ []) do
    opts =
      opts
      |> Enum.into([])
      |> NimbleOptions.validate(put_x_opts_schema())
      |> case do
        {:ok, opts} -> opts
        {:error, error} -> raise Exception.message(error)
      end

    with {:ok, script} <- GraphCompiler.compile(graph),
         {:ok, {input, input_types, semantic_entries}} <- Scenic.SSM.Compiler.compile(graph) do
      input_list = {input, input_types}
      # Synchronous semantic compilation via SSM (replaces async Task)
      if viewport.semantic_enabled do
        store_semantic_entries(viewport, name, semantic_entries)
      end

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

          # Build and store semantic information
          semantic_info = build_semantic_info(graph, name)
          true = :ets.insert(semantic_table, {name, semantic_info})

          # Build and store enhanced scene script information
          new_graph? = not :ets.member(scene_script_table, name)
          scene_script_info = build_scene_script_info(graph, name, script, %{})
          true = :ets.insert(scene_script_table, {name, scene_script_info})

          # Hierarchy (parent/child/depth) only changes when the SET of
          # graphs changes — recomputing it on every content push made each
          # push O(all graphs ever seen), so a busy editor got slower with
          # every accumulated scene (per-keystroke latency growing over a
          # session). Recompute only when a new graph name appears; removals
          # recompute in the :DOWN / del_graph cleanup paths.
          if new_graph?, do: recompute_scene_script_hierarchy(scene_script_table)

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
  def del_graph(%ViewPort{semantic_table: semantic_table, scene_script_table: scene_script_table} = viewport, name) do
    # Mirror put_graph: a deleted graph must not leave ghost semantic /
    # scene-script rows behind (see the :DOWN handler for the full story).
    if semantic_table, do: :ets.delete(semantic_table, name)

    if scene_script_table do
      :ets.delete(scene_script_table, name)
      # Set shrank — refresh hierarchy (put_graph only recomputes on set growth)
      recompute_scene_script_hierarchy(scene_script_table)
    end

    del_script(viewport, name)
  end

  # --------------------------------------------------------
  @doc """
  Set the root theme for the ViewPort.

  > #### Warning {: .error}
  >
  > This will restart the current root scene
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

  def set_root(_, %Scene{}, _) do
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
  @doc """
  Get the semantic information for a graph in the viewport.

  This is useful during development to inspect what semantic annotations
  are available for testing.

  ## Examples

      ViewPort.get_semantic(viewport)
      # => {:ok, %{elements: %{...}, by_type: %{...}}}

      ViewPort.get_semantic(viewport, :specific_graph)
      # => {:ok, %{...}}
  """
  @spec get_semantic(viewport :: ViewPort.t(), graph_key :: any) ::
          {:ok, map} | {:error, :no_semantic_info}
  def get_semantic(%ViewPort{pid: pid}, graph_key \\ :main) do
    GenServer.call(pid, {:get_semantic, graph_key})
  end

  @doc """
  Register a semantic element in the viewport's semantic table.

  This allows components and scenes to manually register clickable elements
  with their semantic information and bounds for testing and automation.

  ## Parameters
    - `viewport` - The ViewPort struct or PID
    - `graph_key` - The graph key (typically the scene name or :_root_)
    - `element_id` - The semantic ID for this element (atom)
    - `semantic_data` - Map containing element metadata including:
      - `:type` - Element type (e.g., :button, :text_input)
      - `:label` - Human-readable label
      - `:clickable` - Boolean indicating if element accepts clicks
      - `:bounds` - Map with :left, :top, :width, :height

  ## Examples
      ViewPort.register_semantic(viewport, :_root_, :my_button, %{
        type: :button,
        label: "Click Me",
        clickable: true,
        bounds: %{left: 100, top: 200, width: 150, height: 40}
      })
  """
  @spec register_semantic(
          viewport :: ViewPort.t() | pid(),
          graph_key :: any(),
          element_id :: atom(),
          semantic_data :: map()
        ) :: :ok
  def register_semantic(viewport, graph_key, element_id, semantic_data)

  def register_semantic(%ViewPort{pid: pid}, graph_key, element_id, semantic_data) do
    register_semantic(pid, graph_key, element_id, semantic_data)
  end

  def register_semantic(pid, graph_key, element_id, semantic_data) when is_pid(pid) do
    GenServer.call(pid, {:register_semantic, graph_key, element_id, semantic_data})
  end

  # --------------------------------------------------------
  @doc """
  Inspect all semantic information in the viewport.

  This prints a formatted view of all semantic elements, making it easy
  to see what's available during development.

  ## Examples

      ViewPort.inspect_semantic(viewport)
      # Prints:
      # === Semantic Tree for :main ===
      # Total elements: 5
      #
      # By type:
      #   button: 2 elements
      #     - :submit_btn: %{type: :button, label: "Submit"}
      #     - :cancel_btn: %{type: :button, label: "Cancel"}
      #   text_buffer: 1 element
      #     - :buffer_1: %{type: :text_buffer, buffer_id: 1}
      # => :ok
  """
  @spec inspect_semantic(viewport :: ViewPort.t(), graph_key :: any) :: :ok
  def inspect_semantic(%ViewPort{} = viewport, graph_key \\ :main) do
    Scenic.Semantic.Query.inspect_semantic_tree(viewport, graph_key)
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
    scene_script_table = :ets.new(:_vp_scene_script_table_, [:public, {:read_concurrency, true}])

    # Create semantic tables if enabled (default: true)
    {semantic_table, semantic_index, semantic_enabled} =
      if opts[:semantic_registration] != false do
        st =
          :ets.new(:_vp_semantic_table_, [
            :public,
            :ordered_set,
            {:read_concurrency, true}
          ])

        si =
          :ets.new(:_vp_semantic_index_, [
            :public,
            :set,
            {:read_concurrency, true}
          ])

        {st, si, true}
      else
        {nil, nil, false}
      end

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
      scene_script_table: scene_script_table,

      # Semantic element tables for testing/automation (Phase 1)
      # semantic_table: ETS table with {scene_name, element_id} -> Entry
      # semantic_index: ETS table with element_id -> {scene_name, element_id}
      # semantic_enabled: boolean flag
      semantic_table: semantic_table,
      semantic_index: semantic_index,
      semantic_enabled: semantic_enabled,

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

      # SSM hover tracking — which element is currently under the cursor
      # nil | {pid, inv_tx, element_id}
      _hover_target: nil,

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
          semantic_table: semantic_table,
          scene_script_table: scene_script_table,
          scenes_by_pid: scenes_by_pid,
          scenes_by_id: scenes_by_id,
          starting_scenes: starting_scenes,
          monitors: monitors
        } = old_state
      ) do
    # Collect this pid's graph names BEFORE deleting its scripts, so the
    # matching semantic / scene-script rows can be purged with them. Without
    # this, every dead scene leaves ghost rows in the semantic table (its
    # last-rendered text, cursor, etc.), which shadow the live scene's data
    # for any "find latest entry of type X" style query — the root cause of
    # an entire class of order-dependent test flakes.
    owned_names = :ets.match(script_table, {:"$1", :_, pid}) |> List.flatten()

    # cleanup scripts & names tables
    :ets.match_delete(script_table, {:_, :_, pid})

    # Tell the DRIVERS too — the explicit del_script path casts @del_scripts,
    # but this death path never did, so the render side accumulated every
    # dead scene's scripts for the life of the session. The C driver's
    # per-frame work grew with each dead scene: measured as GPU render time
    # degrading ~2x over a long run (and an editor session "getting slow").
    if owned_names != [] do
      cast_drivers(old_state, {@del_scripts, owned_names})
    end

    Enum.each(owned_names, fn name ->
      if semantic_table, do: :ets.delete(semantic_table, name)
      if scene_script_table, do: :ets.delete(scene_script_table, name)
    end)

    # The graph set shrank — refresh hierarchy once (put_graph no longer
    # recomputes on every push, only on set changes).
    if scene_script_table != nil and owned_names != [] do
      recompute_scene_script_hierarchy(scene_script_table)
    end

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
        {Scenic.Primitive.Component, script_id, local_tx, _pid, _uid, _local_id, _scissor}, acc ->
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

  # --------------------------------------------------------
  # Semantic information access
  def handle_call({:get_semantic, graph_key}, _from, %{semantic_table: semantic_table} = state) do
    result = case :ets.lookup(semantic_table, graph_key) do
      [{^graph_key, info}] -> {:ok, info}
      [] -> {:error, :no_semantic_info}
    end
    {:reply, result, state}
  end

  # Register a semantic element
  def handle_call({:register_semantic, graph_key, element_id, semantic_data}, _from, %{semantic_table: semantic_table} = state) do
    # Get current semantic data for this graph, or create new
    current_data = case :ets.lookup(semantic_table, graph_key) do
      [{^graph_key, data}] -> data
      [] -> %{
        graph_key: graph_key,
        timestamp: System.system_time(:millisecond),
        elements: %{},
        by_type: %{}
      }
    end

    # Add the new element
    element_type = Map.get(semantic_data, :type, :unknown)

    updated_data = current_data
    |> put_in([:elements, element_id], Map.merge(semantic_data, %{id: element_id}))
    |> update_in([:by_type, element_type], fn existing ->
      existing = existing || []
      if element_id in existing do
        existing
      else
        [element_id | existing]
      end
    end)
    |> Map.put(:timestamp, System.system_time(:millisecond))

    # Store back in ETS
    :ets.insert(semantic_table, {graph_key, updated_data})

    {:reply, :ok, state}
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

  # Compile and store semantic elements (Phase 1)
  # Store pre-compiled semantic entries into ETS tables (synchronous, from SSM compiler)
  defp store_semantic_entries(viewport, scene_name, entries) do
    Enum.each(entries, fn entry ->
      key = {scene_name, entry.id}
      :ets.insert(viewport.semantic_table, {key, entry})
      :ets.insert(viewport.semantic_index, {entry.id, key})
    end)

    :ok
  rescue
    error ->
      require Logger

      Logger.warning(
        "Semantic storage failed for #{inspect(scene_name)}: #{Exception.message(error)}"
      )

      :ok
  end

  defp gen_info(%{
         name: name,
         # name_table: name_table,
         script_table: script_table,
         semantic_table: semantic_table,
         semantic_index: semantic_index,
         semantic_enabled: semantic_enabled,
         scene_script_table: scene_script_table,
         size: size
       }) do
    %ViewPort{
      pid: self(),
      name: name,
      # name_table: name_table,
      script_table: script_table,
      semantic_table: semantic_table,
      semantic_index: semantic_index,
      semantic_enabled: semantic_enabled,
      scene_script_table: scene_script_table,
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
         %{input_lists: ils, script_table: script_table, semantic_table: semantic_table, scene_script_table: scene_script_table} = state
       ) do
    state =
      with {:ok, script} <- GraphCompiler.compile(graph),
           {:ok, {input_list, input_types, _semantic_entries}} <- Scenic.SSM.Compiler.compile(graph) do
        # write the script to the table
        case :ets.lookup(script_table, name) do
          # do nothing if the script is in the table and has not changed
          [{_, ^script, :viewport}] ->
            :no_change

          # it isn't there or has changed
          _ ->
            true = :ets.insert(script_table, {name, script, :viewport})

            # Build and store semantic information
            semantic_info = build_semantic_info(graph, name)
            true = :ets.insert(semantic_table, {name, semantic_info})

            # Build and store enhanced scene script information
            scene_script_info = build_scene_script_info(graph, name, script, state)
            true = :ets.insert(scene_script_table, {name, scene_script_info})

            # Recompute hierarchy for all graphs after each update
            recompute_scene_script_hierarchy(scene_script_table)

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
  # cursor_pos — do normal routing PLUS hover tracking for cursor_enter/leave
  defp handle_input(
         {:cursor_pos, gxy} = input,
         %{
           _input_captures: captures,
           _input_requests: requests,
           input_positional: input_positional,
           _hover_target: prev_hover
         } = state
       ) do
    case Map.fetch(captures, :cursor_pos) do
      {:ok, pids} ->
        do_captured_input(input, pids, state)
        {:noreply, state}

      :error ->
        # Single hit-test with :any — reuse for both cursor_pos delivery and hover
        hit = if Enum.member?(input_positional, :cursor_pos) or
                 Enum.member?(input_positional, :cursor_enter) do
          input_find_hit(state.input_lists, :any, @root_id, gxy)
        else
          :not_found
        end

        # Deliver cursor_pos to the hit element (if it accepts cursor_pos)
        case hit do
          {:ok, pid, xy, _inv_tx, id} ->
            send(pid, {:_input, {:cursor_pos, xy}, input, id})
          _ -> :ok
        end

        # Deliver to request listeners
        case Map.fetch(requests, :cursor_pos) do
          {:ok, pids} -> do_requested_input(input, pids, state)
          :error -> :ok
        end

        # Hover tracking — compare current hit with previous hover target
        curr_key = case hit do
          {:ok, pid, _xy, inv_tx, id} -> {pid, inv_tx, id}
          _ -> nil
        end

        prev_key = prev_hover

        state = if hover_target_changed?(prev_key, curr_key) do
          # Fire cursor_leave to old target
          fire_cursor_leave(prev_key, gxy)
          # Fire cursor_enter to new target
          fire_cursor_enter(curr_key, gxy, hit)
          %{state | _hover_target: curr_key}
        else
          state
        end

        {:noreply, state}
    end
  end

  # viewport exit — clear hover target
  defp handle_input(
         {:viewport, {:exit, _pos}} = input,
         %{_hover_target: hover} = state
       ) do
    # Fire leave to current hover target
    if hover do
      fire_cursor_leave(hover, {0, 0})
    end
    state = %{state | _hover_target: nil}

    # Continue with normal viewport event handling
    %{_input_captures: captures, _input_requests: requests, input_positional: input_positional} = state
    case Map.fetch(captures, :viewport) do
      {:ok, pids} -> do_captured_input(input, pids, state)
      :error ->
        if Enum.member?(input_positional, :viewport), do: do_listed_input(input, state)
        case Map.fetch(requests, :viewport) do
          {:ok, pids} -> do_requested_input(input, pids, state)
          :error -> :ok
        end
    end
    {:noreply, state}
  end

  # receive input from a driver and cast it to a scene (generic handler)
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
        listed_result = if Enum.member?(input_positional, input_type) do
          do_listed_input(input, state)
        end

        # Scroll targeting: when a hit-tested scrollable handles the event,
        # don't also broadcast to request_input listeners. This makes nested
        # scrollables work — innermost gets the event exclusively.
        # If it can't handle it, it returns {:cont, scene} which bubbles up.
        skip_requested = input_type == :cursor_scroll and listed_result == :hit

        unless skip_requested do
          case Map.fetch(requests, input_type) do
            {:ok, pids} -> do_requested_input(input, pids, state)
            :error -> :ok
          end
        end
    end

    {:noreply, state}
  end

  # --------------------------------------------------------
  # a scene decided to let others continue processing the input
  def handle_continue_input(raw_input, state) do
    handle_input(raw_input, state)
  end

  # ── SSM hover tracking helpers ──

  defp hover_target_changed?(nil, nil), do: false
  defp hover_target_changed?(nil, _), do: true
  defp hover_target_changed?(_, nil), do: true
  defp hover_target_changed?({pid_a, _, id_a}, {pid_b, _, id_b}),
    do: pid_a != pid_b or id_a != id_b

  defp fire_cursor_leave(nil, _gxy), do: :ok
  defp fire_cursor_leave({pid, inv_tx, id}, gxy) do
    xy = Math.Vector2.project(gxy, inv_tx)
    send(pid, {:_input, {:cursor_leave, xy}, {:cursor_leave, gxy}, id})
  rescue
    _ -> :ok
  end

  defp fire_cursor_enter(nil, _gxy, _hit), do: :ok
  defp fire_cursor_enter({_pid, _inv_tx, _id}, _gxy, :not_found), do: :ok
  defp fire_cursor_enter({pid, _inv_tx, id}, _gxy, {:ok, _pid, xy, _inv, _id}) do
    send(pid, {:_input, {:cursor_enter, xy}, {:cursor_enter, xy}, id})
  rescue
    _ -> :ok
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
    # coord space and indicate if it was over an input.
    #
    # If the scene's transform cannot be resolved, DROP the event for that
    # pid — the captured-input path already does this for buttons.
    #
    # Measured: this fires ~676×/suite-run, i.e. it is the COMMON case for
    # a non-positional requester when the click hits some other component,
    # not a rare race. Forwarding raw GLOBAL coords (the old behavior) made
    # the receiver run local math on global values — e.g. a menu-bar click
    # at global y=17 is "inside" a full-height editor pane's local box, so
    # the editor treated menu clicks as text clicks. Components had grown
    # ad-hoc defenses against this (see TextField's overlay-click filter).
    # Dropping is both safer and cheaper.
    Enum.each(pids, fn pid ->
      case prep_gxy_input(gxy, :any, pid, state) do
        {:ok, xy, id} ->
          send(pid, {:_input, {:cursor_button, {button, action, mods, xy}}, input, id})

        _ ->
          :ok
      end
    end)
  end

  defp do_requested_input({:cursor_scroll, {delta, gxy}} = input, pids, state) do
    # send the input to each requesting pid. But... needs to be in the local
    # coord space and indicate if it was over an input.
    # Unresolvable transform → drop for that pid (see cursor_button above).
    Enum.each(pids, fn pid ->
      case prep_gxy_input(gxy, :any, pid, state) do
        {:ok, xy, id} -> send(pid, {:_input, {:cursor_scroll, {delta, xy}}, input, id})
        _ -> :ok
      end
    end)
  end

  defp do_requested_input({:cursor_pos, gxy} = input, pids, state) do
    # send the input to each requesting pid. But... needs to be in the local
    # coord space and indicate if it was over an input.
    # Unresolvable transform → drop for that pid (see cursor_button above).
    Enum.each(pids, fn pid ->
      case prep_gxy_input(gxy, :any, pid, state) do
        {:ok, xy, id} -> send(pid, {:_input, {:cursor_pos, xy}, input, id})
        _ -> :ok
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
    case input_find_hit(ils, :cursor_scroll, @root_id, gxy) do
      {:ok, pid, xy, _inv_tx, id} ->
        send(pid, {:_input, {:cursor_scroll, {delta, xy}}, input, id})
        :hit
      _ ->
        :not_found
    end
  end

  # cursor_enter/leave are synthetic events fired by hover tracking — not routed via listed input
  defp do_listed_input({:cursor_enter, _}, _state), do: :ok
  defp do_listed_input({:cursor_leave, _}, _state), do: :ok

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
    # Clear hover target if the hovered scene went down
    state = case state._hover_target do
      {^pid, _, _} -> %{state | _hover_target: nil}
      _ -> state
    end

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
    input = comp_input_prim([], 0, primitives[0], primitives, Math.Matrix.identity(), nil)

    # compile the requested input types
    types =
      Enum.reduce(input, [], fn {_mod, _name, _tx, _pid, types, _id, _scissor}, acc ->
        [types | acc]
      end)
      |> List.flatten()
      |> Enum.uniq()

    {:ok, {input, types}}
  end

  defp comp_input_prim(input, uid, primitive, primitives, tx, scissor)

  # skip anything hidden
  defp comp_input_prim(input, _uid, %Primitive{styles: %{hidden: true}}, _, _tx, _scissor), do: input

  # skip script primitives - no input handlers there
  defp comp_input_prim(input, _uid, %Primitive{module: Primitive.Script}, _, _tx, _scissor), do: input

  # it is a group. Calc the local transform if there one, but doesn't go into the
  # list as a component itself...
  defp comp_input_prim(
         input,
         _uid,
         %Primitive{module: Primitive.Group, data: ids, transforms: txs, styles: styles},
         primitives,
         tx,
         scissor
       ) do
    # calculate the graph-local transform
    local_tx = local_tx(txs, tx)

    # if this group has a scissor style, create scissor bounds for children
    # scissor is {w, h} and clips to {0, 0, w, h} in the group's local space
    child_scissor =
      case Map.get(styles, :scissor) do
        {w, h} -> {local_tx, w, h}
        _ -> scissor
      end

    # reduce the group
    Enum.reduce(ids, input, fn id, inpt ->
      comp_input_prim(inpt, id, primitives[id], primitives, local_tx, child_scissor)
    end)
  end

  # components get a call out to another input list
  defp comp_input_prim(
         input,
         _uid,
         %Primitive{module: Primitive.Component, data: {_, _, name}, transforms: txs},
         _,
         tx,
         scissor
       ) do
    # calculate the graph-local transform
    local_tx = local_tx(txs, tx)
    [{Primitive.Component, name, local_tx, self(), [], nil, scissor} | input]
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
         tx,
         scissor
         # ) when is_list(input_types) do
       ) do
    # calculate the graph-local transform
    local_tx = local_tx(txs, tx)
    [{module, data, local_tx, self(), input_types, id, scissor} | input]
  end

  # primitives that don't have input set are skipped
  defp comp_input_prim(input, _uid, _primitive, _, _tx, _scissor), do: input

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

  # Check if a global point is clipped by a scissor rectangle.
  # Returns true if the point is OUTSIDE the scissor (i.e. clipped/hidden).
  # scissor_tx is the scissor group's accumulated transform within its own graph.
  # parent_tx is the transform that maps from the graph's local space to global space.
  defp scissor_clips?(nil, _gx, _gy, _parent_tx), do: false

  defp scissor_clips?({scissor_tx, w, h}, gx, gy, parent_tx) do
    # Compose parent_tx with scissor_tx to get full global transform
    global_scissor_tx = Math.Matrix.mul(parent_tx, scissor_tx)
    inv = Math.Matrix.invert(global_scissor_tx)
    {sx, sy} = Math.Vector2.project({gx, gy}, inv)
    # Clipped if outside the scissor rectangle {0, 0, w, h}
    sx < 0 or sx > w or sy < 0 or sy > h
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

    # If any primitive wants cursor_enter, ensure cursor_pos is requested
    # from the driver (viewport generates enter/leave from cursor_pos events)
    input_positional =
      if :cursor_enter in input_positional and :cursor_pos not in input_positional do
        Enum.sort([:cursor_pos | input_positional])
      else
        input_positional
      end

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
    # require Logger
    # Logger.info("🎯 input_find_hit: name=#{inspect(name)}, type=#{inspect(input_type)}, point=#{inspect(global_point)}")

    case Map.fetch(lists, name) do
      {:ok, {in_list, _, _}} ->
        # Logger.info("  Found input_list with #{length(in_list)} items")
        do_find_hit(in_list, input_type, global_point, lists, name, parent_tx)

      _ ->
        # Logger.info("  No input_list found for #{inspect(name)}")
        :not_found
    end
  end

  defp do_find_hit(input_list, input_type, global_point, lists, name, parent_tx)
  defp do_find_hit([], _, _, _, _, _), do: :not_found

  # components recurse
  defp do_find_hit(
         [{Primitive.Component, data, local_tx, _pid, _uid, _id, scissor} | tail],
         input_type,
         {gx, gy} = global_point,
         lists,
         name,
         parent_tx
       ) do
    # if there's a scissor, check the global point is within scissor bounds
    # before recursing into the component
    if scissor_clips?(scissor, gx, gy, parent_tx) do
      do_find_hit(tail, input_type, global_point, lists, name, parent_tx)
    else
    # require Logger
    # Logger.info("🔍 Component hit test: name=#{inspect(name)}, component_id=#{inspect(data)}, point=#{inspect(global_point)}")

    # calculate the local matrix, which becomes the parent of the component
    local_tx = Math.Matrix.mul(parent_tx, local_tx)

    # recurse to test the component
    case input_find_hit(lists, input_type, data, global_point, local_tx) do
      {:ok, _, _, _, _} = hit ->
        # There was a hit inside the component. Return result as we are done.
        # Logger.info("✅ Component hit found!")
        hit

      :not_found ->
        # if not found, keep going
        # Logger.info("❌ Component hit not found, continuing...")
        do_find_hit(tail, input_type, global_point, lists, name, parent_tx)
    end
    end
  end

  # actual thing to test against
  defp do_find_hit(
         [{module, data, local_tx, pid, types, id, scissor} | tail],
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

    # for this to be a hit, it must pass the scissor check, be a valid input type
    # on the primitive, AND be within the primitive itself.
    with false <- scissor_clips?(scissor, gx, gy, parent_tx),
         true <- input_type == :any || Enum.member?(types, input_type),
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
      _ ->
        # No hit here (scissor clipped, wrong input type, or outside primitive)
        do_find_hit(tail, input_type, gp, lists, name, parent_tx)
    end
  end

  # Build semantic information from a graph
  defp build_semantic_info(graph, graph_key) do
    elements =
      graph.primitives
      |> Enum.reduce(%{}, fn {id, primitive}, acc ->
        # Extract semantic data if present - use direct access for struct fields
        # Check if primitive has opts field and it contains semantic data
        opts = Map.get(primitive, :opts, [])
        semantic = case opts do
          opts when is_list(opts) -> Keyword.get(opts, :semantic)
          _ -> nil
        end

        if semantic do
          # The ID is stored in primitive.id field, not in opts
          symbolic_id = Map.get(primitive, :id, id)

          element_info = %{
            id: symbolic_id,
            primitive_id: id,
            type: primitive.module,
            semantic: semantic,
            # Extract text content for text primitives
            content: extract_content(primitive),
            # Store transform for position info if needed
            transforms: primitive.transforms
          }
          Map.put(acc, symbolic_id, element_info)
        else
          acc
        end
      end)

    %{
      graph_key: graph_key,
      timestamp: System.system_time(:millisecond),
      elements: elements,
      # Quick access indices
      by_type: group_elements_by_semantic_type(elements)
    }
  end

  # Build enhanced scene script information with hierarchy and metadata
  defp build_scene_script_info(graph, graph_key, script, state) do
    # Extract all elements (not just semantic ones)
    elements = extract_all_elements(graph)

    # Extract script references for hierarchy
    children = extract_script_references(script)

    # Debug output (removed for production)

    # Build enhanced element data
    enhanced_elements = enhance_elements(elements, graph)

    %{
      # === HIERARCHY INFORMATION ===
      graph_key: graph_key,
      children: children,
      parent: nil,                    # Will be computed during hierarchy pass
      depth: 0,                      # Will be computed during hierarchy pass
      render_order: 0,               # Will be computed during hierarchy pass

      # === METADATA ===
      timestamp: System.system_time(:millisecond),
      owner_pid: determine_owner_pid(state),

      # === VISUAL INFORMATION ===
      transforms: extract_graph_transforms(script),
      bounds: %{x: 0, y: 0, w: 0, h: 0},  # Will be computed from primitives

      # === ELEMENTS (Enhanced from current semantic system) ===
      elements: enhanced_elements,

      # === FAST LOOKUPS ===
      by_type: group_elements_by_semantic_type(enhanced_elements),
      by_role: group_elements_by_role(enhanced_elements),
      by_primitive: group_elements_by_primitive_type(enhanced_elements)
    }
  end

  # Extract all primitives, not just those with semantic data
  defp extract_all_elements(graph) do
    graph.primitives
    |> Enum.reduce(%{}, fn {id, primitive}, acc ->
      element_info = %{
        id: id,
        type: primitive.module,
        primitive_data: primitive.data,
        transforms: primitive.transforms,

        # Semantic data (if present)
        semantic: extract_semantic_data(primitive),

        # Content (for text primitives)
        content: extract_content(primitive),

        # Computed properties for automation
        clickable: is_clickable_primitive(primitive),
        visible: true,  # Will be computed based on transforms/clips
        text_selectable: is_text_selectable(primitive)
      }
      Map.put(acc, id, element_info)
    end)
  end

  # Extract semantic data from primitive options
  defp extract_semantic_data(primitive) do
    case Map.get(primitive, :opts) do
      nil -> %{}
      opts when is_list(opts) -> Keyword.get(opts, :semantic, %{})
      _ -> %{}
    end
  end

  # Extract script references from compiled script
  defp extract_script_references(script) when is_list(script) do
    references = script
    |> Enum.filter(fn
      {:script, _child_key} -> true
      _ -> false
    end)
    |> Enum.map(fn {:script, key} -> key end)
    |> Enum.uniq()

    # Debug output (removed for production)

    references
  end
  defp extract_script_references(_), do: []

  # Extract graph-level transforms from script
  defp extract_graph_transforms(script) when is_list(script) do
    script
    |> Enum.filter(fn
      {:push_transform, _} -> true
      {:translate, _} -> true
      {:scale, _} -> true
      {:rotate, _} -> true
      _ -> false
    end)
  end
  defp extract_graph_transforms(_), do: []

  # Enhance elements with computed properties
  defp enhance_elements(elements, _graph) do
    # For now, just return elements as-is
    # TODO: Add bounds calculation, visibility computation, etc.
    elements
  end

  # Determine if primitive is clickable
  defp is_clickable_primitive(%{module: Scenic.Primitive.RoundedRectangle}), do: true
  defp is_clickable_primitive(%{module: Scenic.Primitive.Rectangle}), do: true
  defp is_clickable_primitive(%{module: Scenic.Primitive.Circle}), do: true
  defp is_clickable_primitive(%{module: Scenic.Primitive.Ellipse}), do: true
  defp is_clickable_primitive(primitive) do
    # Check if primitive has semantic role that suggests clickability
    semantic = extract_semantic_data(primitive)
    case Map.get(semantic, :role) do
      :button -> true
      :link -> true
      _ -> false
    end
  end

  # Determine if primitive contains selectable text
  defp is_text_selectable(%{module: Scenic.Primitive.Text}), do: true
  defp is_text_selectable(primitive) do
    semantic = extract_semantic_data(primitive)
    Map.get(semantic, :type) == :text_buffer
  end

  # Group elements by accessibility role
  defp group_elements_by_role(elements) do
    elements
    |> Enum.reduce(%{}, fn {id, element}, acc ->
      if role = get_in(element, [:semantic, :role]) do
        Map.update(acc, role, [id], &[id | &1])
      else
        acc
      end
    end)
  end

  # Group elements by primitive type
  defp group_elements_by_primitive_type(elements) do
    elements
    |> Enum.reduce(%{}, fn {id, element}, acc ->
      primitive_type = element.type
      Map.update(acc, primitive_type, [id], &[id | &1])
    end)
  end

  # Determine owner PID from state
  defp determine_owner_pid(_state) do
    # For now, return nil - this would need access to the owner info
    # from the graph insertion context
    nil
  end

  # Recompute hierarchy relationships for all scene scripts
  defp recompute_scene_script_hierarchy(scene_script_table) do
    # Get all current scene script entries
    entries = :ets.tab2list(scene_script_table)

    # Build parent/child relationships and compute depths
    updated_entries = compute_hierarchy_relationships(entries)

    # Update all entries with new hierarchy information
    Enum.each(updated_entries, fn {key, updated_data} ->
      :ets.insert(scene_script_table, {key, updated_data})
    end)
  end

  # Compute parent/child relationships and depths for all scene scripts
  defp compute_hierarchy_relationships(entries) do
    # Create a map for easier lookups
    data_map = Map.new(entries)

    # Build parent relationships by finding who references each graph
    entries_with_parents = Enum.map(entries, fn {key, data} ->
      parent = find_parent_graph(key, data_map)
      updated_data = Map.put(data, :parent, parent)
      {key, updated_data}
    end)

    # Compute depths starting from root nodes
    entries_with_depths = compute_depths(entries_with_parents)

    entries_with_depths
  end

  # Find which graph references this one as a child
  defp find_parent_graph(target_key, data_map) do
    Enum.find_value(data_map, fn {graph_key, graph_data} ->
      if target_key in graph_data.children do
        graph_key
      else
        nil
      end
    end)
  end

  # Compute depth for each graph based on its position in the hierarchy
  defp compute_depths(entries_with_parents) do
    data_map = Map.new(entries_with_parents)

    # Find root graphs (no parent)
    roots = Enum.filter(entries_with_parents, fn {_key, data} ->
      data.parent == nil
    end)

    # Assign depths starting from roots
    depth_assignments = compute_depths_recursive(roots, data_map, %{}, 0)

    # Apply depth assignments to all entries
    Enum.map(entries_with_parents, fn {key, data} ->
      depth = Map.get(depth_assignments, key, 0)
      updated_data = Map.put(data, :depth, depth)
      {key, updated_data}
    end)
  end

  # Recursively compute depths for the hierarchy
  defp compute_depths_recursive(nodes, data_map, depth_map, current_depth) do
    # Assign current depth to all nodes at this level
    updated_depth_map = Enum.reduce(nodes, depth_map, fn {key, _data}, acc ->
      Map.put(acc, key, current_depth)
    end)

    # Find all children of current nodes
    children = Enum.flat_map(nodes, fn {_key, data} ->
      data.children
      |> Enum.map(fn child_key ->
        child_data = Map.get(data_map, child_key)
        if child_data do
          {child_key, child_data}
        else
          nil
        end
      end)
      |> Enum.filter(& &1)
    end)

    # Recurse for children if any exist
    if children != [] do
      compute_depths_recursive(children, data_map, updated_depth_map, current_depth + 1)
    else
      updated_depth_map
    end
  end

  defp extract_content(%{module: Scenic.Primitive.Text, data: text}), do: text
  defp extract_content(_), do: nil

  defp group_elements_by_semantic_type(elements) do
    elements
    |> Enum.reduce(%{}, fn {id, element}, acc ->
      if type = get_in(element, [:semantic, :type]) do
        Map.update(acc, type, [id], &[id | &1])
      else
        acc
      end
    end)
  end
end
