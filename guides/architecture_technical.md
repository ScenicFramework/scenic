# Technical Architecture Guide

This guide provides an in-depth technical explanation of how Scenic's core components work together to create a high-performance, fault-tolerant GUI framework.

## Architectural Overview

Scenic uses a layered architecture that cleanly separates concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                        Applications                         │
│                     (Business Logic)                       │
├─────────────────────────────────────────────────────────────┤
│                         Scenes                              │
│                   (UI Logic & State)                       │
├─────────────────────────────────────────────────────────────┤
│                        Graphs                               │
│                  (Declarative UI)                          │
├─────────────────────────────────────────────────────────────┤
│                       ViewPort                              │
│                 (Coordination Layer)                       │
├─────────────────────────────────────────────────────────────┤
│                       Scripts                               │
│                 (Compiled Commands)                        │
├─────────────────────────────────────────────────────────────┤
│                       Drivers                               │
│                (Rendering & Input)                         │
├─────────────────────────────────────────────────────────────┤
│                      Hardware                               │
│                 (Display & Input)                          │
└─────────────────────────────────────────────────────────────┘
```

## The ViewPort: Central Coordination

### Core Architecture

The ViewPort acts as the central nervous system, coordinating all interactions between the application layer and the rendering layer.

#### ETS Table Strategy

```elixir
# Script table - public, read-optimized for concurrent driver access
script_table = :ets.new(:_vp_script_table_, [
  :public, 
  {:read_concurrency, true}
])

# Table structure: {name, script, owner_pid}
:ets.insert(script_table, {"button_1", compiled_script, scene_pid})
```

**Why ETS?**
- **Concurrent Access**: Multiple drivers can read simultaneously without blocking
- **Performance**: Direct memory access, no process serialization
- **Fault Tolerance**: Automatic cleanup when processes crash
- **Change Detection**: Efficient comparison of script content

#### Process Monitoring

```elixir
# ViewPort monitors all scenes and drivers
monitors = %{
  scene_pid => monitor_ref,
  driver_pid => monitor_ref
}

# Automatic cleanup on process crash
def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
  # Clean up scripts owned by crashed process
  :ets.match_delete(script_table, {:_, :_, pid})
  # Clean up input routing for crashed process  
  state = clean_input_state(state, pid)
  {:noreply, state}
end
```

### Input Processing Architecture

#### Hit Testing Algorithm

```elixir
def input_find_hit(lists, input_type, name, {gx, gy} = global_point, parent_tx) do
  case Map.fetch(lists, name) do
    {:ok, {input_list, _, _}} ->
      # Walk input list in reverse order (last drawn = first hit)
      do_find_hit(input_list, input_type, global_point, lists, name, parent_tx)
    _ ->
      :not_found
  end
end

defp do_find_hit([{module, data, local_tx, pid, types, id} | tail], input_type, {gx, gy}, lists, name, parent_tx) do
  # Calculate cumulative transform
  combined_tx = Math.Matrix.mul(parent_tx, local_tx)
  inverse_tx = Math.Matrix.invert(combined_tx)
  
  # Project global point to local coordinates
  {x, y} = Math.Vector2.project({gx, gy}, inverse_tx)
  
  # Test if point is within primitive and input type matches
  with true <- input_type == :any || Enum.member?(types, input_type),
       true <- module.contains_point?(data, {x, y}) do
    # Hit! Convert back to parent coordinate space
    parent_xy = Math.Vector2.project({gx, gy}, Math.Matrix.invert(parent_tx))
    {:ok, pid, parent_xy, inverse_tx, id}
  else
    false -> do_find_hit(tail, input_type, {gx, gy}, lists, name, parent_tx)
  end
end
```

#### Input Routing States

```elixir
# Normal operation - scenes request input types
input_requests = %{
  :cursor_button => [scene_pid_1, scene_pid_2],
  :key => [text_input_pid]
}

# Temporary capture - one scene captures all input of a type
input_captures = %{
  :cursor_pos => [dragging_scene_pid],  # Captures during drag
  :key => [modal_scene_pid]             # Captures during modal
}

# Positional input types from all scenes
input_positional = [:cursor_button, :cursor_scroll, :cursor_pos]
```

## Script Compilation Pipeline

### Graph → Script Transformation

```elixir
# 1. Graph describes WHAT to draw
graph = Graph.build()
|> rectangle({100, 50}, fill: :blue, translate: {10, 20})
|> text("Hello", font_size: 16, translate: {15, 35})

# 2. Compiler generates HOW to draw
script = GraphCompiler.compile(graph)
# Result: [
#   {:push_state},
#   {:fill_color, {:color_rgba, {0, 0, 255, 255}}},
#   {:translate, {10, 20}},
#   {:draw_rect, {100, 50}},
#   {:translate, {5, 15}},  # Relative offset
#   {:font_size, 16},
#   {:draw_text, "Hello"},
#   {:pop_state}
# ]
```

### Compilation Optimizations

#### Transform Flattening
```elixir
# Graph hierarchy:
# Group(translate: {10, 20}, scale: 2.0)
#   └─ Rectangle(translate: {5, 5})

# Compiled to single transform:
# translate({10, 20}) → scale(2.0) → translate({5, 5})
# Result: combined matrix applied once
combined_tx = Math.Matrix.mul([
  Matrix.translate({10, 20}),
  Matrix.scale({2.0, 2.0}), 
  Matrix.translate({5, 5})
])
```

#### State Management
```elixir
# Automatic state push/pop insertion
script = [
  {:push_state},      # Preserve parent state
  {:stroke_width, 2},
  {:stroke_color, :red},
  {:draw_line, {{0, 0}, {10, 10}}},
  {:pop_state}        # Restore parent state
]
```

## Driver Architecture

### Driver Lifecycle

```elixir
defmodule Scenic.Driver do
  # 1. Driver starts and registers with ViewPort
  def init(driver, opts) do
    GenServer.cast(viewport.pid, {:register_driver, self()})
    {:ok, driver}
  end

  # 2. ViewPort sends current state
  def handle_info({:_put_scripts_, ids}, driver) do
    # Read scripts from ETS and render
    scripts = Enum.map(ids, &ViewPort.get_script(viewport, &1))
    render_scripts(scripts, driver)
    {:noreply, driver}
  end

  # 3. Driver sends input back to ViewPort
  def handle_mouse_click(button, x, y, driver) do
    input = {:cursor_button, {button, 1, [], {x, y}}}
    ViewPort.input(viewport, input)
    {:noreply, driver}
  end
end
```

### Rendering Pipeline

```elixir
# Driver processes script commands sequentially
def render_script([cmd | rest], graphics_context) do
  case cmd do
    {:fill_color, color} -> 
      set_fill_color(graphics_context, color)
    {:translate, {x, y}} -> 
      translate_context(graphics_context, x, y)
    {:draw_rect, {w, h}} -> 
      draw_rectangle(graphics_context, w, h)
    {:push_state} -> 
      push_graphics_state(graphics_context)
    {:pop_state} -> 
      pop_graphics_state(graphics_context)
  end
  render_script(rest, graphics_context)
end
```

## Performance Characteristics

### Concurrent Script Access

```elixir
# Multiple drivers can read the same script simultaneously
# No serialization through ViewPort process

Driver A: ViewPort.get_script(vp, "scene_1") # Direct ETS read
Driver B: ViewPort.get_script(vp, "scene_1") # Concurrent ETS read  
Driver C: ViewPort.get_script(vp, "scene_1") # No blocking
```

### Change Detection Optimization

```elixir
def put_script(viewport, name, new_script, opts) do
  case :ets.lookup(script_table, name) do
    [{_, ^new_script, _}] -> 
      :no_change  # Identical script, no driver notification
    _ -> 
      :ets.insert(script_table, {name, new_script, owner})
      notify_drivers({:put_scripts, [name]})  # Only notify on change
      {:ok, name}
  end
end
```

### Input Rate Limiting

```elixir
# Driver-level input buffering
def send_input(driver, {:cursor_pos, _} = input) when driver.limit_ms > 0 do
  case driver.input_limited do
    true -> 
      # Buffer the input, send later
      %{driver | input_buffer: Map.put(driver.input_buffer, :cursor_pos, input)}
    false ->
      # Send immediately and start rate limit timer
      Process.send_after(self(), :_input_limiter_, driver.limit_ms)
      send_input_now(driver, input)
  end
end
```

## Fault Tolerance Mechanisms

### Process Isolation

```elixir
# Each component runs in its own process
Supervision Tree:
├─ Scenic.ViewPort (coordinator)
├─ DynamicSupervisor (scenes)
│  ├─ Scene.MainMenu
│  ├─ Scene.Settings  
│  └─ Component.Button
└─ DynamicSupervisor (drivers)
   ├─ Driver.Local
   └─ Driver.Network
```

### Graceful Degradation

```elixir
# ViewPort continues operating with partial failures
def handle_info({:DOWN, _ref, :process, driver_pid, reason}, state) do
  Logger.warn("Driver #{inspect(driver_pid)} crashed: #{inspect(reason)}")
  
  # Remove from driver list but continue serving other drivers
  state = %{state | driver_pids: List.delete(state.driver_pids, driver_pid)}
  
  # Scenes and other drivers unaffected
  {:noreply, state}
end
```

### Automatic Resource Cleanup

```elixir
# Scripts owned by crashed processes are automatically cleaned up
def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
  # Remove all scripts owned by crashed process
  :ets.match_delete(script_table, {:_, :_, pid})
  
  # Clean up input routing
  state = remove_input_requests(state, pid)
  state = remove_input_captures(state, pid)
  
  {:noreply, state}
end
```

## Memory Management

### Script Lifecycle

```elixir
# Scripts are reference counted through ownership
script_owners = %{
  "button_1" => scene_pid_1,
  "background" => scene_pid_1, 
  "modal" => scene_pid_2
}

# When scene crashes, all its scripts are cleaned up
# When script is replaced, old version is garbage collected
# ETS tables are memory-mapped and efficient
```

### Graph Compilation Caching

```elixir
# Scenes can cache compiled results
defmodule MyScene do
  # Compile once at module load time
  @static_graph Graph.build()
  |> rectangle({800, 600}, fill: :background)

  @static_script GraphCompiler.compile(@static_graph)

  def init(scene, _param, _opts) do
    # Use pre-compiled script - no runtime compilation cost
    ViewPort.put_script(scene.viewport, :background, @static_script)
    {:ok, scene}
  end
end
```

## Debugging and Introspection

### Script Analysis

```elixir
# Inspect compiled scripts
{:ok, script} = ViewPort.get_script(viewport, "my_scene")
Script.analyze(script)
# %{
#   command_count: 15,
#   draw_calls: 3,
#   state_changes: 8,
#   transforms: 2,
#   estimated_render_time: "0.1ms"
# }
```

### ViewPort State Inspection

```elixir
# View current ViewPort state
{:ok, info} = ViewPort.info(viewport)
%ViewPort{
  name: :main_viewport,
  size: {800, 600},
  script_table: #Reference<0.1234.5678>,
  pid: #PID<0.123.0>
}

# List all script IDs
ViewPort.all_script_ids(viewport)
# ["scene_1", "button_1", "background", ...]
```

### Input Flow Debugging

```elixir
# Trace input routing
def handle_input({:cursor_button, {button, action, mods, {x, y}}}, state) do
  Logger.debug("Input: button=#{button}, pos={#{x}, #{y}}")
  
  case input_find_hit(state.input_lists, :cursor_button, :_root_, {x, y}) do
    {:ok, pid, local_xy, _tx, id} ->
      Logger.debug("Hit: scene=#{inspect(pid)}, id=#{id}, local_pos=#{inspect(local_xy)}")
    :not_found ->
      Logger.debug("No hit found")
  end
end
```

This architecture enables Scenic to achieve its design goals of high performance, fault tolerance, and clean separation of concerns while handling the complex coordination required for real-time GUI applications.