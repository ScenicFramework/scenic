# Scenic Semantic Layer Developer Guide

The Scenic semantic layer provides tools to inspect and query GUI elements by their semantic meaning during development. This guide shows how to use these tools when developing with Flamelex/Quillex.

## Quick Start

### 1. In your IEx session (when running Flamelex)

```elixir
# Import the dev tools
import Scenic.DevTools

# See all semantic info
semantic()

# See all text buffers
buffers()

# See content of buffer 1
buffer(1)

# See all buttons
buttons()

# Find elements by type
find(:menu)
find(:text_input)
```

### 2. Adding Semantic Annotations to Your Components

When building components, add semantic annotations to make them queryable:

```elixir
@graph Graph.build()
  # Text buffer with semantic info
  |> text(buffer_content, 
      id: :buffer_text,
      semantic: Semantic.text_buffer(buffer_id: 1))
  
  # Button with semantic info  
  |> rect({100, 40}, 
      id: :save_button,
      semantic: Semantic.button("Save"))
  
  # Text input field
  |> text("", 
      id: :search_field,
      semantic: Semantic.text_input("search", placeholder: "Search..."))
```

### 3. Visual Semantic Overlay

Add a visual overlay to see semantic information in real-time:

```elixir
defmodule MyApp.Scene.Main do
  use Scenic.Scene
  
  @graph Graph.build()
    |> text("Hello World", semantic: Semantic.text_buffer(buffer_id: 1))
    |> semantic_overlay(viewport: viewport, enabled: false)
  
  # Toggle overlay with keyboard shortcut
  def handle_input({:key, {"S", :meta, _}}, _context, state) do
    # Cmd+S toggles semantic overlay
    cast_children({:semantic_overlay, :toggle})
    {:noreply, state}
  end
end
```

## REPL Commands Reference

### `semantic(viewport_name, graph_key)`
Shows full semantic tree with all elements organized by type.

```elixir
iex> semantic()
=== Semantic Tree for :main ===
Total elements: 5

By type:
  button: 2 elements
    - :save_btn: %{type: :button, label: "Save"}
    - :cancel_btn: %{type: :button, label: "Cancel"}
  text_buffer: 1 element
    - :buffer_1: %{type: :text_buffer, buffer_id: 1}
```

### `buffers()`
Lists all text buffers with content preview.

```elixir
iex> buffers()
Text Buffers:
[1] "def hello do\\n  :world\\nend"
[2] "# TODO: implement feature"
```

### `buffer(id)`
Shows full content of a specific buffer.

```elixir
iex> buffer(1)
Buffer 1:
def hello do
  :world
end
```

### `buttons()`
Lists all buttons with their labels.

```elixir
iex> buttons()
Buttons:
- "Save" (id: :save_btn)
- "Cancel" (id: :cancel_btn)
- "Submit" (id: :submit_btn)
```

### `find(type)`
Find all elements of a specific semantic type.

```elixir
iex> find(:menu)
Found 2 menu element(s):
- :file_menu: %{type: :menu, name: "File", orientation: :vertical}
- :edit_menu: %{type: :menu, name: "Edit", orientation: :vertical}
```

### `types()`
List all semantic types currently in use.

```elixir
iex> types()
Semantic types in use:
- button (3 elements)
- text_buffer (2 elements)
- menu (2 elements)
- text_input (1 element)
```

### `raw_semantic()`
Get the raw semantic data structure for advanced queries.

```elixir
iex> data = raw_semantic()
iex> data.by_type
%{
  button: [:save_btn, :cancel_btn],
  text_buffer: [:buffer_1]
}
```

## Query API for Testing

The semantic layer provides a query API for use in tests:

```elixir
alias Scenic.Semantic.Query

# Get buffer text
{:ok, content} = Query.get_buffer_text(viewport, 1)

# Find button by label
{:ok, button} = Query.get_button_by_label(viewport, "Save")

# Get all editable content
{:ok, editable} = Query.get_editable_content(viewport)

# Find elements with custom filter
{:ok, elem} = Query.find_one(viewport, :text_buffer, fn elem ->
  elem.semantic.buffer_id == 1
end)
```

## Common Semantic Types

The `Scenic.Semantic` module provides helpers for common patterns:

- `Semantic.button(label)` - Clickable buttons
- `Semantic.text_buffer(buffer_id: id)` - Text editor buffers
- `Semantic.text_input(name, opts)` - Input fields
- `Semantic.menu(name, opts)` - Menu containers
- `Semantic.menu_item(label, opts)` - Menu items
- `Semantic.annotate(type, attrs)` - Generic annotations

## Tips for Development

1. **Always add semantic info to interactive elements** - Buttons, inputs, and editable text should have semantic annotations.

2. **Use consistent buffer IDs** - If buffer 1 is your main editor, keep it consistent across sessions.

3. **Toggle overlay with hotkey** - Add a keyboard shortcut to toggle the semantic overlay during development.

4. **Query in tests** - Use `Query` module functions instead of parsing visual output.

5. **Custom semantic types** - Create your own semantic types for domain-specific elements:

```elixir
# Custom semantic annotation
|> rect({100, 100}, 
    semantic: %{
      type: :code_cell,
      language: :elixir,
      cell_id: 42
    })
```

## Debugging Tips

If semantic info isn't showing:

1. Check the element has a `:semantic` option
2. Verify the viewport name (default is `:main_viewport`)
3. Check the graph key (default is `:main`)
4. Use `raw_semantic()` to see all data
5. Ensure the graph was pushed after adding semantic info

## Example: Flamelex Development Session

```elixir
# Start Flamelex
iex -S mix

# Import dev tools
import Scenic.DevTools

# Check what's in the editor
buffers()
# Text Buffers:
# [1] "defmodule MyModule do\\n  def hello, do: :world\\nend"

# Make a change programmatically
Flamelex.Buffer.insert_text(1, "\\n  def goodbye, do: :bye")

# Verify the change
buffer(1)
# Buffer 1:
# defmodule MyModule do
#   def hello, do: :world
#   def goodbye, do: :bye
# end

# See all interactive elements
types()
# Semantic types in use:
# - text_buffer (1 element)
# - button (3 elements)
# - menu (2 elements)
```

This semantic layer makes Flamelex development much more interactive and testable!