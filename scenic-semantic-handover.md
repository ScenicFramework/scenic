# Scenic Semantic Layer Implementation Handover

## Context and Goal

We need to add a minimal semantic layer to Scenic that allows test frameworks (particularly spex-driven tests) to query and assert on the meaning/content of GUI elements, not just their visual representation. This is especially important for testing text editors like Quillex/Flamelex where we need to verify buffer contents.

The current problem: Scenic's ViewPort only stores rendering scripts in ETS, making it impossible to query "what text is in buffer 1?" or "which element is the submit button?" during tests.

## Core Implementation Strategy

Add a parallel semantic information system that:
1. Extracts semantic meaning from Graphs during compilation
2. Stores this information alongside rendering scripts
3. Provides simple query APIs for testing

## Files to Modify

### 1. `/lib/scenic/view_port.ex`

**Add semantic table to ViewPort struct:**

```elixir
defstruct [
  # ... existing fields ...
  script_table: nil,
  semantic_table: nil,  # NEW: Add this field
  # ... rest of existing fields ...
]
```

**Modify `init/1` to create semantic table:**

```elixir
def init(opts) do
  # ... existing code ...
  
  # After creating script_table, add:
  semantic_table = :ets.new(:semantic_table, [:set, :public])
  
  # Update struct initialization to include semantic_table
end
```

**Modify `put/4` to build and store semantic info:**

```elixir
def put(%ViewPort{} = vp, graph_key, %Graph{} = graph, opts \\ []) do
  # Existing: compile graph to scripts
  scripts = Graph.compile(graph)
  
  # NEW: Build semantic information
  semantic_info = build_semantic_info(graph, graph_key)
  
  # Store both
  :ets.insert(vp.script_table, {graph_key, scripts})
  :ets.insert(vp.semantic_table, {graph_key, semantic_info})  # NEW
  
  # ... rest of existing implementation ...
end

# NEW: Add this private function
defp build_semantic_info(graph, graph_key) do
  elements = 
    graph.primitives
    |> Enum.reduce(%{}, fn {id, primitive}, acc ->
      # Extract semantic data if present
      if semantic = get_in(primitive, [:opts, :semantic]) do
        element_info = %{
          id: id,
          type: primitive.module,
          semantic: semantic,
          # Extract text content for text primitives
          content: extract_content(primitive),
          # Store transform for position info if needed
          transform: primitive.transforms
        }
        Map.put(acc, id, element_info)
      else
        acc
      end
    end)
  
  %{
    graph_key: graph_key,
    timestamp: System.system_time(:millisecond),
    elements: elements,
    # Quick access indices
    by_type: group_elements_by_semantic_type(elements)
  }
end

defp extract_content(%{module: Scenic.Primitive.Text, data: text}), do: text
defp extract_content(_), do: nil

defp group_elements_by_semantic_type(elements) do
  elements
  |> Enum.reduce(%{}, fn {id, element}, acc ->
    if type = get_in(element, [:semantic, :type]) do
      Map.update(acc, type, [id], &[id | &1])
    else
      acc
    end
  end)
end
```

### 2. Create `/lib/scenic/semantic.ex`

```elixir
defmodule Scenic.Semantic do
  @moduledoc """
  Semantic information helpers for Scenic components.
  
  Provides consistent semantic annotations for testing and accessibility.
  """
  
  @doc """
  Mark an element as a button.
  
  ## Examples
      |> rect({100, 40}, semantic: Scenic.Semantic.button("Submit"))
  """
  def button(label) do
    %{type: :button, label: label, role: :button}
  end
  
  @doc """
  Mark an element as an editable text buffer.
  
  ## Examples
      |> text(content, semantic: Scenic.Semantic.text_buffer(buffer_id: 1))
  """
  def text_buffer(opts) do
    %{
      type: :text_buffer,
      buffer_id: Keyword.fetch!(opts, :buffer_id),
      editable: Keyword.get(opts, :editable, true),
      role: :textbox
    }
  end
  
  @doc """
  Mark an element as a text input field.
  """
  def text_input(name, opts \\ []) do
    %{
      type: :text_input,
      name: name,
      value: Keyword.get(opts, :value),
      placeholder: Keyword.get(opts, :placeholder),
      role: :textbox
    }
  end
  
  @doc """
  Mark an element as a menu.
  """
  def menu(name, opts \\ []) do
    %{
      type: :menu,
      name: name,
      orientation: Keyword.get(opts, :orientation, :vertical),
      role: :menu
    }
  end
  
  @doc """
  Mark an element as a menu item.
  """
  def menu_item(label, opts \\ []) do
    %{
      type: :menu_item,
      label: label,
      parent_menu: Keyword.get(opts, :parent_menu),
      role: :menuitem
    }
  end
  
  @doc """
  Generic semantic annotation.
  """
  def annotate(type, attrs \\ %{}) do
    Map.merge(%{type: type}, attrs)
  end
end
```

### 3. Create `/lib/scenic/semantic/query.ex`

```elixir
defmodule Scenic.Semantic.Query do
  @moduledoc """
  Query API for semantic information in Scenic ViewPorts.
  
  Provides testing-friendly functions to find and inspect GUI elements
  based on their semantic meaning rather than visual properties.
  """
  
  @doc """
  Get semantic information for a graph.
  """
  def get_semantic_info(viewport, graph_key \\ :main) do
    case :ets.lookup(viewport.semantic_table, graph_key) do
      [{^graph_key, info}] -> {:ok, info}
      [] -> {:error, :no_semantic_info}
    end
  end
  
  @doc """
  Find all elements of a specific semantic type.
  
  ## Examples
      Query.find_by_type(viewport, :button)
      Query.find_by_type(viewport, :text_buffer)
  """
  def find_by_type(viewport, type, graph_key \\ :main) do
    with {:ok, info} <- get_semantic_info(viewport, graph_key) do
      ids = get_in(info, [:by_type, type]) || []
      elements = Enum.map(ids, &Map.get(info.elements, &1))
      {:ok, elements}
    end
  end
  
  @doc """
  Find a single element by semantic type and additional filter.
  
  ## Examples
      Query.find_one(viewport, :text_buffer, fn elem -> 
        elem.semantic.buffer_id == 1 
      end)
  """
  def find_one(viewport, type, filter_fn, graph_key \\ :main) do
    with {:ok, elements} <- find_by_type(viewport, type, graph_key) do
      case Enum.find(elements, filter_fn) do
        nil -> {:error, :not_found}
        element -> {:ok, element}
      end
    end
  end
  
  @doc """
  Get text content from a text buffer by buffer_id.
  """
  def get_buffer_text(viewport, buffer_id, graph_key \\ :main) do
    with {:ok, buffer} <- find_one(viewport, :text_buffer, fn elem ->
           elem.semantic.buffer_id == buffer_id
         end, graph_key) do
      {:ok, buffer.content || ""}
    end
  end
  
  @doc """
  Find all buttons in the viewport.
  """
  def get_buttons(viewport, graph_key \\ :main) do
    find_by_type(viewport, :button, graph_key)
  end
  
  @doc """
  Find button by label.
  """
  def get_button_by_label(viewport, label, graph_key \\ :main) do
    find_one(viewport, :button, fn elem ->
      elem.semantic.label == label
    end, graph_key)
  end
  
  @doc """
  Get all editable text content.
  """
  def get_editable_content(viewport, graph_key \\ :main) do
    with {:ok, info} <- get_semantic_info(viewport, graph_key) do
      editable = 
        info.elements
        |> Map.values()
        |> Enum.filter(fn elem ->
          get_in(elem, [:semantic, :editable]) == true
        end)
        |> Enum.map(fn elem ->
          %{
            id: elem.id,
            type: elem.semantic.type,
            content: elem.content,
            buffer_id: elem.semantic[:buffer_id]
          }
        end)
      {:ok, editable}
    end
  end
  
  @doc """
  Debug helper - print all semantic elements.
  """
  def inspect_semantic_tree(viewport, graph_key \\ :main) do
    with {:ok, info} <- get_semantic_info(viewport, graph_key) do
      IO.puts("=== Semantic Tree for #{graph_key} ===")
      IO.puts("Total elements: #{map_size(info.elements)}")
      IO.puts("\nBy type:")
      
      Enum.each(info.by_type, fn {type, ids} ->
        IO.puts("  #{type}: #{length(ids)} elements")
        Enum.each(ids, fn id ->
          elem = Map.get(info.elements, id)
          IO.puts("    - #{id}: #{inspect(elem.semantic)}")
        end)
      end)
      
      :ok
    end
  end
end
```

### 4. Update `/lib/scenic/graph.ex`

We need to ensure semantic options are preserved through graph operations. Look for the `add/4` function and similar primitive-adding functions. Make sure `:semantic` is included in allowed options.

This might already work if Scenic passes through all options, but verify that semantic options aren't stripped during graph compilation.

## Testing the Implementation

### 1. Create a test file `test/scenic/semantic_test.exs`:

```elixir
defmodule Scenic.SemanticTest do
  use ExUnit.Case
  alias Scenic.{ViewPort, Graph, Semantic}
  alias Scenic.Semantic.Query
  
  setup do
    {:ok, viewport} = ViewPort.start_link(name: :semantic_test_vp)
    {:ok, viewport: viewport}
  end
  
  test "semantic info is stored when graph is put", %{viewport: viewport} do
    graph = 
      Graph.build()
      |> Scenic.Primitives.rect({100, 40}, semantic: Semantic.button("Click me"))
      |> Scenic.Primitives.text("Click me", semantic: %{type: :label, for: :button})
    
    ViewPort.put(viewport, :test_graph, graph)
    
    assert {:ok, info} = Query.get_semantic_info(viewport, :test_graph)
    assert map_size(info.elements) == 2
    assert info.by_type.button != nil
  end
  
  test "can query buttons by label", %{viewport: viewport} do
    graph = 
      Graph.build()
      |> Scenic.Primitives.rect({100, 40}, semantic: Semantic.button("Submit"))
      |> Scenic.Primitives.rect({100, 40}, semantic: Semantic.button("Cancel"))
    
    ViewPort.put(viewport, graph)
    
    assert {:ok, submit_btn} = Query.get_button_by_label(viewport, "Submit")
    assert submit_btn.semantic.label == "Submit"
    
    assert {:ok, buttons} = Query.get_buttons(viewport)
    assert length(buttons) == 2
  end
  
  test "can query text buffer content", %{viewport: viewport} do
    buffer_content = "Hello, World!"
    
    graph = 
      Graph.build()
      |> Scenic.Primitives.text(buffer_content, 
           semantic: Semantic.text_buffer(buffer_id: 1))
    
    ViewPort.put(viewport, graph)
    
    assert {:ok, ^buffer_content} = Query.get_buffer_text(viewport, 1)
  end
end
```

### 2. Integration test with actual Flamelex/Quillex component:

```elixir
# In your text editor test
test "can read buffer content through semantic layer" do
  # Setup your editor component
  {:ok, scene} = MyEditor.start_link(viewport: viewport)
  
  # Type some text (using your existing input simulation)
  Scene.cast(scene, {:input, "Hello semantic world"})
  
  # Query through semantic API
  assert {:ok, "Hello semantic world"} = Query.get_buffer_text(viewport, 1)
end
```

## Migration Guide for Existing Components

To add semantic information to existing Quillex/Flamelex components:

```elixir
# Before: 
@graph Graph.build()
  |> text(buffer.content, id: :buffer_text)

# After:
@graph Graph.build()
  |> text(buffer.content, 
      id: :buffer_text,
      semantic: Semantic.text_buffer(buffer_id: buffer.id))

# For buttons:
# Before:
|> rect(button_size, id: :save_button)
|> text("Save", id: :save_label)

# After:
|> rect(button_size, id: :save_button, semantic: Semantic.button("Save"))
|> text("Save", id: :save_label)
```

## Success Criteria

1. Can query buffer text content in tests without parsing viewport scripts
2. Can find and identify buttons by their labels
3. Zero performance impact on non-semantic components
4. Existing Scenic apps continue working without modification
5. Simple API that's intuitive for test writers

## Next Steps After Basic Implementation

Once the basic implementation is working:

1. Add semantic info to Quillex BufferPane component
2. Update comprehensive_text_editing_spex.exs to use semantic queries
3. Document common semantic patterns
4. Consider adding semantic info to ScriptInspector for backwards compatibility

## Implementation Order

1. Start with ViewPort.ex changes
2. Create Semantic module with helper functions
3. Create Query module for testing
4. Write tests to verify it works
5. Update one Quillex component as proof of concept
6. Update spex tests to use new Query API

The goal is a working proof of concept that can query buffer text within 1-2 days, then iterate based on real usage.