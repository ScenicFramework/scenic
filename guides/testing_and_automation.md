# Testing and Automation

Scenic includes a semantic element registration system that enables automated testing and AI-driven interaction with your applications. Similar to how Playwright and Puppeteer work with web browsers, Scenic's semantic system lets you find and interact with UI elements by ID rather than hardcoded screen coordinates.

## Why Semantic Registration?

Traditional GUI testing requires knowing exact pixel coordinates to click buttons or interact with elements. This is fragile and breaks when layouts change. Semantic registration solves this by:

- **Finding elements by ID** - Just like `document.getElementById()` in web development
- **Automatic bounds calculation** - No need to track where elements are on screen
- **Resilient to layout changes** - Element IDs stay stable even if positions change
- **AI automation ready** - Enables tools like MCP (Model Context Protocol) to control your app

## Quick Start

### 1. Add IDs to Your Elements

Simply add an `:id` option to any primitive you want to interact with:

```elixir
@graph Graph.build()
  |> text("Click Me", id: :save_button, translate: {100, 50})
  |> rectangle({200, 40}, id: :input_field, translate: {100, 100})
  |> circle(25, id: :status_indicator, translate: {50, 50})
```

That's it! Any primitive with an `:id` is automatically registered in the semantic system.

### 2. Query Elements

Use the `Scenic.ViewPort.Semantic` module to find and interact with elements:

```elixir
# Get viewport
{:ok, viewport} = Scenic.ViewPort.info(:main_viewport)

# Find element by ID
{:ok, button} = Scenic.ViewPort.Semantic.find_element(viewport, :save_button)

# See what you got
IO.inspect(button)
#=> %Scenic.Semantic.Compiler.Entry{
#     id: :save_button,
#     type: :text,
#     label: "Click Me",
#     local_bounds: %{left: 0, top: 0, width: 100, height: 20},
#     screen_bounds: %{left: 100, top: 50, width: 100, height: 20},
#     clickable: false,
#     ...
#   }
```

### 3. Click Elements by ID

The most powerful feature - click elements without knowing their coordinates:

```elixir
# Click the save button (calculates center point automatically)
{:ok, {x, y}} = Scenic.ViewPort.Semantic.click_element(viewport, :save_button)
#=> {:ok, {150.0, 60.0}}
```

This finds the element, calculates its center point, and sends mouse click events through the driver - just like a real user clicking!

## Advanced Queries

### Find All Clickable Elements

```elixir
{:ok, elements} = Scenic.ViewPort.Semantic.find_clickable_elements(viewport)

# Filter by type
{:ok, buttons} = Scenic.ViewPort.Semantic.find_clickable_elements(
  viewport,
  %{type: :component}
)

# Filter by label text
{:ok, save_buttons} = Scenic.ViewPort.Semantic.find_clickable_elements(
  viewport,
  %{label: "Save"}
)
```

### Find Element at Coordinates

```elixir
# What's at this screen position?
{:ok, element} = Scenic.ViewPort.Semantic.element_at_point(viewport, 150, 60)
```

### Get Hierarchical Tree

```elixir
# Get full semantic tree starting from root
{:ok, tree} = Scenic.ViewPort.Semantic.get_semantic_tree(viewport)

# Get subtree from specific element
{:ok, subtree} = Scenic.ViewPort.Semantic.get_semantic_tree(viewport, :my_group)
```

## Explicit Semantic Metadata

For more control, add explicit semantic metadata to any primitive:

```elixir
@graph Graph.build()
  |> rectangle(
    {100, 50},
    semantic: %{
      id: :custom_button,
      type: :button,
      clickable: true,
      focusable: true,
      label: "Save File",
      role: :primary_action,
      bounds: %{left: 0, top: 0, width: 100, height: 50}
    }
  )
```

Available semantic fields:

- `:id` - Element identifier (atom or string)
- `:type` - Semantic type (`:button`, `:input`, `:checkbox`, etc.)
- `:clickable` - Whether element responds to clicks (boolean)
- `:focusable` - Whether element can receive focus (boolean)
- `:label` - Human-readable label (string)
- `:role` - Semantic role (`:primary_action`, `:navigation`, etc.)
- `:bounds` - Custom bounds if auto-calculation doesn't work

## Components and Groups

Groups and components with IDs are also registered:

```elixir
@graph Graph.build()
  |> group(
    fn g ->
      g
      |> rectangle({200, 100}, id: :dialog_background)
      |> text("Are you sure?", id: :dialog_message)
      |> rectangle({80, 30}, id: :ok_button)
      |> rectangle({80, 30}, id: :cancel_button)
    end,
    id: :confirmation_dialog,
    translate: {100, 100}
  )
```

Now you can query the dialog and all its children:

```elixir
{:ok, dialog} = Scenic.ViewPort.Semantic.find_element(viewport, :confirmation_dialog)
{:ok, ok_btn} = Scenic.ViewPort.Semantic.find_element(viewport, :ok_button)

# Dialog's parent_id is nil, ok_button's parent_id is :confirmation_dialog
```

## Configuration

Semantic registration is enabled by default. To disable it:

```elixir
# In your viewport config
ViewPort.start_link(
  name: :main_viewport,
  size: {800, 600},
  semantic_registration: false,  # Disable semantic system
  # ... other opts
)
```

## Performance

The semantic system is designed for zero performance impact:

- **Parallel compilation** - Semantic compilation runs asynchronously, never blocking rendering
- **ETS tables** - Fast in-memory lookups with read concurrency
- **Fire-and-forget** - No messages sent back to scenes
- **Lazy updates** - Only compiles when graphs change

When disabled via config, there is literally zero overhead - the ETS tables aren't even created.

## Testing Patterns

### Integration Tests

```elixir
defmodule MyApp.IntegrationTest do
  use ExUnit.Case

  test "user can save document" do
    # Start app
    start_supervised!(MyApp.Application)

    # Get viewport
    {:ok, vp} = Scenic.ViewPort.info(:main_viewport)

    # Interact with UI
    {:ok, _} = Scenic.ViewPort.Semantic.click_element(vp, :new_document_button)
    Process.sleep(100)

    # Type some content (you'll need to send input through driver)
    # ...

    {:ok, _} = Scenic.ViewPort.Semantic.click_element(vp, :save_button)
    Process.sleep(100)

    # Verify document was saved
    assert File.exists?("test_doc.txt")
  end
end
```

### AI Automation with MCP

The semantic system integrates with Model Context Protocol (MCP) to enable AI agents to control your application:

```typescript
// In MCP server
async function findClickableElements() {
  const viewport = await getViewport();
  const elements = await Scenic.ViewPort.Semantic.find_clickable_elements(viewport);
  return elements;
}

async function clickElement(elementId: string) {
  const viewport = await getViewport();
  const coords = await Scenic.ViewPort.Semantic.click_element(viewport, elementId);
  return coords;
}
```

This enables natural language commands like:
- "Click the save button"
- "Show me all clickable elements"
- "Find the status indicator"

## Current Limitations (Phase 1)

The current implementation is Phase 1 of a multi-phase rollout:

- ✅ **Automatic registration** - Elements with IDs auto-register
- ✅ **Query by ID** - Find elements quickly
- ✅ **Click by ID** - Interact without coordinates
- ✅ **Basic bounds** - Simple rectangles, circles, text
- ⚠️  **No transform calculations** - `screen_bounds` equals `local_bounds` (no translate/rotate/scale applied)
- ⚠️  **No component sub-scenes** - Components register, but not their internal graphs
- ⚠️  **Text bounds are estimates** - No font metrics yet (fixed 100x20)

Future phases will add:
- **Phase 2**: Transform-aware coordinate calculation
- **Phase 3**: Component sub-scene handling
- **Phase 4**: Advanced features (visibility, filters, performance optimizations)

## Entry Struct Reference

When you query an element, you get a `Scenic.Semantic.Compiler.Entry` struct:

```elixir
%Scenic.Semantic.Compiler.Entry{
  id: :my_button,                    # Element ID
  type: :rect,                       # Primitive type
  module: Scenic.Primitive.Rectangle, # Primitive module
  parent_id: :my_group,              # Parent element ID (or nil)
  children: [],                      # Child element IDs
  local_bounds: %{                   # Bounds in local coordinates
    left: 0,
    top: 0,
    width: 100,
    height: 50
  },
  screen_bounds: %{                  # Bounds in screen coordinates (Phase 1: same as local)
    left: 0,
    top: 0,
    width: 100,
    height: 50
  },
  clickable: false,                  # Can be clicked
  focusable: false,                  # Can receive focus
  label: nil,                        # Human-readable label
  role: nil,                         # Semantic role
  value: {100, 50},                  # Primitive data (dimensions, text, etc.)
  hidden: false,                     # Whether element is hidden
  z_index: 0                         # Depth order (higher = on top)
}
```

## Best Practices

### 1. Use Descriptive IDs

```elixir
# Good
id: :save_document_button
id: :email_input_field
id: :user_profile_avatar

# Avoid
id: :button1
id: :rect_a
id: :thing
```

### 2. Add IDs to Interactive Elements

Focus on elements users interact with:
- Buttons
- Input fields
- Checkboxes
- List items
- Dialogs

### 3. Use Groups for Complex UIs

```elixir
@graph Graph.build()
  |> group(
    fn g ->
      g
      |> text("Name:", id: :name_label)
      |> rectangle({200, 30}, id: :name_input)
    end,
    id: :name_field_group
  )
```

### 4. Leverage Semantic Metadata for Custom Components

```elixir
defmodule MyApp.Component.CustomButton do
  # ...

  def init(scene, {text, opts}, _) do
    graph =
      Graph.build()
      |> rounded_rectangle(
        {100, 40, 5},
        id: opts[:id],
        semantic: %{
          type: :button,
          clickable: true,
          label: text,
          role: opts[:role] || :action
        }
      )

    scene = push_graph(scene, graph)
    {:ok, scene}
  end
end
```

## What to Read Next?

- [ViewPort Overview](overview_viewport.html) - Understand the ViewPort architecture
- [Graph Overview](overview_graph.html) - Learn about scene graphs
- [Scenic MCP Documentation](../scenic_mcp/README.md) - AI automation integration
