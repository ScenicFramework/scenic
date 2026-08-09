# Troubleshooting Guide

This guide helps you diagnose and fix common issues when working with Scenic's architecture.

## General Debugging Workflow

1. **Identify the Layer**: Is the issue in Scene logic, ViewPort coordination, or Driver rendering?
2. **Check Process Health**: Are all processes running? Any crashes in logs?
3. **Inspect Data Flow**: Are graphs compiling? Scripts reaching drivers? Input routing correctly?
4. **Examine State**: ViewPort state, ETS contents, scene assigns
5. **Add Logging**: Trace the data flow through the system

## Nothing Renders / Blank Screen

### Symptoms
- Window opens but shows nothing
- Expected graphics don't appear
- No visual output from scenes

### Diagnostic Steps

#### 1. Check if ViewPort Started
```elixir
# Verify ViewPort is running
{:ok, info} = Scenic.ViewPort.info(:my_viewport)
IO.inspect(info)

# Check if process is alive
Process.alive?(info.pid)
```

#### 2. Check Scene Status
```elixir
# List running processes that look like scenes
scenes = Process.list()
|> Enum.filter(fn pid ->
  case Process.info(pid, :dictionary) do
    {:dictionary, dict} -> 
      Keyword.get(dict, :"$initial_call") 
      |> to_string() 
      |> String.contains?("Scene")
    _ -> false
  end
end)

IO.inspect(scenes, label: "Scene processes")
```

#### 3. Check Script Generation
```elixir
# List all scripts in ViewPort
script_ids = Scenic.ViewPort.all_script_ids(viewport)
IO.inspect(script_ids, label: "Available scripts")

# Check if root script exists
case Scenic.ViewPort.get_script(viewport, "_root_") do
  {:ok, script} -> 
    IO.puts("Root script has #{length(script)} commands")
  {:error, :not_found} ->
    IO.puts("ERROR: No root script found!")
end
```

#### 4. Check Driver Status
```elixir
# Check ETS table for scripts
:ets.tab2list(viewport.script_table)
|> Enum.each(fn {name, script, owner} ->
  IO.puts("Script: #{name}, Commands: #{length(script)}, Owner: #{inspect(owner)}")
end)
```

### Common Causes & Solutions

#### Scene Init Failed
```elixir
# Scene crashed during init - check logs
def init(scene, param, opts) do
  # Add logging to debug
  IO.puts("Scene init called with param: #{inspect(param)}")
  
  graph = Graph.build() |> text("Hello")
  scene = push_graph(scene, graph)
  
  IO.puts("Graph pushed successfully")
  {:ok, scene}
catch
  error -> 
    IO.puts("Scene init failed: #{inspect(error)}")
    {:stop, error}
end
```

#### No Driver Connected
```elixir
# Check if any drivers are running
driver_pids = :sys.get_state(viewport.pid).driver_pids
case driver_pids do
  [] -> IO.puts("ERROR: No drivers connected!")
  pids -> IO.puts("Drivers: #{inspect(pids)}")
end
```

#### Graph Compilation Failed
```elixir
# Test graph compilation manually
graph = Graph.build() |> text("test")
case Scenic.Graph.Compiler.compile(graph) do
  {:ok, script} -> 
    IO.puts("Compilation successful: #{length(script)} commands")
  {:error, reason} ->
    IO.puts("ERROR: Compilation failed: #{inspect(reason)}")
end
```

## Input Not Working

### Symptoms
- Clicks don't register
- Keyboard input ignored
- Mouse movement not tracked

### Diagnostic Steps

#### 1. Check Input Configuration
```elixir
# Verify primitives have input enabled
graph = Graph.build()
|> rectangle({100, 50}, 
    fill: :blue, 
    translate: {50, 50},
    input: [:cursor_button])  # Must have this!
```

#### 2. Check Input Requests
```elixir
# See what input types are being requested
state = :sys.get_state(viewport.pid)
IO.inspect(state._input_requests, label: "Input requests")
IO.inspect(state.input_positional, label: "Positional input")
```

#### 3. Test Input Injection
```elixir
# Manually inject input to test routing
test_input = {:cursor_button, {:btn_left, 1, [], {75, 75}}}
result = Scenic.ViewPort.input(viewport, test_input)
IO.inspect(result, label: "Input result")
```

#### 4. Check Hit Testing
```elixir
# Test hit detection manually
{:ok, hit} = Scenic.ViewPort.find_point(viewport, {75, 75})
IO.inspect(hit, label: "Hit test result")
```

### Common Causes & Solutions

#### Missing Input Style
```elixir
# WRONG - no input specified
|> rectangle({100, 50}, fill: :blue)

# CORRECT - input types specified
|> rectangle({100, 50}, fill: :blue, input: [:cursor_button])
```

#### Wrong Coordinate Space
```elixir
# Check if coordinates are in correct space
def handle_input({:cursor_button, {btn, action, mods, {x, y}}}, id, scene) do
  IO.puts("Click at local coords: {#{x}, #{y}}, element: #{id}")
  # Coordinates are already in scene's local space
  {:noreply, scene}
end
```

#### Scene Not Requesting Input
```elixir
# Scene must request input types it wants
def init(scene, _param, _opts) do
  # Request input types
  scene = Scene.request_input(scene, [:cursor_button, :key])
  # ... rest of init
end
```

## Performance Issues

### Symptoms
- Slow rendering
- High CPU usage
- Memory growth
- Laggy input response

### Diagnostic Steps

#### 1. Profile Script Compilation
```elixir
# Measure compilation time
{time_us, {:ok, script}} = :timer.tc(fn ->
  Scenic.Graph.Compiler.compile(large_graph)
end)
IO.puts("Compilation took #{time_us}μs for #{length(script)} commands")
```

#### 2. Check Script Sizes
```elixir
# Find large scripts
Scenic.ViewPort.all_script_ids(viewport)
|> Enum.map(fn id ->
  {:ok, script} = Scenic.ViewPort.get_script(viewport, id)
  {id, length(script)}
end)
|> Enum.sort_by(fn {_, size} -> size end, :desc)
|> Enum.take(10)
|> IO.inspect(label: "Largest scripts")
```

#### 3. Monitor Process Memory
```elixir
# Check ViewPort memory usage
info = Process.info(viewport.pid, [:memory, :message_queue_len])
IO.inspect(info, label: "ViewPort process info")

# Check ETS table size
table_info = :ets.info(viewport.script_table)
IO.inspect(table_info[:size], label: "Script table entries")
```

#### 4. Profile with Observer
```elixir
# Start observer to monitor system
:observer.start()
```

### Common Causes & Solutions

#### Frequent Graph Rebuilds
```elixir
# INEFFICIENT - rebuilds entire graph
def update_counter(scene, count) do
  graph = Graph.build()
  |> text("Count: #{count}")
  |> button("Reset")
  push_graph(scene, graph)
end

# EFFICIENT - modify only what changed
def update_counter(scene, count) do
  graph = scene.assigns.graph
  |> Graph.modify(:counter, &text(&1, "Count: #{count}"))
  push_graph(scene, graph)
end
```

#### Large Monolithic Graphs
```elixir
# INEFFICIENT - one huge graph
graph = Graph.build()
|> add_background()
|> add_menu()
|> add_content() 
|> add_footer()

# EFFICIENT - separate static and dynamic
# Use scripts for static content
ViewPort.put_script(vp, :background, background_script)
ViewPort.put_script(vp, :menu, menu_script)

graph = Graph.build()
|> script(:background)
|> script(:menu)
|> add_dynamic_content()  # Only this part recompiles
```

#### Memory Leaks
```elixir
# Check for orphaned scripts
:ets.tab2list(viewport.script_table)
|> Enum.map(fn {name, _script, owner} ->
  alive = Process.alive?(owner)
  {name, owner, alive}
end)
|> Enum.filter(fn {_, _, alive} -> not alive end)
|> IO.inspect(label: "Scripts with dead owners")
```

## Driver Issues

### Symptoms
- Graphics appear but don't update
- Driver crashes or restarts
- Input works but no visual feedback

### Diagnostic Steps

#### 1. Check Driver Process
```elixir
# Find driver processes
driver_pids = :sys.get_state(viewport.pid).driver_pids
Enum.each(driver_pids, fn pid ->
  case Process.info(pid) do
    nil -> IO.puts("Driver #{inspect(pid)} is dead")
    info -> IO.puts("Driver #{inspect(pid)} alive, memory: #{info[:memory]}")
  end
end)
```

#### 2. Test Script Delivery
```elixir
# Create a simple test driver
defmodule TestDriver do
  use Scenic.Driver
  
  def validate_opts(_), do: {:ok, []}
  def init(driver, _), do: {:ok, driver}
  
  def update_scene(script_ids, driver) do
    IO.puts("TestDriver received scripts: #{inspect(script_ids)}")
    {:ok, driver}
  end
end

{:ok, _} = Scenic.ViewPort.start_driver(viewport, [module: TestDriver])
```

#### 3. Check Driver Logs
Look for driver-specific error messages in logs.

### Common Causes & Solutions

#### Driver Not Handling Script Updates
```elixir
def update_scene(script_ids, driver) do
  # Process each script
  Enum.each(script_ids, fn id ->
    case Scenic.ViewPort.get_script(driver.viewport, id) do
      {:ok, script} -> render_script(script, driver)
      {:error, :not_found} -> 
        Logger.warn("Script #{id} not found")
    end
  end)
  {:ok, driver}
end
```

#### Graphics Context Issues
Ensure driver maintains proper graphics state:
```elixir
def render_script(script, driver) do
  # Save initial state
  save_graphics_state(driver.context)
  
  try do
    Enum.each(script, &execute_command(&1, driver))
  after
    # Always restore state
    restore_graphics_state(driver.context)
  end
end
```

## Scene Lifecycle Issues

### Symptoms
- Scenes don't start
- Components not appearing
- Scene crashes on updates

### Diagnostic Steps

#### 1. Check Scene Registration
```elixir
# Check scene hierarchy
state = :sys.get_state(viewport.pid)
IO.inspect(state.scenes_by_pid, label: "Scenes by PID")
IO.inspect(state.scenes_by_id, label: "Scenes by ID")
```

#### 2. Test Scene Init
```elixir
def init(scene, param, opts) do
  IO.puts("Scene #{__MODULE__} init called")
  IO.inspect(param, label: "Param")
  IO.inspect(opts, label: "Opts")
  
  # Your scene init code here
  {:ok, scene}
catch
  kind, error ->
    IO.puts("Scene init failed: #{kind} #{inspect(error)}")
    {:stop, error}
end
```

#### 3. Check Component Communication
```elixir
def handle_event({:click, :my_button}, _from, scene) do
  IO.puts("Button clicked in #{__MODULE__}")
  {:noreply, scene}
end
```

### Common Causes & Solutions

#### Scene Init Crashes
```elixir
# Add error handling to scene init
def init(scene, param, _opts) do
  try do
    graph = build_initial_graph(param)
    scene = push_graph(scene, graph)
    {:ok, scene}
  rescue
    error ->
      Logger.error("Scene init failed: #{inspect(error)}")
      # Return a minimal working scene
      graph = Graph.build() |> text("Error loading scene")
      scene = push_graph(scene, graph)
      {:ok, scene}
  end
end
```

#### Component Not Found
```elixir
# Verify component module exists and is compiled
Code.ensure_loaded?(MyApp.Component.Button)

# Check component is properly added to graph
graph = Graph.build()
|> MyApp.Component.Button.add_to_graph("Click me", id: :my_btn)
```

## ETS Table Issues

### Symptoms
- Scripts not persisting
- Memory errors
- Access violations

### Diagnostic Steps

#### 1. Check Table Health
```elixir
# Verify table exists and is accessible
table = viewport.script_table
:ets.info(table) |> IO.inspect(label: "Table info")

# Check table permissions
:ets.info(table, :protection) |> IO.inspect(label: "Protection")
```

#### 2. Check Table Contents
```elixir
# List all entries
:ets.tab2list(table) 
|> Enum.take(10)  # First 10 entries
|> IO.inspect(label: "Table contents")
```

### Common Causes & Solutions

#### Table Access Violations
ETS tables should be `:public` for concurrent driver access:
```elixir
# CORRECT - public table with read concurrency
:ets.new(:script_table, [:public, {:read_concurrency, true}])
```

#### Memory Pressure
```elixir
# Monitor table size
:ets.info(table, :memory) |> IO.inspect(label: "Table memory (words)")

# Clean up orphaned entries
:ets.match_delete(table, {:_, :_, :"$1"}) 
# This would delete entries where owner is dead (advanced usage)
```

## Common Error Messages

### "Scene process not found"
- Scene crashed during startup
- Check scene `init/3` function for errors
- Verify scene module exists and compiles

### "Script compilation failed"
- Invalid graph structure
- Missing or malformed primitives
- Check graph building code

### "Input routing failed"
- No scene has requested the input type
- Hit testing failed (no matching primitives)
- Check primitive input styles

### "Driver not responding"
- Driver process crashed
- Driver not implementing required callbacks
- Check driver logs for errors

## Debug Logging Setup

Add comprehensive logging to trace issues:

```elixir
# In config/dev.exs
config :logger, level: :debug

# In your modules
require Logger

def put_graph(scene, graph) do
  Logger.debug("Pushing graph with #{map_size(graph.primitives)} primitives")
  result = push_graph(scene, graph)
  Logger.debug("Graph push result: #{inspect(result)}")
  result
end
```

## Using Observer for System Monitoring

```elixir
# Start observer
:observer.start()

# Key things to monitor:
# 1. Process tree - are all processes running?
# 2. Memory usage - any processes using excessive memory?
# 3. ETS tables - size and access patterns
# 4. Message queues - any processes with message buildup?
```

The key to effective debugging is understanding the data flow: `Scene → Graph → ViewPort → Script → Driver → Screen` and `Input → ViewPort → Scene`. Most issues occur at the boundaries between these components.