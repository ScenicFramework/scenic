# Input Handling Overview

This guide explains how Scenic routes user input (mouse clicks, keyboard, etc.) to your scenes and components. Understanding this is critical for building interactive UIs that behave correctly when components overlap.

## The Three Input Systems

Scenic has three distinct ways to receive input, each with different behaviors:

| System | Stacking/Occlusion | Use Case |
|--------|-------------------|----------|
| Primitives with `input:` style | Yes - hit-tested, single winner | Normal interactive elements |
| `request_input/2` | No - broadcast to all requesters | Keyboard input, global listeners |
| `capture_input/2` | Exclusive ownership | Dropdowns, modals, drag operations |

### 1. Primitives with `input:` Style (Recommended for Positional Input)

This is the **recommended approach** for handling mouse/cursor input. When you add `input: true` or `input: :cursor_button` to a primitive, Scenic performs hit-testing to determine which primitive was clicked.

```elixir
graph
|> rect({100, 50}, fill: :blue, input: :cursor_button, id: :my_button)
|> rect({100, 50}, fill: :red, input: :cursor_button, id: :overlay, translate: {20, 10})
```

**How it works:**
- Scenic walks primitives in **reverse draw order** (last drawn = first tested)
- The **first primitive** that contains the cursor position "wins"
- Only the owning scene receives the input event
- Overlapping components are handled correctly - the topmost one gets the click

**The input is delivered to `handle_input/3` with context:**

```elixir
def handle_input({:cursor_button, {:btn_left, 1, _, coords}}, context, scene) do
  case context.id do
    :my_button -> handle_button_click(scene)
    :overlay -> handle_overlay_click(scene)
    _ -> {:noreply, scene}
  end
end
```

### 2. `request_input/2` (Broadcast - Use for Non-Positional Input)

When a scene calls `request_input(scene, [:cursor_button])`, it receives **all** input events of that type, regardless of cursor position.

```elixir
def init(scene, _data, _opts) do
  # This scene will receive ALL cursor_button events!
  request_input(scene, [:cursor_button, :key])
  {:ok, scene}
end
```

**Critical behavior:**
- For positional input (cursor_button, cursor_pos, cursor_scroll), **all scenes that requested that input type receive the event**
- There is NO stacking/occlusion check
- The `context.id` will be `nil` if the click wasn't over one of your primitives with `input:` style

**When to use `request_input`:**
- Keyboard input (`:key`, `:codepoint`) - not positional, so broadcast is appropriate
- Global listeners that need to know about ALL clicks (rare)
- Detecting clicks outside your component (though `capture_input` is usually better)

**When NOT to use `request_input`:**
- Normal click handling on interactive elements - use `input:` style instead
- Components that can overlap with other components

### 3. `capture_input/2` (Exclusive - Use for Temporary Modal States)

When a scene calls `capture_input(scene, [:cursor_button])`, it gets **exclusive** ownership of that input type. No other scene receives the input.

```elixir
# When dropdown opens
def handle_input({:cursor_button, {:btn_left, 1, _, _}}, _context, scene) do
  # Open dropdown and capture input
  :ok = capture_input(scene, [:cursor_button, :cursor_pos])
  {:noreply, open_dropdown(scene)}
end

# When dropdown closes
def close_dropdown(scene) do
  :ok = release_input(scene)
  # ...
end
```

**How it works:**
- Captured input completely bypasses hit-testing and request broadcasting
- Only the capturing scene receives the input
- Multiple captures stack - releasing returns to previous capturer
- Use `release_input/1` when done

**When to use `capture_input`:**
- Dropdown menus (to receive clicks outside the menu to close it)
- Modal dialogs
- Drag operations (to track cursor even when it leaves your primitive)
- Any temporary state where you need exclusive input control

## The Dispatch Order

When input arrives, Scenic processes it in this order:

```elixir
def handle_input({input_type, _} = input, state) do
  case Map.fetch(captures, input_type) do
    {:ok, pids} ->
      # 1. CAPTURED: Send only to the capturing process
      do_captured_input(input, pids, state)

    :error ->
      # 2. HIT-TESTED: If positional, find which primitive was hit
      if Enum.member?(input_positional, input_type) do
        do_listed_input(input, state)  # Single winner based on hit-testing
      end

      # 3. REQUESTED: Broadcast to all requesters (runs IN ADDITION to hit-tested!)
      case Map.fetch(requests, input_type) do
        {:ok, pids} -> do_requested_input(input, pids, state)
      end
  end
end
```

**Important:** Steps 2 and 3 both run if there's no capture! This means:
- The hit-tested scene gets the input with a valid `context.id`
- All scenes that requested the input ALSO get it (with `nil` id if not over their primitives)

This is often the source of confusion and bugs when components overlap.

## Best Practices for Components

### DO: Use `input:` style for clickable elements

```elixir
defmodule MyButton do
  use Scenic.Component

  def init(scene, _data, _opts) do
    graph = Graph.build()
    |> rect({100, 40}, fill: :blue, input: :cursor_button, id: :button_bg)
    |> text("Click me", translate: {10, 25})

    scene = push_graph(scene, graph)
    {:ok, scene}
  end

  def handle_input({:cursor_button, {:btn_left, 1, _, _}}, %{id: :button_bg}, scene) do
    # Handle click - we know it was on our button
    send_parent_event(scene, {:clicked, scene.assigns.id})
    {:noreply, scene}
  end

  def handle_input(_, _, scene), do: {:noreply, scene}
end
```

### DO: Use `request_input` only for keyboard input

```elixir
def init(scene, _data, _opts) do
  # Keyboard input is not positional, so request is appropriate
  request_input(scene, [:key])
  {:ok, scene}
end

def handle_input({:key, {:key_enter, 1, _}}, _context, scene) do
  # Handle Enter key
  {:noreply, scene}
end
```

### DO: Use `capture_input` for dropdowns/modals

```elixir
def open_dropdown(scene) do
  # Capture so we get clicks outside the dropdown (to close it)
  :ok = capture_input(scene, [:cursor_button, :cursor_pos])
  # ...
end

def handle_input({:cursor_button, {:btn_left, 1, _, coords}}, _context, scene) do
  if click_outside_dropdown?(coords, scene) do
    close_dropdown(scene)
  else
    handle_dropdown_click(coords, scene)
  end
end

def close_dropdown(scene) do
  :ok = release_input(scene)
  # ...
end
```

### DON'T: Use `request_input` for positional input in components

```elixir
# BAD - Will receive ALL clicks, even those meant for overlapping components
def init(scene, _data, _opts) do
  request_input(scene, [:cursor_button])  # Don't do this!
  {:ok, scene}
end
```

### DON'T: Forget to release captured input

```elixir
# BAD - Input stays captured forever
def handle_escape(scene) do
  # Forgot to release_input!
  {:noreply, close_modal(scene)}
end

# GOOD
def handle_escape(scene) do
  :ok = release_input(scene)
  {:noreply, close_modal(scene)}
end
```

## Forwarding Input from Root Scene

If your root scene needs to forward input to child components, you have two patterns:

### Pattern 1: Let components handle their own input via primitives

This is the preferred approach. Each component uses `input:` style on its primitives and handles its own input. The root scene doesn't need to do anything special.

### Pattern 2: Root scene captures and forwards

For special cases where the root scene needs control:

```elixir
# Root scene
def init(scene, _data, _opts) do
  request_input(scene, [:key])  # Keyboard only at root
  {:ok, scene}
end

def handle_input({:key, _} = input, _context, scene) do
  # Forward to focused component
  case scene.assigns.focused_component do
    nil -> {:noreply, scene}
    pid ->
      send(pid, {:forwarded_input, input})
      {:noreply, scene}
  end
end
```

## Debugging Input Issues

### Check what primitives have `input:` style

```elixir
# In your scene
def debug_input_primitives(graph) do
  Graph.reduce(graph, [], fn primitive, acc ->
    case Primitive.get_style(primitive, :input) do
      nil -> acc
      input_types -> [{Primitive.get_id(primitive), input_types} | acc]
    end
  end)
  |> IO.inspect(label: "Primitives with input")
end
```

### Check what's captured/requested

```elixir
# Check current captures
{:ok, captures} = Scenic.ViewPort.Input.fetch_captures!(viewport)
IO.inspect(captures, label: "Captured inputs")

# Check current requests
{:ok, requests} = Scenic.ViewPort.Input.fetch_requests!(viewport)
IO.inspect(requests, label: "Requested inputs")
```

### Add logging to trace input flow

```elixir
def handle_input(input, context, scene) do
  Logger.debug("Input: #{inspect(input)}, context.id: #{inspect(context.id)}")
  # ...
end
```

## Summary

| Need | Use | Notes |
|------|-----|-------|
| Button clicks | `input: :cursor_button` on primitive | Hit-tested, stacking works |
| Hover effects | `input: :cursor_pos` on primitive | Hit-tested, stacking works |
| Scrolling | `input: :cursor_scroll` on primitive | Hit-tested, stacking works |
| Keyboard input | `request_input(scene, [:key])` | Not positional, broadcast OK |
| Dropdown/Modal | `capture_input` while open | Exclusive, remember to release |
| Drag operation | `capture_input` while dragging | Track cursor even outside primitive |

The key insight: **For positional input in components, always prefer primitives with `input:` style over `request_input`**. This ensures proper stacking/occlusion behavior when components overlap.
