# Scenic Semantic DOM

This document describes the semantic DOM system added to Scenic, which enables testing and development tools to query GUI elements by their semantic meaning rather than visual properties.

## Overview

The semantic DOM provides a parallel data structure alongside Scenic's rendering pipeline that stores metadata about GUI elements. This allows tools to:

- Query elements by type (button, text_buffer, menu, etc.)
- Access element properties without parsing visual output
- Build testing frameworks that understand GUI semantics
- Create developer tools for inspecting running applications

## Architecture

### Core Components

1. **ViewPort Enhancement** (`lib/scenic/view_port.ex`)
   - Added `semantic_table` ETS table to store semantic data per graph
   - Added `get_semantic/2` and `inspect_semantic/2` functions
   - Semantic data is stored alongside script data

2. **Semantic Helper Module** (`lib/scenic/semantic.ex`)
   - Provides convenience functions for creating semantic annotations
   - Common patterns: `text_buffer/1`, `button/1`, `menu/1`, etc.

3. **Query API** (`lib/scenic/semantic/query.ex`)
   - Functions to query semantic data: `find_by_type/3`, `get_buffer_text/3`, etc.
   - Returns semantic elements with their properties and content

4. **Developer Tools** (`lib/scenic/dev_tools.ex`)
   - Generic tools for any Scenic application
   - Scene hierarchy visualization
   - Graph inspection
   - Semantic element queries

## Usage

### Adding Semantic Annotations

When building graphs, add semantic metadata to primitives:

```elixir
@graph Graph.build()
|> text("Hello World", 
    id: :my_text,
    semantic: Semantic.text_buffer(buffer_id: "buffer_1"))
|> rect({100, 40}, 
    id: :save_btn,
    semantic: Semantic.button("Save"))
```

### Querying Semantic Data

In tests or development tools:

```elixir
# Find all buttons
{:ok, buttons} = Semantic.Query.find_by_type(viewport, :button)

# Get text buffer content
{:ok, content} = Semantic.Query.get_buffer_text(viewport, "buffer_1")

# Use developer tools
import Scenic.DevTools
scene_tree()        # Show scene hierarchy
semantic_summary()  # Show all semantic elements
find_semantic(:button)  # Find elements by type
```

### Application-Specific Tools

Applications can build their own semantic tools on top of the generic ones:

```elixir
defmodule MyApp.DevTools do
  # Use Scenic's generic tools
  alias Scenic.DevTools
  
  # Add app-specific functionality
  def show_active_document() do
    # Custom logic using semantic queries
  end
end
```

## Semantic Types

Common semantic types include:

- `:text_buffer` - Text editing areas
- `:button` - Clickable buttons
- `:menu` - Menu items or menu bars
- `:text_input` - Single-line text inputs
- `:list` - List containers
- `:list_item` - Individual list items

Applications can define custom semantic types as needed.

## Best Practices

1. **Always add semantic data to interactive elements** - Buttons, inputs, menus should have semantic annotations

2. **Use consistent IDs** - Buffer IDs, element IDs should be stable across renders

3. **Include relevant metadata** - Add properties that tests might need (editable, role, file_path, etc.)

4. **Keep semantic data lightweight** - Don't duplicate large content, reference it

5. **Update semantic data with content** - When text changes, update the semantic content

## Integration with Testing

The semantic DOM enables powerful testing patterns:

```elixir
# In a test
test "clicking save button saves the document" do
  # Start your scene
  {:ok, scene} = MyScene.start_link()
  
  # Query semantic elements
  {:ok, save_button} = find_one(viewport, :button, fn b -> 
    b.semantic.label == "Save" 
  end)
  
  # Simulate interaction
  send_event(scene, {:click, save_button.id})
  
  # Verify results via semantic queries
  {:ok, content} = get_buffer_text(viewport, "main_buffer")
  assert content == "Expected content"
end
```

## Future Enhancements

Potential future improvements:

- Automatic semantic annotation inference
- Semantic change notifications
- Integration with accessibility tools
- Cross-graph semantic relationships
- Semantic-based event routing