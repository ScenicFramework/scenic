# Getting Started with Scenic Architecture

This guide provides a hands-on introduction to understanding and working with Scenic's core architecture. By the end of this guide, you'll understand how ViewPorts, Drivers, Scripts, and Scenes work together.

## Prerequisites

- Basic Elixir knowledge (processes, GenServers, supervision)
- Understanding of GUI concepts (rendering, input handling)
- Familiarity with ETS tables (helpful but not required)

## Quick Architecture Overview

Before diving in, let's understand the key players:

- **Scene**: Your application logic - creates graphs describing what to draw
- **Graph**: Declarative description of UI (like HTML)  
- **ViewPort**: Central coordinator - compiles graphs to scripts, routes input
- **Script**: Compiled drawing commands (like assembly for graphics)
- **Driver**: Renders scripts to screen, captures user input

## Your First ViewPort

Let's start by creating a ViewPort and examining what happens:

```elixir
# Start a minimal ViewPort
{:ok, viewport} = Scenic.ViewPort.start([
  name: :learning_viewport,
  size: {400, 300},
  default_scene: MyApp.SimpleScene
])

# Examine the ViewPort struct
IO.inspect(viewport, label: "ViewPort")
# %Scenic.ViewPort{
#   name: :learning_viewport,
#   pid: #PID<0.123.0>, 
#   script_table: #Reference<0.1234.5678>,
#   size: {400, 300}
# }
```

**What just happened?**

1. ViewPort process started and registered itself
2. ETS table created for storing scripts  
3. Default scene process started
4. Scene compiled its initial graph to a script
5. Script stored in ETS table
6. Any connected drivers would be notified

## Understanding Scripts

Let's create a simple script manually to understand what drivers actually receive:

```elixir
alias Scenic.Script

# Create a script manually
my_script = Script.start()
|> Script.push_state()                    # Save graphics state
|> Script.fill_color({255, 0, 0, 255})    # Set red fill
|> Script.translate({50, 50})             # Move origin
|> Script.draw_rect({100, 60})            # Draw rectangle
|> Script.pop_state()                     # Restore state
|> Script.finish()                        # Optimize and finalize

IO.inspect(my_script, label: "Compiled Script")
# [
#   {:push_state},
#   {:fill_color, {:color_rgba, {255, 0, 0, 255}}},
#   {:translate, {50, 50}},
#   {:draw_rect, {100, 60}},
#   {:pop_state}
# ]

# Store it in the ViewPort
{:ok, _} = Scenic.ViewPort.put_script(viewport, "red_box", my_script)
```

**Key Insights:**

- Scripts are lists of simple drawing commands
- They're optimized for fast execution by drivers
- State management (push/pop) prevents style bleeding
- Commands are stateful - order matters

## From Graph to Script

Now let's see how the normal workflow works - graphs compiled to scripts:

```elixir
alias Scenic.Graph
import Scenic.Primitives

# Create a graph (declarative)
graph = Graph.build(font_size: 16)
|> rectangle({100, 60}, fill: :red, translate: {50, 50})
|> text("Hello", translate: {60, 75}, fill: :white)

# Compile it to see what drivers receive
{:ok, compiled_script} = Scenic.Graph.Compiler.compile(graph)
IO.inspect(compiled_script, label: "Graph → Script")

# Store in ViewPort (this is what push_graph does internally)
{:ok, _} = Scenic.ViewPort.put_graph(viewport, "hello_scene", graph)
```

**Compare the Results:**

The compiled graph script will be more complex than our manual script because:
- Font information is included
- Text rendering commands added
- Coordinate calculations optimized
- State management automatically inserted

## Working with the ETS Table

The ViewPort uses ETS tables for high-performance script storage. Let's explore:

```elixir
# Get all script IDs
script_ids = Scenic.ViewPort.all_script_ids(viewport)
IO.inspect(script_ids, label: "All Scripts")

# Retrieve a specific script
{:ok, script} = Scenic.ViewPort.get_script(viewport, "hello_scene")
IO.inspect(length(script), label: "Script command count")

# Examine the ETS table directly (advanced)
table = viewport.script_table
:ets.tab2list(table) |> IO.inspect(label: "Raw ETS contents")
```

**Understanding the Output:**

- Each entry: `{name, script, owner_pid}`
- Scripts owned by the process that created them
- Automatic cleanup when owner crashes

## Input Handling Fundamentals

Let's explore how input flows through the system:

```elixir
# Create a graph with clickable elements
interactive_graph = Graph.build()
|> rectangle({100, 50}, 
    fill: :blue, 
    translate: {50, 50},
    input: [:cursor_button])  # Make it clickable
|> text("Click me", 
    translate: {55, 70}, 
    input: [:cursor_button])  # Also clickable

# Push to ViewPort
{:ok, _} = Scenic.ViewPort.put_graph(viewport, "interactive", interactive_graph)

# Simulate input (what a driver would send)
input_event = {:cursor_button, {:btn_left, 1, [], {75, 65}}}  # Click at (75, 65)
Scenic.ViewPort.input(viewport, input_event)
```

**What happens during input processing:**

1. Driver captures mouse click at global coordinates
2. ViewPort receives input event
3. Hit testing performed against scene hierarchy
4. Coordinates projected to local scene space
5. Event sent to target scene with local coordinates

## Building a Simple Driver

Let's create a minimal driver to see the other side of the equation:

```elixir
defmodule DebugDriver do
  use Scenic.Driver

  def validate_opts(_opts), do: {:ok, []}

  def init(driver, _opts) do
    IO.puts("Driver started!")
    {:ok, driver}
  end

  def update_scene(script_ids, driver) do
    IO.puts("Scripts to render: #{inspect(script_ids)}")
    
    # Get and examine each script
    Enum.each(script_ids, fn id ->
      case Scenic.ViewPort.get_script(driver.viewport, id) do
        {:ok, script} ->
          IO.puts("Script #{id}: #{length(script)} commands")
          # In a real driver, you'd render these commands
        _ ->
          IO.puts("Script #{id}: not found")
      end
    end)
    
    {:ok, driver}
  end

  def request_input(input_types, driver) do
    IO.puts("Input types requested: #{inspect(input_types)}")
    {:ok, driver}
  end
end

# Start the debug driver
{:ok, _driver_pid} = Scenic.ViewPort.start_driver(viewport, [
  module: DebugDriver
])
```

**Watch the Output:**

When you create or update graphs, you'll see the driver receive notifications about which scripts to render.

## Exploring Scene Lifecycle

Let's trace what happens when scenes start and manage their UI:

```elixir
defmodule LearningScene do
  use Scenic.Scene
  alias Scenic.Graph
  import Scenic.Primitives

  def init(scene, _param, _opts) do
    IO.puts("Scene starting: #{inspect(self())}")
    
    # Build initial graph
    graph = Graph.build(font_size: 18)
    |> text("Learning Scene", translate: {10, 30})
    |> rectangle({200, 100}, stroke: {2, :green}, translate: {10, 50})

    # Push to ViewPort (compiles to script)
    scene = push_graph(scene, graph)
    IO.puts("Graph pushed to ViewPort")
    
    # Schedule an update to see change detection
    Process.send_after(self(), :update_text, 2000)
    
    {:ok, assign(scene, counter: 0)}
  end

  def handle_info(:update_text, scene) do
    # Update the graph
    counter = scene.assigns.counter + 1
    
    graph = scene.assigns.graph
    |> Graph.modify(:dynamic_text, &text(&1, "Counter: #{counter}"))
    
    scene = scene
    |> assign(counter: counter)
    |> push_graph(graph)
    
    # Schedule next update
    Process.send_after(self(), :update_text, 1000)
    
    {:noreply, scene}
  end
end

# Set this as the new default scene
Scenic.ViewPort.set_root(viewport, LearningScene)
```

**Observe the Behavior:**

- Scene process starts
- Initial graph compiled and stored
- Updates only trigger script compilation if content changed
- ViewPort coordinates all the communication

## Performance Insights

Let's explore Scenic's performance characteristics:

```elixir
# Measure script compilation time
large_graph = Graph.build()
large_graph = Enum.reduce(1..1000, large_graph, fn i, graph ->
  graph |> rectangle({10, 10}, translate: {rem(i, 50) * 15, div(i, 50) * 15})
end)

{time_us, {:ok, script}} = :timer.tc(fn ->
  Scenic.Graph.Compiler.compile(large_graph)
end)

IO.puts("Compiled #{length(script)} commands in #{time_us}μs")

# Test change detection
{time_us, result} = :timer.tc(fn ->
  Scenic.ViewPort.put_script(viewport, "large_graph", script)
end)
IO.puts("First store took #{time_us}μs, result: #{inspect(result)}")

{time_us, result} = :timer.tc(fn ->
  Scenic.ViewPort.put_script(viewport, "large_graph", script)  # Same script
end)
IO.puts("Second store took #{time_us}μs, result: #{inspect(result)}")
```

**Performance Lessons:**

- Compilation has a cost - cache when possible
- Change detection is very fast
- ETS operations are microsecond-scale
- Large graphs should be broken into reusable pieces

## Debugging Techniques

Here are essential debugging approaches:

```elixir
# 1. Inspect ViewPort state
{:ok, info} = Scenic.ViewPort.info(viewport)
IO.inspect(info)

# 2. List all scripts
script_ids = Scenic.ViewPort.all_script_ids(viewport)
IO.inspect(script_ids)

# 3. Examine a compiled script
{:ok, script} = Scenic.ViewPort.get_script(viewport, "_root_")
IO.inspect(script |> Enum.take(10), label: "First 10 commands")

# 4. Find scenes in the process tree
scenes = Process.list()
|> Enum.filter(fn pid ->
  case Process.info(pid, :dictionary) do
    {:dictionary, dict} -> 
      Keyword.get(dict, :"$initial_call") |> to_string() |> String.contains?("Scene")
    _ -> false
  end
end)
IO.inspect(scenes, label: "Scene processes")

# 5. Monitor script changes
:ets.match(viewport.script_table, {:"$1", :"$2", :"$3"})
|> Enum.each(fn [name, script, owner] ->
  IO.puts("Script: #{name}, Commands: #{length(script)}, Owner: #{inspect(owner)}")
end)
```

## Common Patterns

### Static vs Dynamic Content

```elixir
# Static content - compile once, reuse many times
@background_script Script.start()
|> Script.fill_color({240, 240, 240, 255})
|> Script.draw_rect({800, 600})
|> Script.finish()

def init(scene, _param, _opts) do
  # Push static background
  ViewPort.put_script(scene.viewport, :background, @background_script)
  
  # Dynamic content graph references static script
  graph = Graph.build()
  |> script(:background)  # Reference to static script
  |> text("Dynamic content", id: :dynamic, translate: {10, 10})
  
  scene = push_graph(scene, graph)
  {:ok, scene}
end
```

### Efficient Updates

```elixir
# Only update what changed
def handle_info({:update_status, new_status}, scene) do
  # Modify only the specific element
  graph = scene.assigns.graph
  |> Graph.modify(:status_text, &text(&1, new_status))
  
  scene = push_graph(scene, graph)
  {:noreply, scene}
end
```

## Next Steps

Now that you understand the core architecture:

1. **Explore Driver Development**: Look at `scenic_driver_local` for a real driver implementation
2. **Study Script Commands**: Read the `Scenic.Script` module documentation
3. **Build Complex Scenes**: Create scenes with multiple components
4. **Profile Performance**: Use `:observer` to watch process behavior
5. **Implement Custom Primitives**: Extend Scenic with your own primitive types

## Troubleshooting

**Script not rendering?**
- Check if driver is connected: `ViewPort.all_script_ids(viewport)`
- Verify script compilation: `Graph.Compiler.compile(graph)`
- Ensure ViewPort received the script

**Input not working?**  
- Verify `:input` style is set on primitives
- Check coordinate spaces (global vs local)
- Confirm scene is requesting the input type

**Performance issues?**
- Profile script compilation time
- Break large graphs into smaller pieces
- Use static scripts for unchanging content
- Monitor ETS table size

The key to mastering Scenic is understanding this data flow: `Graph → Script → Driver → Screen` and `Input → ViewPort → Scene`. Everything else builds on these fundamentals.