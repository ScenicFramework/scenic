# Scenic DevTools Guide

## Overview

The new Scenic DevTools provide a unified interface for inspecting and debugging Scenic applications, with a focus on semantic content that supports development, testing, automation, and accessibility.

## Key Improvements

### 1. Unified `inspect_viewport()` Function

The new `inspect_viewport()` replaces both `scene_tree()` and `inspect_app()` with a single, powerful function that provides:

```elixir
# Import the tools
import Scenic.DevTools

# Full inspection (default)
inspect_viewport()

# Options for focused inspection
inspect_viewport(show: :semantic)     # Just semantic content
inspect_viewport(show: :scenes)       # Just scene hierarchy  
inspect_viewport(show: :graphs)       # Just graphs
inspect_viewport(verbose: true)       # Detailed view
inspect_viewport(graph: "abc123")     # Specific graph
```

### 2. Semantic-First Design

The tools are built around the semantic layer, making it easy to:
- Find elements by their semantic type
- Access content directly without parsing visual output
- Build automation and accessibility features

### 3. Generic Semantic Functions

```elixir
# Find elements by type
find(:button)
find(:text_buffer)
find(:menu)

# See what types are in use
types()

# View all semantic content
semantic()

# Get raw data for advanced queries
raw_semantic()
```

### 4. Application-Specific Functions

Text editor applications (like Quillex) extend the DevTools with specialized functions:

```elixir
# Import both modules
import Scenic.DevTools
import Quillex.DevTools

# Text buffer functions (Quillex-specific)
buffers()        # List all text buffers with preview
buffer(1)        # Show full content of buffer by index
buffer("uuid")   # Show buffer by ID
buffer("file.ex") # Show buffer by filename

# Other editor-specific tools
cursor_info()    # Show cursor position and context
selection_info() # Show current selection
buffer_stats()   # Detailed buffer statistics
syntax_info()    # Language/syntax detection
```

## Semantic Annotation Best Practices

### Adding Semantic Data

When building Scenic graphs, add semantic annotations to make elements queryable:

```elixir
@graph Graph.build()
  # Text buffer with semantic info
  |> text(buffer_content, 
      id: :buffer_text,
      semantic: Semantic.text_buffer(buffer_id: buffer.uuid))
  
  # Button with semantic info  
  |> rect({100, 40}, 
      id: :save_button,
      semantic: Semantic.button("Save"))
  
  # Custom semantic data
  |> group(
      semantic: %{
        type: :code_editor,
        language: :elixir,
        file_path: "lib/myfile.ex",
        editable: true
      })
```

### Semantic Helper Functions

The `Scenic.Semantic` module provides helpers for common patterns:

```elixir
Semantic.button("Label")                    # Clickable button
Semantic.text_buffer(buffer_id: id)         # Text editor buffer
Semantic.text_input(name, opts)             # Input field
Semantic.menu(name, opts)                   # Menu container
Semantic.menu_item(label, opts)             # Menu item
Semantic.annotate(type, attrs)              # Generic annotation
```

### Custom Semantic Types

You can create custom semantic types for your application:

```elixir
# In your component
|> rect({100, 100}, 
    semantic: %{
      type: :code_cell,        # Custom type
      language: :elixir,
      cell_id: 42,
      execution_state: :ready
    })

# Query it later
find(:code_cell)
```

## Usage Examples

### During Development

```elixir
iex> import Scenic.DevTools

# Get overview of your app
iex> inspect_viewport()

╔═══ Scenic ViewPort Inspector ═══╗
║ ViewPort: :main_viewport
║ Size: 800×600
║ Root: Elixir.MyApp.Scene.Root
╚═════════════════════════════════╝

🎬 Scene Hierarchy:
─────────────────
🎬 _main_ (RootScene)
├── 📄 editor_1 (EditorScene)
└── 📄 sidebar (SidebarScene)

📊 Graphs & Semantic Content:
────────────────────────────

🏷️  With Semantic Data:
  📋 "abc123..." (scene: editor_1)
     Elements: 3
     📝 text_buffer: 1 buffer
     🔘 button: Save, Cancel

📈 Semantic Summary:
──────────────────
  📝 text_buffer: 1 (1 buffer)
  🔘 button: 2 (Save, Cancel)

💡 Quick Commands:
  • inspect_viewport(show: :semantic)  # Just semantic content
  • find(:button)                      # Find by type
  • types()                            # List all types
  • semantic()                         # All semantic content
```

### Finding Elements

```elixir
iex> find(:button)

🔘 Found 3 button element(s):

Graph "abc123...":
  • "Save"
  • "Cancel"

Graph "def456...":
  • "Submit"
```

### Application-Specific Buffer Access (Quillex)

```elixir
# Import Quillex-specific tools
iex> import Quillex.DevTools

# See all buffers
iex> buffers()

📝 Text Buffers:
[1] Buffer abc12345... (main.ex): "defmodule MyApp do..."
[2] Buffer def67890... (notes.md): "# TODO: implement feature"

# Inspect specific buffer
iex> buffer(1)

📝 Buffer Details:
ID: abc12345-6789-0123-4567-890123456789
File: lib/main.ex
Editable: true

Stats: 25 lines, 89 words, 487 chars
Cursor: Line 5, Column 12

--- Content ---
defmodule MyApp do
  use Application
  
  def start(_type, _args) do
    # ...
  end
end
--- End ---
```

## Application-Specific Extensions

Applications can extend the DevTools with domain-specific functionality:

```elixir
defmodule MyApp.DevTools do
  # Import base DevTools
  import Scenic.DevTools
  
  # Add app-specific tools
  def show_active_document() do
    # Use semantic queries to find active document
    case find(:document) do
      # Custom logic here
    end
  end
  
  def list_open_files() do
    # Query semantic data for file information
    raw_semantic()
    |> extract_file_info()
    |> display_files()
  end
end
```

## Integration with Testing

The DevTools are designed to work seamlessly with testing frameworks:

```elixir
defmodule MyAppTest do
  use ExUnit.Case
  alias Scenic.Semantic.Query
  
  test "save button saves the document" do
    # Start your scene
    {:ok, scene, viewport} = start_scene()
    
    # Use semantic queries
    {:ok, save_button} = Query.get_button_by_label(viewport, "Save")
    {:ok, buffer_text} = Query.get_buffer_text(viewport, buffer_id)
    
    # Simulate interaction
    send_event(scene, {:click, save_button.id})
    
    # Verify results
    assert file_saved?()
  end
end
```

## Tips and Tricks

1. **Use verbose mode for debugging**: `inspect_viewport(verbose: true)` shows additional details

2. **Filter by graph**: `inspect_viewport(graph: "partial_id")` to focus on specific components

3. **Combine with IEx helpers**: The DevTools work great with IEx's autocomplete and history

4. **Add semantic data incrementally**: Start with key interactive elements, add more as needed

5. **Use consistent semantic types**: Stick to common types like `:button`, `:text_buffer`, `:menu` when possible

6. **Include metadata**: Add extra fields like `file_path`, `cursor_position`, `language` to semantic data

## Future Enhancements

The semantic layer and DevTools are designed to support future features:

- **Accessibility**: Screen readers can use semantic data
- **Automation**: UI testing frameworks can find elements reliably  
- **AI Integration**: Language models can understand UI structure
- **Remote Debugging**: Inspect apps running on other devices
- **Time-Travel Debugging**: Record and replay semantic state changes