# API Reference

This reference provides detailed information about Scenic's core APIs, organized by module and use case.

## Scenic.ViewPort

The central coordinator managing scripts, input routing, and driver communication.

### Core Functions

#### `start/1`
```elixir
@spec start(opts :: Keyword.t()) :: {:ok, ViewPort.t()}
```

Start a new ViewPort process.

**Options:**
- `:name` - Process name (optional)
- `:size` - `{width, height}` viewport dimensions (required)
- `:default_scene` - Root scene module or `{module, args}` (required)
- `:theme` - Theme configuration (default: `:dark`)
- `:drivers` - List of driver configurations (default: `[]`)
- `:input_filter` - Input type filter (default: `:all`)

**Example:**
```elixir
{:ok, vp} = ViewPort.start([
  size: {800, 600},
  default_scene: MyApp.MainScene,
  drivers: [[module: Scenic.Driver.Local]]
])
```

#### `put_script/4`
```elixir
@spec put_script(ViewPort.t(), any, Script.t(), Keyword.t()) :: 
  {:ok, any} | :no_change | {:error, atom}
```

Store a compiled script and notify drivers.

**Parameters:**
- `viewport` - ViewPort struct
- `name` - Script identifier (any term)
- `script` - Compiled script (list of commands)
- `opts` - Options (`:owner` pid)

**Returns:**
- `{:ok, name}` - Script stored successfully
- `:no_change` - Identical script, no notification sent
- `{:error, reason}` - Storage error

#### `put_graph/4`
```elixir
@spec put_graph(ViewPort.t(), any, Graph.t(), Keyword.t()) :: 
  {:ok, any} | {:error, atom}
```

Compile graph to script and store in ViewPort.

**Parameters:**
- `viewport` - ViewPort struct
- `name` - Graph/script identifier
- `graph` - Graph to compile
- `opts` - Options (`:owner` pid)

#### `get_script/2`
```elixir
@spec get_script(ViewPort.t(), any) :: {:ok, Script.t()} | {:error, :not_found}
```

Retrieve script by name from ETS table.

#### `input/2`
```elixir
@spec input(ViewPort.t(), ViewPort.Input.t()) :: :ok | {:error, atom}
```

Send input event to ViewPort for processing.

**Input Types:**
- `{:cursor_button, {button, action, mods, {x, y}}}`
- `{:cursor_pos, {x, y}}`
- `{:cursor_scroll, {offset, {x, y}}}`
- `{:key, {key, action, mods}}`
- `{:codepoint, {codepoint, mods}}`

#### `start_driver/2` / `stop_driver/2`
```elixir
@spec start_driver(ViewPort.t(), Keyword.t()) :: {:ok, pid} | :error
@spec stop_driver(ViewPort.t(), pid) :: :ok
```

Dynamic driver management.

### Scene Management

#### `set_root/3`
```elixir
@spec set_root(ViewPort.t(), module, any) :: :ok
```

Change the root scene, stopping current scene hierarchy.

#### `set_theme/2`
```elixir
@spec set_theme(ViewPort.t(), atom | map) :: :ok
```

Update the global theme and restart root scene.

## Scenic.Script

Low-level drawing command creation and manipulation.

### Script Building

#### `start/0`
```elixir
@spec start() :: Script.t()
```

Create empty script for building commands.

#### `finish/1`
```elixir
@spec finish(Script.t()) :: Script.t()
```

Finalize script with optimizations.

### Drawing Commands

#### State Management
```elixir
push_state(script)     # Save graphics state
pop_state(script)      # Restore graphics state
reset_state(script)    # Reset to initial state
```

#### Transforms
```elixir
translate(script, {x, y})          # Move coordinate system
scale(script, {sx, sy})            # Scale coordinate system  
rotate(script, radians)            # Rotate coordinate system
transform(script, matrix)          # Apply matrix transform
```

#### Styling
```elixir
fill_color(script, color)          # Set fill color
stroke_color(script, color)        # Set stroke color
stroke_width(script, width)        # Set line width
font(script, font_name)            # Set font
font_size(script, size)            # Set font size
```

#### Drawing Primitives
```elixir
draw_line(script, {from, to})               # Draw line
draw_rect(script, {width, height})          # Draw rectangle
draw_rrect(script, {w, h}, radius)          # Draw rounded rectangle
draw_circle(script, radius)                 # Draw circle
draw_ellipse(script, {rx, ry})              # Draw ellipse
draw_text(script, text, {x, y})             # Draw text
draw_triangles(script, triangles)           # Draw triangle mesh
draw_sprites(script, sprites)               # Draw image sprites
```

#### Advanced
```elixir
draw_script(script, script_name)            # Reference another script
draw_path(script, path_commands)            # Draw vector path
scissor(script, {x, y, w, h})               # Set clipping rectangle
```

### Color Formats

Colors can be specified as:
- Atoms: `:red`, `:blue`, `:transparent`
- RGB tuples: `{255, 128, 0}`
- RGBA tuples: `{255, 128, 0, 200}`
- Named colors: `{:color_rgb, {255, 128, 0}}`

## Scenic.Driver

Driver interface for rendering and input collection.

### Driver Callbacks

#### Required Callbacks

```elixir
@callback validate_opts(Keyword.t()) :: {:ok, any} | {:error, String.t()}
@callback init(Driver.t(), Keyword.t()) :: {:ok, Driver.t()}
```

#### Optional Callbacks

```elixir
@callback reset_scene(Driver.t()) :: {:ok, Driver.t()}
@callback request_input([Input.class()], Driver.t()) :: {:ok, Driver.t()}
@callback update_scene([Script.id()], Driver.t()) :: {:ok, Driver.t()}
@callback del_scripts([Script.id()], Driver.t()) :: {:ok, Driver.t()}
@callback clear_color(Color.t(), Driver.t()) :: {:ok, Driver.t()}
```

### Driver Helpers

#### Input Sending
```elixir
send_input(driver, input_event)    # Send input to ViewPort
```

#### State Management
```elixir
assign(driver, key, value)         # Assign driver state
get(driver, key, default)          # Get assigned value
set_busy(driver, boolean)          # Set busy flag for batching
```

#### Update Control
```elixir
request_update(driver)             # Request update_scene callback
```

### Input Event Format

#### Mouse/Touch Input
```elixir
{:cursor_button, {button, action, modifiers, {x, y}}}
# button: :btn_left, :btn_right, :btn_middle, :btn_x1, :btn_x2
# action: 0 (release), 1 (press)
# modifiers: [:ctrl, :shift, :alt, :meta]

{:cursor_pos, {x, y}}
{:cursor_scroll, {offset, {x, y}}}
```

#### Keyboard Input
```elixir
{:key, {key, action, modifiers}}
# key: :space, :enter, :escape, :f1, etc.
# action: 0 (release), 1 (press), 2 (repeat)

{:codepoint, {unicode_codepoint, modifiers}}
```

#### System Events
```elixir
{:viewport, {:reshape, {width, height}}}
{:viewport, :close}
```

## Scenic.Graph

Declarative UI description and manipulation.

### Graph Building

#### `build/1`
```elixir
@spec build(opts :: Keyword.t()) :: Graph.t()
```

Create new graph with optional root styles.

**Example:**
```elixir
Graph.build(font: :roboto, font_size: 16, fill: :white)
```

#### Primitive Addition
```elixir
# Import helpers from Scenic.Primitives
import Scenic.Primitives

graph = Graph.build()
|> rectangle({100, 50}, fill: :blue, translate: {10, 20})
|> text("Hello", font_size: 18, translate: {15, 35})
|> circle(25, stroke: {2, :red}, translate: {50, 50})
```

### Graph Modification

#### `modify/3`
```elixir
@spec modify(Graph.t(), id, (Graph.t() -> Graph.t())) :: Graph.t()
```

Modify existing primitive by ID.

**Example:**
```elixir
graph = Graph.build()
|> text("Counter: 0", id: :counter, translate: {10, 20})

# Later update the text
graph = Graph.modify(graph, :counter, &text(&1, "Counter: #{count}"))
```

#### `delete/2`
```elixir
@spec delete(Graph.t(), id) :: Graph.t()
```

Remove primitive by ID.

### Component Integration

#### `add_to_graph/3`
```elixir
# Add component scenes to graphs
graph = Graph.build()
|> MyComponent.add_to_graph(init_data, translate: {100, 100})

# Or using helper functions
import Scenic.Components
graph = Graph.build()
|> button("Click me", id: :my_button, translate: {50, 50})
```

## Input Types Reference

### Positional Input
Requires coordinate transformation and hit testing:
- `:cursor_button` - Mouse clicks/touches
- `:cursor_pos` - Mouse/touch movement
- `:cursor_scroll` - Scroll wheel/gestures

### Non-Positional Input
Sent directly to requesting scenes:
- `:key` - Keyboard key presses
- `:codepoint` - Unicode character input
- `:viewport` - Window/viewport events

### Input Modifiers
Available modifier keys:
- `:ctrl` - Control key
- `:shift` - Shift key
- `:alt` - Alt/Option key
- `:meta` - Windows/Cmd key

### Button Types
Available mouse buttons:
- `:btn_left` - Primary button
- `:btn_right` - Secondary button  
- `:btn_middle` - Middle button/wheel
- `:btn_x1` - Extra button 1
- `:btn_x2` - Extra button 2

## Error Handling

### Common Error Types

#### ViewPort Errors
- `{:error, :invalid_size}` - Invalid viewport dimensions
- `{:error, :invalid_scene}` - Scene module doesn't exist or invalid
- `{:error, :driver_start_failed}` - Driver initialization failed

#### Script Errors
- `{:error, :compilation_failed}` - Graph compilation error
- `{:error, :invalid_script}` - Malformed script commands
- `{:error, :not_found}` - Script doesn't exist

#### Input Errors
- `{:error, :invalid_input}` - Malformed input event
- `{:error, :no_target}` - No scene to receive input

### Error Recovery Patterns

```elixir
# Graceful script compilation
case ViewPort.put_graph(viewport, name, graph) do
  {:ok, _} -> 
    :ok
  {:error, reason} -> 
    Logger.error("Graph compilation failed: #{inspect(reason)}")
    # Use fallback graph or previous version
    ViewPort.put_graph(viewport, name, fallback_graph)
end

# Safe input handling  
case ViewPort.input(viewport, input_event) do
  :ok -> 
    :ok
  {:error, :invalid_input} ->
    Logger.warn("Invalid input ignored: #{inspect(input_event)}")
end
```

## Performance Guidelines

### Script Optimization
- Cache compiled scripts when possible
- Use static scripts for unchanging content
- Break large graphs into smaller, reusable pieces
- Leverage change detection by avoiding unnecessary updates

### Input Efficiency
- Request only needed input types
- Use input capture sparingly
- Implement proper input rate limiting in drivers

### Memory Management
- Clean up script ownership properly
- Avoid creating many small scripts
- Monitor ETS table growth
- Use `:observer` to profile memory usage

This API reference provides the essential interfaces for building Scenic applications. For implementation details and examples, see the other guides in this documentation.