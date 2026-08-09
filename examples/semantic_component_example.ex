defmodule SemanticComponentExample do
  @moduledoc """
  Example showing best practices for adding semantic annotations to Scenic components.
  
  This example demonstrates:
  - How to add semantic data to primitives
  - Using the Semantic helper module
  - Creating custom semantic types
  - Making components testable and accessible
  """
  
  use Scenic.Component
  import Scenic.Primitives
  import Scenic.Components
  alias Scenic.Graph
  alias Scenic.Semantic
  
  @impl Scenic.Component
  def validate(data), do: {:ok, data}
  
  @impl Scenic.Component
  def init(data, opts) do
    # Build a graph with comprehensive semantic annotations
    graph = build_graph(data)
    
    state = %{
      graph: graph,
      data: data,
      buffer_content: "Hello, Scenic!",
      selected_item: nil
    }
    
    {:ok, state, push: graph}
  end
  
  defp build_graph(_data) do
    Graph.build()
    # Header with semantic menu annotation
    |> group(fn g ->
      g
      |> rect({800, 40}, fill: :light_gray, semantic: Semantic.menu("main_menu", orientation: :horizontal))
      |> text("File", translate: {10, 25}, semantic: Semantic.menu_item("File", parent_menu: "main_menu"))
      |> text("Edit", translate: {60, 25}, semantic: Semantic.menu_item("Edit", parent_menu: "main_menu"))
      |> text("View", translate: {110, 25}, semantic: Semantic.menu_item("View", parent_menu: "main_menu"))
    end)
    
    # Main editor area with text buffer semantic
    |> group(fn g ->
      g
      |> rect({800, 400}, translate: {0, 40}, fill: :white, stroke: {1, :gray})
      |> text("Hello, Scenic!", 
          translate: {10, 60},
          id: :main_buffer,
          semantic: Semantic.text_buffer(
            buffer_id: "main_editor_buffer",
            editable: true
          ))
    end, translate: {0, 0})
    
    # Toolbar with semantic buttons
    |> group(fn g ->
      g
      |> button("Save", 
          id: :save_btn,
          translate: {10, 450},
          semantic: Semantic.button("Save"))
      |> button("Cancel", 
          id: :cancel_btn,
          translate: {80, 450},
          semantic: Semantic.button("Cancel"))
      |> button("Run", 
          id: :run_btn,
          translate: {170, 450},
          semantic: %{
            type: :button,
            label: "Run",
            action: :execute_code,
            shortcut: "Cmd+R"
          })
    end)
    
    # Sidebar with custom semantic type
    |> group(fn g ->
      g
      |> rect({200, 400}, translate: {600, 40}, fill: :light_blue)
      |> text("Files", translate: {610, 60}, font_size: 16)
      |> group(fn g ->
        g
        |> text("• main.ex", translate: {610, 90}, 
            id: :file_1,
            semantic: %{
              type: :file_item,
              path: "lib/main.ex",
              file_type: :elixir,
              selectable: true
            })
        |> text("• test.ex", translate: {610, 110},
            id: :file_2,
            semantic: %{
              type: :file_item,
              path: "test/test.ex", 
              file_type: :elixir,
              selectable: true
            })
      end)
    end, semantic: %{
      type: :file_browser,
      role: :navigation,
      label: "Project Files"
    })
    
    # Status bar with semantic info
    |> group(fn g ->
      g
      |> rect({800, 30}, translate: {0, 570}, fill: :dark_gray)
      |> text("Ready", 
          translate: {10, 590}, 
          fill: :white,
          semantic: %{
            type: :status_text,
            live: true,
            updates: :frequently
          })
      |> text("Line 1, Col 1", 
          translate: {700, 590}, 
          fill: :white,
          semantic: %{
            type: :cursor_position,
            line: 1,
            column: 1
          })
    end, semantic: Semantic.annotate(:status_bar))
    
    # Search input with semantic annotation
    |> text_input("",
        id: :search_input,
        translate: {300, 10},
        width: 200,
        hint: "Search...",
        semantic: Semantic.text_input("search", 
          placeholder: "Search files and symbols",
          shortcut: "Cmd+F"
        ))
  end
  
  # Event handlers that could update semantic data
  @impl Scenic.Component
  def handle_event({:click, :save_btn}, _context, state) do
    # Update status with semantic info
    new_graph = state.graph
      |> Graph.modify(:status_text, fn p ->
        # Update both visual and semantic
        p 
        |> text("Saving...")
        |> update_opts(semantic: %{
          type: :status_text,
          state: :saving,
          live: true
        })
      end)
    
    {:noreply, %{state | graph: new_graph}, push: new_graph}
  end
  
  def handle_event({:click, {:file_item, path}}, _context, state) do
    # Update selection state semantically
    new_graph = state.graph
      |> Graph.modify(:file_browser, fn p ->
        p |> update_opts(semantic: %{
          type: :file_browser,
          selected_file: path,
          role: :navigation
        })
      end)
    
    {:noreply, %{state | graph: new_graph, selected_item: path}, push: new_graph}
  end
  
  def handle_event(_event, _context, state) do
    {:noreply, state}
  end
  
  @impl Scenic.Component
  def handle_info({:buffer_changed, new_content}, state) do
    # Update buffer content and semantic data
    new_graph = state.graph
      |> Graph.modify(:main_buffer, fn p ->
        p 
        |> text(new_content)
        |> update_opts(semantic: Semantic.text_buffer(
            buffer_id: "main_editor_buffer",
            editable: true,
            modified: true,
            content_hash: :erlang.phash2(new_content)
          ))
      end)
    
    {:noreply, %{state | graph: new_graph, buffer_content: new_content}, push: new_graph}
  end
  
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

defmodule SemanticComponentExample.Test do
  @moduledoc """
  Example test showing how to use semantic queries with the component.
  """
  
  def demo_semantic_queries() do
    # This would be in a real test
    viewport = :main_viewport
    
    # Import the dev tools
    import Scenic.DevTools
    
    IO.puts("\n=== Semantic Component Example ===\n")
    
    # Find all buttons
    IO.puts("Finding all buttons:")
    find(:button)
    
    # Find custom semantic types
    IO.puts("\nFinding file items:")
    find(:file_item)
    
    # Inspect the whole viewport
    IO.puts("\nFull inspection:")
    inspect_viewport()
    
    # Get raw semantic data for advanced queries
    IO.puts("\nRaw semantic data for custom queries:")
    data = raw_semantic()
    
    # Custom query example
    file_items = for {_graph_key, graph_data} <- data,
                     {_id, element} <- graph_data.elements,
                     element.semantic.type == :file_item,
                     do: element.semantic
    
    IO.puts("Found #{length(file_items)} file items")
    Enum.each(file_items, fn item ->
      IO.puts("  - #{item.path} (#{item.file_type})")
    end)
  end
end