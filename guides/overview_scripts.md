# Script Overview

Scenic Scripts are the fundamental rendering data structure that drivers actually interpret and draw. They represent the compiled, optimized form of your scene graphs - essentially a list of low-level drawing commands that can be efficiently processed by rendering systems.

## What is a Script?

A Script is an immutable list of drawing operations that tells a driver exactly what to render. Think of it as "assembly language for graphics" - it's what your high-level scene graphs get compiled down to.

```elixir
# High-level graph
graph = Graph.build()
|> rectangle({100, 50}, fill: :blue, translate: {10, 20})
|> text("Hello", font_size: 16, translate: {15, 35})

# Gets compiled to script (simplified representation)
script = [
  {:push_state},
  {:set_fill, {:color_rgba, {0, 0, 255, 255}}},
  {:translate, {10, 20}},
  {:draw_rect, {100, 50}},
  {:translate, {5, 15}},  # relative to previous
  {:set_font_size, 16},
  {:draw_text, "Hello"},
  {:pop_state}
]
```

## Why Scripts Exist

### Performance Optimization
- **Pre-compilation**: Expensive graph traversal and transformation happens once, not every frame
- **Optimized Commands**: Scripts contain only the minimal operations needed to render
- **Memory Efficiency**: Scripts can be shared between multiple drivers without duplication

### Update Isolation
Scripts enable efficient partial updates:
- **Static Content**: Large, unchanging parts of UI can be pre-compiled to scripts
- **Dynamic Content**: Only the changing parts need recompilation
- **Independent Updates**: Scripts can be updated without affecting graphs that reference them

### Driver Simplification
- **Consistent Interface**: All drivers receive the same script format regardless of source
- **Reduced Complexity**: Drivers don't need to understand graph structures or scene hierarchies
- **Parallel Processing**: Multiple drivers can process the same script simultaneously

## Script Creation Patterns

### Automatic Compilation
Most scripts are created automatically when you push graphs:

```elixir
# In a scene
def init(scene, _param, _opts) do
  graph = Graph.build()
  |> text("Hello World", translate: {100, 100})
  
  scene = push_graph(scene, graph)  # Automatically compiles to script
  {:ok, scene}
end
```

### Manual Script Creation
For advanced use cases, you can create scripts directly:

```elixir
alias Scenic.Script

# Build a reusable script for a complex graphic
checkmark_script = 
  Script.start()
  |> Script.push_state()
  |> Script.stroke_width(3)
  |> Script.stroke_color(:green)
  |> Script.line({{5, 10}, {8, 13}})
  |> Script.line({{8, 13}, {15, 6}})
  |> Script.pop_state()
  |> Script.finish()

# Publish the script
scene = push_script(scene, checkmark_script, "checkmark")

# Reference from a graph
graph = Graph.build()
|> script("checkmark", translate: {50, 50})
```

## Script Commands

Scripts contain a variety of low-level drawing commands:

### State Management
- `push_state` / `pop_state` - Save/restore graphics state
- `reset_state` - Reset to initial state

### Transforms
- `translate` - Move coordinate system
- `scale` - Scale coordinate system  
- `rotate` - Rotate coordinate system
- `transform` - Apply arbitrary matrix transformation

### Styling
- `fill_color` / `stroke_color` - Set colors
- `stroke_width` - Set line width
- `font` / `font_size` - Set text properties
- `scissor` - Set clipping rectangle

### Drawing Operations
- `draw_line` - Draw line segments
- `draw_rect` / `draw_rrect` - Draw rectangles
- `draw_circle` / `draw_ellipse` - Draw circular shapes
- `draw_text` - Render text
- `draw_triangles` - Draw triangle meshes
- `draw_sprites` - Draw image sprites

### Advanced Operations
- `draw_script` - Reference another script (composition)
- `draw_path` - Draw complex vector paths
- `gradient_*` - Set up gradient fills

## Script Lifecycle

### Compilation
1. Scene calls `push_graph(scene, graph)`
2. ViewPort calls `Scenic.Graph.Compiler.compile(graph)`
3. Compiler traverses graph hierarchy depth-first
4. Each primitive contributes its drawing commands
5. Transforms and styles are applied and inherited
6. Result is an optimized command list

### Storage and Distribution
1. Compiled script stored in ViewPort's ETS table
2. Change detection prevents unnecessary updates
3. ViewPort notifies all connected drivers
4. Drivers read script from ETS table concurrently

### Execution
1. Driver reads script from ETS table
2. Driver processes commands sequentially
3. Graphics state maintained during execution
4. Output rendered to screen/file/network

## Performance Considerations

### Script Reuse
Scripts are immutable and can be safely reused:
- Same script can be referenced by multiple graphs
- Scripts can be cached and reused across scene changes
- Complex graphics compiled once, drawn many times

### Memory Management
- Scripts are garbage collected when no longer referenced
- ViewPort cleans up scripts when owning processes crash
- Large scripts can be broken into smaller, reusable pieces

### Update Strategies
- **Full Recompile**: Simple but potentially expensive for large graphs
- **Partial Updates**: Modify scripts surgically for specific changes
- **Script Composition**: Combine static and dynamic scripts

## Error Handling

### Compilation Errors
- Invalid primitives or malformed graphs detected at compile time
- Detailed error messages indicate problematic graph elements
- Scene initialization fails gracefully with clear diagnostics

### Runtime Errors
- Malformed scripts detected when drivers attempt to process them
- Drivers can skip invalid commands and continue processing
- ViewPort monitors driver health and can restart failed drivers

## Advanced Patterns

### Script Templating
Create parameterized scripts for reusable components:

```elixir
def create_button_script(text, width, height) do
  Script.start()
  |> Script.push_state()
  |> Script.fill_color({200, 200, 200, 255})
  |> Script.draw_rrect({width, height}, 5)
  |> Script.fill_color({0, 0, 0, 255})
  |> Script.font_size(14)
  |> Script.text_align(:center)
  |> Script.draw_text(text, {width/2, height/2})
  |> Script.pop_state()
  |> Script.finish()
end
```

### Multi-Layer Composition
Combine multiple scripts for complex graphics:

```elixir
# Background layer - static
background_script = create_background_script()

# Content layer - dynamic 
content_script = create_content_script(data)

# Overlay layer - interactive elements
overlay_script = create_overlay_script()

# Combine in graph
graph = Graph.build()
|> script("background")
|> script("content") 
|> script("overlay")
```

### Performance Profiling
Scripts can be analyzed for optimization opportunities:
- Command count and complexity
- State change frequency
- Redundant operations
- Memory usage patterns

## Related Documentation

- [ViewPort Overview](overview_viewport.html) - How scripts are managed and distributed
- [Driver Overview](overview_driver.html) - How drivers process scripts
- [Graph Overview](overview_graph.html) - The high-level representation that compiles to scripts
- [Primitives Overview](overview_primitives.html) - The building blocks that generate script commands

## Example: Complete Script Workflow

```elixir
defmodule MyApp.Scene.Dashboard do
  use Scenic.Scene
  alias Scenic.{Graph, Script}
  import Scenic.Primitives

  # Static background compiled at module load time
  @background_script Script.start()
    |> Script.fill_color({240, 240, 240, 255})
    |> Script.draw_rect({800, 600})
    |> Script.finish()

  def init(scene, _param, _opts) do
    # Push the static background script
    scene = push_script(scene, @background_script, "background")
    
    # Create dynamic content graph
    graph = Graph.build()
    |> script("background")  # Reference static script
    |> text("Loading...", translate: {50, 50}, id: :status)
    
    scene = push_graph(scene, graph)
    {:ok, scene}
  end
  
  def handle_info({:data_update, data}, scene) do
    # Update only the dynamic parts - background script unchanged
    graph = scene.assigns.graph
    |> Graph.modify(:status, &text(&1, "Data: #{data}"))
    
    scene = push_graph(scene, graph)
    {:noreply, scene}
  end
end
```

Scripts are the bridge between Scenic's high-level declarative API and the low-level rendering systems, providing both performance and flexibility for complex graphical applications.