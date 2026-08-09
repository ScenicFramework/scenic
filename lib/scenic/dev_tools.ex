defmodule Scenic.DevTools do
  @moduledoc """
  Developer tools for inspecting Scenic applications during development.
  
  This module provides a unified interface for understanding the structure,
  state, and semantic content of Scenic applications. It's designed for
  development, testing, automation, and accessibility.
  
  ## Quick Start
  
      iex> import Scenic.DevTools
      iex> inspect_viewport()      # The main inspection function
  
  ## Other Tools
  
      iex> semantic()              # Just semantic content  
      iex> buffers()               # Text buffer shortcuts
      iex> find(:button)           # Find elements by type
  """
  
  alias Scenic.ViewPort
  
  @doc """
  The primary inspection function for Scenic applications.
  
  Provides a unified view of:
  - ViewPort configuration
  - Scene hierarchy with relationships
  - Graphs with their semantic content
  - Interactive elements summary
  
  This replaces both scene_tree() and inspect_app() with a cleaner,
  more informative display.
  
  ## Options
  
    * `:viewport` - ViewPort name or pid (default: `:main_viewport`)
    * `:graph` - Specific graph to inspect (default: all graphs)
    * `:show` - What to display: `:all`, `:scenes`, `:semantic`, `:graphs`
    * `:verbose` - Show additional details (default: false)
  
  ## Examples
  
      # Default view - everything
      iex> inspect_viewport()
      
      # Just semantic content
      iex> inspect_viewport(show: :semantic)
      
      # Specific graph with details
      iex> inspect_viewport(graph: "abc123", verbose: true)
      
      # Different viewport
      iex> inspect_viewport(viewport: :secondary)
  """
  def inspect_viewport(opts \\ []) do
    viewport_name = Keyword.get(opts, :viewport, :main_viewport)
    show = Keyword.get(opts, :show, :all)
    graph_filter = Keyword.get(opts, :graph)
    verbose = Keyword.get(opts, :verbose, false)
    
    with {:ok, viewport} <- get_viewport(viewport_name) do
      IO.puts("\n╔═══ Scenic ViewPort Inspector ═══╗")
      IO.puts("║ ViewPort: #{inspect(viewport_name)}")
      IO.puts("║ Size: #{format_size(viewport.size)}")
      IO.puts("╚═════════════════════════════════╝\n")
      
      case show do
        :all ->
          show_hierarchy_if_available(viewport)
          show_graphs_with_semantic(viewport, graph_filter, verbose)
          show_semantic_summary(viewport)
          
        :hierarchy ->
          show_hierarchy_if_available(viewport)
          
        :scenes ->
          show_hierarchy_if_available(viewport)
          
        :semantic ->
          show_graphs_with_semantic(viewport, graph_filter, verbose)
          show_semantic_summary(viewport)
          
        :graphs ->
          show_graphs_with_semantic(viewport, graph_filter, verbose)
      end
      
      show_quick_tips()
      :ok
    else
      error -> 
        IO.puts("❌ Error: #{inspect(error)}")
        :error
    end
  end
  
  @doc """
  Show all semantic content across the application.
  
  A simplified view focusing just on the semantic elements,
  organized by type with content previews.
  """
  def semantic(viewport_name \\ :main_viewport, graph_key \\ nil) do
    with {:ok, viewport} <- get_viewport(viewport_name) do
      if graph_key do
        # Show semantic for specific graph
        show_graph_semantic(viewport, graph_key)
      else
        # Show all semantic content
        show_all_semantic(viewport)
      end
      :ok
    end
  end
  
  
  @doc """
  Find elements by semantic type.
  
  ## Examples
  
      iex> find(:button)
      iex> find(:text_buffer)
      iex> find(:menu)
  """
  def find(type, viewport_name \\ :main_viewport) do
    with {:ok, viewport} <- get_viewport(viewport_name) do
      entries = :ets.tab2list(viewport.semantic_table)
      
      elements = for {graph_key, data} <- entries,
                     id <- Map.get(data.by_type, type, []),
                     elem = Map.get(data.elements, id),
                     do: {graph_key, elem}
      
      if elements == [] do
        IO.puts("No #{type} elements found")
        show_available_types(entries)
      else
        icon = get_type_icon(type)
        IO.puts("\n#{icon} Found #{length(elements)} #{type} element(s):")
        
        Enum.group_by(elements, fn {graph_key, _} -> graph_key end)
        |> Enum.each(fn {graph_key, elems} ->
          IO.puts("\nGraph \"#{short_id(graph_key)}\":")
          Enum.each(elems, fn {_, elem} ->
            desc = format_element_for_find(elem)
            IO.puts("  • #{desc}")
          end)
        end)
      end
      :ok
    end
  end
  
  @doc """
  List all semantic types in use.
  """
  def types(viewport_name \\ :main_viewport) do
    with {:ok, viewport} <- get_viewport(viewport_name) do
      entries = :ets.tab2list(viewport.semantic_table)
      
      type_counts = entries
        |> Enum.flat_map(fn {_, data} -> 
          Enum.map(data.by_type, fn {type, ids} -> {type, length(ids)} end)
        end)
        |> Enum.reduce(%{}, fn {type, count}, acc ->
          Map.update(acc, type, count, &(&1 + count))
        end)
      
      if map_size(type_counts) == 0 do
        IO.puts("No semantic types found")
      else
        IO.puts("\n🏷️  Semantic Types in Use:")
        type_counts
        |> Enum.sort_by(fn {_, count} -> -count end)
        |> Enum.each(fn {type, count} ->
          icon = get_type_icon(type)
          IO.puts("#{icon} #{type}: #{count} element(s)")
        end)
      end
      :ok
    end
  end
  
  @doc """
  Get raw semantic data for advanced queries.
  
  Returns the semantic data structure that you can
  query programmatically.
  """
  def raw_semantic(viewport_name \\ :main_viewport, graph_key \\ nil) do
    with {:ok, viewport} <- get_viewport(viewport_name) do
      if graph_key do
        case :ets.lookup(viewport.semantic_table, graph_key) do
          [{^graph_key, data}] -> data
          [] -> nil
        end
      else
        # Return all semantic data
        entries = :ets.tab2list(viewport.semantic_table)
        Map.new(entries)
      end
    end
  end

  @doc """
  Get enhanced scene script data with hierarchy and metadata.
  
  This provides access to the enhanced scene_script layer that includes
  all elements (not just semantic ones), hierarchy relationships,
  and automation-friendly metadata.
  
  ## Examples
  
      # Get all scene scripts
      iex> raw_scene_script()
      
      # Get specific graph's script data
      iex> raw_scene_script(:main_viewport, "graph_key")
  """
  def raw_scene_script(viewport_name \\ :main_viewport, graph_key \\ nil) do
    with {:ok, viewport} <- get_viewport(viewport_name) do
      if graph_key do
        case :ets.lookup(viewport.scene_script_table, graph_key) do
          [{^graph_key, data}] -> data
          [] -> nil
        end
      else
        # Return all scene script data
        entries = :ets.tab2list(viewport.scene_script_table)
        Map.new(entries)
      end
    end
  end

  @doc """
  Wait for scene hierarchy to be established with retry logic.
  
  Options:
    * `:timeout` - Maximum time to wait in milliseconds (default: 5000)
    * `:interval` - Check interval in milliseconds (default: 100)
    * `:min_scenes` - Minimum number of scenes expected (default: 2)
  """
  def wait_for_scene_hierarchy(viewport_name \\ :main_viewport, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5000)
    interval = Keyword.get(opts, :interval, 100)
    min_scenes = Keyword.get(opts, :min_scenes, 2)
    
    wait_until(timeout, interval, fn ->
      data = raw_scene_script(viewport_name)
      
      cond do
        map_size(data) < min_scenes ->
          {:error, :insufficient_scenes}
        not (Map.has_key?(data, "_root_") and Map.has_key?(data, "_main_")) ->
          {:error, :missing_core_scenes}
        true ->
          # Verify hierarchy is properly established
          root = data["_root_"]
          main = data["_main_"]
          
          if root && main && main.parent == "_root_" && length(root.children) > 0 do
            {:ok, data}
          else
            {:error, :hierarchy_not_ready}
          end
      end
    end)
  end

  @doc """
  Compare two scene states and show what changed.
  """
  def diff_scenes(before_state, after_state) do
    %{
      added_graphs: Map.keys(after_state) -- Map.keys(before_state),
      removed_graphs: Map.keys(before_state) -- Map.keys(after_state),
      modified_graphs: find_modified_graphs(before_state, after_state),
      element_changes: diff_elements(before_state, after_state),
      hierarchy_changes: diff_hierarchy(before_state, after_state)
    }
  end

  @doc """
  Track scene changes during an operation.
  """
  def track_changes(viewport_name \\ :main_viewport, fun) when is_function(fun, 0) do
    before = raw_scene_script(viewport_name)
    before_time = System.monotonic_time(:microsecond)
    
    result = fun.()
    
    after_time = System.monotonic_time(:microsecond)
    after_state = raw_scene_script(viewport_name)
    
    changes = diff_scenes(before, after_state)
    duration_us = after_time - before_time
    
    {result, Map.put(changes, :duration_us, duration_us)}
  end

  @doc """
  Generate an ASCII art representation of the scene hierarchy.
  """
  def visualize_hierarchy(viewport_name \\ :main_viewport) do
    data = raw_scene_script(viewport_name)
    
    IO.puts("\n╔═══════════════════════════════════╗")
    IO.puts("║     Scene Hierarchy Diagram       ║")
    IO.puts("╚═══════════════════════════════════╝\n")
    
    if map_size(data) == 0 do
      IO.puts("  (No scenes found)")
    else
      render_hierarchy_tree(data, "_root_", "", true, 0)
    end
  end

  @doc """
  Show a heat map of element density across scenes.
  """
  def element_heatmap(viewport_name \\ :main_viewport) do
    data = raw_scene_script(viewport_name)
    
    heatmap = data
    |> Enum.map(fn {key, scene} ->
      density = map_size(scene.elements)
      bar = String.duplicate("█", min(density, 50))
      {key, density, bar}
    end)
    |> Enum.sort_by(fn {_, density, _} -> -density end)
    
    IO.puts("\n📊 Element Density Heatmap:")
    IO.puts("════════════════════════════")
    Enum.each(heatmap, fn {key, density, bar} ->
      short_key = short_id(key)
      padding = String.duplicate(" ", max(0, 20 - String.length(short_key)))
      IO.puts("#{short_key}#{padding} [#{String.pad_leading(Integer.to_string(density), 3)}] #{bar}")
    end)
    IO.puts("")
  end

  @doc """
  Run comprehensive diagnostics when scene structure is unexpected.
  """
  def diagnose_scene_issues(viewport_name \\ :main_viewport) do
    IO.puts("\n🏥 Scene Diagnostics Report")
    IO.puts("═══════════════════════════")
    
    # Check viewport
    case get_viewport(viewport_name) do
      {:ok, vp} ->
        IO.puts("✓ Viewport accessible: #{inspect(viewport_name)}")
        diagnose_viewport(vp)
      {:error, reason} ->
        IO.puts("✗ Viewport error: #{reason}")
        IO.puts("\n⚠️  Cannot access viewport!")
        IO.puts("  Possible causes:")
        IO.puts("  - Application not started")
        IO.puts("  - Wrong viewport name (try :main_viewport)")
        IO.puts("  - ViewPort process crashed")
    end
    
    # Check Scenic processes
    check_scenic_processes()
    
    # Suggest fixes
    suggest_remedies()
  end

  # Private helper functions

  defp wait_until(timeout, _interval, _fun) when timeout <= 0 do
    {:error, :timeout}
  end
  
  defp wait_until(timeout, interval, fun) do
    case fun.() do
      {:ok, result} -> 
        {:ok, result}
      {:error, _reason} ->
        Process.sleep(interval)
        wait_until(timeout - interval, interval, fun)
    end
  end

  defp find_modified_graphs(before_state, after_state) do
    common_keys = Map.keys(before_state) -- (Map.keys(before_state) -- Map.keys(after_state))
    
    Enum.filter(common_keys, fn key ->
      before_data = Map.get(before_state, key)
      after_data = Map.get(after_state, key)
      
      before_data != after_data
    end)
  end

  defp diff_elements(before_state, after_state) do
    %{
      total_before: count_all_elements(before_state),
      total_after: count_all_elements(after_state),
      by_graph: element_changes_by_graph(before_state, after_state)
    }
  end

  defp diff_hierarchy(before_state, after_state) do
    before_structure = extract_hierarchy_structure(before_state)
    after_structure = extract_hierarchy_structure(after_state)
    
    %{
      parent_changes: find_parent_changes(before_structure, after_structure),
      depth_changes: find_depth_changes(before_structure, after_structure)
    }
  end

  defp count_all_elements(scene_data) do
    scene_data
    |> Map.values()
    |> Enum.map(fn scene -> map_size(scene.elements) end)
    |> Enum.sum()
  end

  defp element_changes_by_graph(before_state, after_state) do
    all_keys = Map.keys(before_state) ++ Map.keys(after_state) |> Enum.uniq()
    
    Map.new(all_keys, fn key ->
      before_count = get_in(before_state, [key, :elements]) |> map_size_safe()
      after_count = get_in(after_state, [key, :elements]) |> map_size_safe()
      
      {key, %{before: before_count, after: after_count, change: after_count - before_count}}
    end)
  end

  defp map_size_safe(nil), do: 0
  defp map_size_safe(map) when is_map(map), do: map_size(map)
  defp map_size_safe(_), do: 0

  defp extract_hierarchy_structure(scene_data) do
    Map.new(scene_data, fn {key, scene} ->
      {key, %{parent: scene.parent, depth: scene.depth, children: scene.children}}
    end)
  end

  defp find_parent_changes(before_structure, after_structure) do
    Enum.reduce(after_structure, [], fn {key, after_info}, changes ->
      case Map.get(before_structure, key) do
        nil -> changes
        before_info ->
          if before_info.parent != after_info.parent do
            [{key, %{from: before_info.parent, to: after_info.parent}} | changes]
          else
            changes
          end
      end
    end)
  end

  defp find_depth_changes(before_structure, after_structure) do
    Enum.reduce(after_structure, [], fn {key, after_info}, changes ->
      case Map.get(before_structure, key) do
        nil -> changes
        before_info ->
          if before_info.depth != after_info.depth do
            [{key, %{from: before_info.depth, to: after_info.depth}} | changes]
          else
            changes
          end
      end
    end)
  end

  defp diagnose_viewport(viewport) do
    # Check scene script table
    script_count = case :ets.info(viewport.scene_script_table, :size) do
      :undefined -> 0
      count -> count
    end
    IO.puts("  Scene scripts: #{script_count}")
    
    # Check semantic table
    semantic_count = case :ets.info(viewport.semantic_table, :size) do
      :undefined -> 0
      count -> count
    end
    IO.puts("  Semantic entries: #{semantic_count}")
    
    # Check for common issues
    if script_count == 0 do
      IO.puts("\n⚠️  No scene scripts found!")
      IO.puts("  Possible causes:")
      IO.puts("  - Application just started (try waiting)")
      IO.puts("  - Scene not properly initialized")
      IO.puts("  - ViewPort enhancement not enabled")
    end
  end

  defp check_scenic_processes() do
    IO.puts("\n📋 Process Status:")
    
    # Check if Scenic application is running
    case Application.get_application(Scenic.ViewPort) do
      :scenic ->
        IO.puts("  ✓ Scenic application running")
      _ ->
        IO.puts("  ✗ Scenic application not detected")
    end
    
    # Check for viewport processes
    viewport_count = Process.registered()
    |> Enum.filter(&(Atom.to_string(&1) =~ "viewport"))
    |> length()
    
    IO.puts("  ViewPort processes: #{viewport_count}")
  end

  defp suggest_remedies() do
    IO.puts("\n💡 Suggested Actions:")
    IO.puts("  1. Wait for scene initialization:")
    IO.puts("     Scenic.DevTools.wait_for_scene_hierarchy()")
    IO.puts("  2. Check viewport names:")
    IO.puts("     Scenic.ViewPort.list()")
    IO.puts("  3. Force scene refresh:")
    IO.puts("     Scenic.ViewPort.reset(:main_viewport)")
  end

  @doc """
  Show the hierarchical structure of graphs.
  
  This displays the parent-child relationships between graphs,
  providing a tree view of how your application is structured.
  """
  def hierarchy(viewport_name \\ :main_viewport) do
    with {:ok, viewport} <- get_viewport(viewport_name) do
      entries = :ets.tab2list(viewport.scene_script_table)
      
      if entries == [] do
        IO.puts("📊 No graphs found")
      else
        IO.puts("\n🏗️  Graph Hierarchy:")
        IO.puts("──────────────────")
        
        # Find root graphs (no parent)
        roots = Enum.filter(entries, fn {_, data} -> 
          data.parent == nil 
        end)
        
        if roots == [] do
          IO.puts("  No root graphs found")
        else
          Enum.each(roots, fn {key, data} ->
            render_hierarchy_tree(key, data, entries, "", false)
          end)
        end
      end
      :ok
    end
  end

  @doc """
  Introspect the scene - a high-level view showing your app as scenes and components.
  
  This is the top-level developer interface that presents your application
  in terms of scenes, components, and their relationships rather than 
  low-level graphs and primitives.
  
  ## Examples
  
      # Overview of your entire application
      iex> introspect()
      
      # Dive into a specific scene/component
      iex> introspect("main_editor")
      
      # Show with detailed component info
      iex> introspect(detailed: true)
  """
  def introspect(opts \\ [])
  def introspect(scene_name) when is_binary(scene_name) do
    introspect(scene: scene_name)
  end
  def introspect(opts) when is_list(opts) do
    viewport_name = Keyword.get(opts, :viewport, :main_viewport)
    scene_filter = Keyword.get(opts, :scene)
    detailed = Keyword.get(opts, :detailed, false)
    
    with {:ok, viewport} <- get_viewport(viewport_name) do
      IO.puts("\n╔══════ Scene Introspection ══════╗")
      IO.puts("║ Application: #{format_app_name(viewport_name)}")
      IO.puts("║ ViewPort: #{format_size(viewport.size)}")
      IO.puts("╚═════════════════════════════════╝\n")
      
      scene_analysis = analyze_scenes(viewport)
      
      if scene_filter do
        show_scene_detail(scene_analysis, scene_filter, detailed)
      else
        show_application_overview(scene_analysis, detailed)
      end
      
      show_introspection_tips()
      :ok
    else
      error -> 
        IO.puts("❌ Error: #{inspect(error)}")
        :error
    end
  end

  @doc """
  Explore a specific component or scene interactively.
  
  Shows the component breakdown, its role in the application,
  and what interactive elements it contains.
  """
  def explore(component_name, viewport_name \\ :main_viewport) do
    with {:ok, viewport} <- get_viewport(viewport_name) do
      scene_analysis = analyze_scenes(viewport)
      component = find_component_by_name(scene_analysis, component_name)
      
      if component do
        show_component_explorer(component, scene_analysis)
      else
        IO.puts("🔍 Component '#{component_name}' not found")
        suggest_available_components(scene_analysis)
      end
      :ok
    end
  end

  @doc """
  Show the application's component architecture.
  
  Displays how your application is structured in terms of
  reusable components and their relationships.
  """
  def architecture(viewport_name \\ :main_viewport) do
    with {:ok, viewport} <- get_viewport(viewport_name) do
      IO.puts("\n🏛️  Application Architecture")
      IO.puts("══════════════════════════")
      
      scene_analysis = analyze_scenes(viewport)
      show_architecture_overview(scene_analysis)
      :ok
    end
  end

  @doc """
  Find elements across all graphs with advanced filtering.
  
  Supports finding by:
  - Semantic type (`:text_buffer`, `:button`)
  - Accessibility role (`:textbox`, `:button`)  
  - Primitive type (`Scenic.Primitive.Text`)
  - Graph location
  
  ## Examples
  
      # Find by semantic type
      iex> find_element(type: :text_buffer)
      
      # Find by role
      iex> find_element(role: :button)
      
      # Find by primitive type
      iex> find_element(primitive: Scenic.Primitive.Text)
      
      # Find within specific graph
      iex> find_element(type: :button, in_graph: "main_graph")
  """
  def find_element(opts, viewport_name \\ :main_viewport) do
    type = Keyword.get(opts, :type)
    role = Keyword.get(opts, :role)  
    primitive = Keyword.get(opts, :primitive)
    in_graph = Keyword.get(opts, :in_graph)
    
    with {:ok, viewport} <- get_viewport(viewport_name) do
      entries = :ets.tab2list(viewport.scene_script_table)
      
      # Filter by graph if specified
      entries = if in_graph do
        Enum.filter(entries, fn {key, _} -> 
          String.contains?(to_string(key), in_graph)
        end)
      else
        entries
      end
      
      # Find matching elements
      elements = find_matching_elements(entries, type: type, role: role, primitive: primitive)
      
      display_found_elements(elements, opts)
      :ok
    end
  end
  
  # ============================================================================
  # Private Display Functions
  # ============================================================================

  defp show_hierarchy_if_available(viewport) do
    # Check if scene_script_table is available and has data
    entries = :ets.tab2list(viewport.scene_script_table)
    
    if entries != [] do
      IO.puts("🏗️  Graph Hierarchy:")
      IO.puts("──────────────────")
      
      # Find root graphs (no parent)
      roots = Enum.filter(entries, fn {_, data} -> 
        data.parent == nil 
      end)
      
      if roots == [] do
        IO.puts("  No root graphs found")
      else
        Enum.each(roots, fn {key, data} ->
          render_hierarchy_tree(key, data, entries, "", false)
        end)
      end
      IO.puts("")
    else
      IO.puts("⚠️  Graph hierarchy data not available")
      IO.puts("   (Scene script enhancement not yet populated)")
      IO.puts("")
    end
  end
  
  
  defp show_graphs_with_semantic(viewport, graph_filter, verbose) do
    entries = :ets.tab2list(viewport.semantic_table)
    
    # Filter if specific graph requested
    entries = if graph_filter do
      Enum.filter(entries, fn {key, _} -> 
        String.contains?(key, graph_filter)
      end)
    else
      entries
    end
    
    if entries == [] do
      if graph_filter do
        IO.puts("📊 No graphs matching: #{graph_filter}")
      else
        IO.puts("📊 No graphs found")
      end
    else
      IO.puts("📊 Graphs & Semantic Content:")
      IO.puts("────────────────────────────")
      
      # Group by whether they have semantic content
      {with_semantic, without} = Enum.split_with(entries, fn {_, data} ->
        map_size(data.elements) > 0
      end)
      
      # Show graphs with semantic content first
      if with_semantic != [] do
        IO.puts("\n🏷️  With Semantic Data:")
        Enum.each(with_semantic, fn {key, data} ->
          render_graph_semantic(key, data, verbose, viewport)
        end)
      end
      
      # Then graphs without
      if without != [] and verbose do
        IO.puts("\n⚪ Without Semantic Data:")
        Enum.each(without, fn {key, _} ->
          IO.puts("  • Graph \"#{short_id(key)}\"")
        end)
      end
      
      IO.puts("")
    end
  end
  
  defp show_semantic_summary(viewport) do
    entries = :ets.tab2list(viewport.semantic_table)
    
    all_elements = for {_, data} <- entries,
                       {_, elem} <- data.elements,
                       do: elem
    
    if all_elements != [] do
      IO.puts("📈 Semantic Summary:")
      IO.puts("──────────────────")
      
      # Group by type and show counts
      all_elements
      |> Enum.group_by(& &1.semantic.type)
      |> Enum.sort_by(fn {_, elems} -> -length(elems) end)
      |> Enum.each(fn {type, elems} ->
        icon = get_type_icon(type)
        count = length(elems)
        
        # Show sample for common types
        sample = case type do
          :button ->
            labels = elems 
              |> Enum.map(& &1.semantic[:label])
              |> Enum.filter(& &1)
              |> Enum.take(3)
            if labels != [], do: " (#{Enum.join(labels, ", ")})", else: ""
            
          :text_buffer ->
            " (#{count} buffer#{if count > 1, do: "s", else: ""})"
            
          _ -> ""
        end
        
        IO.puts("  #{icon} #{type}: #{count}#{sample}")
      end)
      
      IO.puts("")
    end
  end
  
  defp show_quick_tips do
    IO.puts("💡 Quick Commands:")
    IO.puts("  • inspect_viewport(show: :semantic)  # Just semantic content")
    IO.puts("  • hierarchy()                        # Show graph structure")
    IO.puts("  • find(:button)                      # Find by semantic type")
    IO.puts("  • find_element(role: :textbox)       # Find by accessibility role")
    IO.puts("  • types()                            # List all semantic types")
    IO.puts("  • semantic()                         # All semantic content")
    IO.puts("  • raw_scene_script()                 # Enhanced data with hierarchy")
  end
  
  # ============================================================================
  # Private Semantic Display Functions
  # ============================================================================
  
  defp show_graph_semantic(viewport, graph_key) do
    case :ets.lookup(viewport.semantic_table, graph_key) do
      [{^graph_key, data}] ->
        IO.puts("\n📊 Semantic Data for Graph \"#{short_id(graph_key)}\":")
        if map_size(data.elements) == 0 do
          IO.puts("  No semantic elements")
        else
          render_semantic_elements(data)
        end
      [] ->
        IO.puts("Graph not found: #{graph_key}")
    end
  end
  
  defp show_all_semantic(viewport) do
    entries = :ets.tab2list(viewport.semantic_table)
    
    all_elements = for {_, data} <- entries,
                       {_, elem} <- data.elements,
                       do: elem
    
    if all_elements == [] do
      IO.puts("\n🚫 No semantic content found")
      IO.puts("\n💡 Add semantic annotations:")
      IO.puts("  |> text(\"Hello\", semantic: Semantic.text_buffer(buffer_id: 1))")
      IO.puts("  |> rect({100, 40}, semantic: Semantic.button(\"Save\"))")
    else
      IO.puts("\n🏷️  All Semantic Content:")
      
      # Group by type
      all_elements
      |> Enum.group_by(& &1.semantic.type)
      |> Enum.sort_by(fn {type, _} -> type end)
      |> Enum.each(fn {type, elems} ->
        icon = get_type_icon(type)
        IO.puts("\n#{icon} #{String.capitalize(to_string(type))} (#{length(elems)}):")
        
        Enum.each(elems, fn elem ->
          desc = format_semantic_element(elem)
          IO.puts("  • #{desc}")
        end)
      end)
    end
  end
  
  # ============================================================================
  # Rendering Helpers
  # ============================================================================
  
  
  defp render_graph_semantic(key, data, verbose, _viewport) do
    element_count = map_size(data.elements)
    
    IO.puts("\n  📋 \"#{short_id(key)}\"")
    IO.puts("     Elements: #{element_count}")
    
    if element_count > 0 do
      # Group by type for cleaner display
      by_type = Enum.group_by(Map.values(data.elements), & &1.semantic.type)
      
      Enum.each(by_type, fn {type, elems} ->
        icon = get_type_icon(type)
        
        if verbose do
          IO.puts("     #{icon} #{type} (#{length(elems)}):")
          Enum.each(elems, fn elem ->
            desc = format_element_line(elem)
            IO.puts("        • #{desc}")
          end)
        else
          # Compact view - show count only
          count = length(elems)
          IO.puts("     #{icon} #{type}: #{count} element#{if count > 1, do: "s", else: ""}")
        end
      end)
    end
  end
  
  defp render_semantic_elements(data) do
    data.by_type
    |> Enum.sort_by(fn {type, _} -> type end)
    |> Enum.each(fn {type, ids} ->
      icon = get_type_icon(type)
      IO.puts("\n  #{icon} #{type} (#{length(ids)}):")
      
      Enum.each(ids, fn id ->
        elem = Map.get(data.elements, id)
        desc = format_semantic_element(elem)
        IO.puts("    • #{desc}")
      end)
    end)
  end
  
  # ============================================================================
  # Formatting Helpers
  # ============================================================================
  
  defp format_element_line(elem) do
    case elem.semantic.type do
      :text_buffer ->
        lines = if elem.content, do: length(String.split(elem.content, "\n")), else: 0
        "Buffer #{short_id(elem.semantic.buffer_id)} (#{lines} lines)"
        
      :button ->
        "\"#{elem.semantic.label}\""
        
      :menu ->
        "\"#{elem.semantic.name}\""
        
      _ ->
        inspect(elem.semantic, limit: 1, pretty: false)
    end
  end
  
  
  defp format_semantic_element(elem) do
    semantic = elem.semantic
    
    case semantic.type do
      :text_buffer ->
        id = short_id(semantic.buffer_id)
        content_info = if elem.content && elem.content != "" do
          lines = length(String.split(elem.content, "\n"))
          chars = String.length(elem.content)
          " - #{lines} lines, #{chars} chars"
        else
          " - empty"
        end
        "#{id}#{content_info}"
        
      :button ->
        "\"#{semantic.label}\""
        
      :menu ->
        "\"#{semantic.name}\" (#{semantic[:orientation] || :vertical})"
        
      :text_input ->
        name = semantic.name
        placeholder = if semantic[:placeholder], do: " (#{semantic.placeholder})", else: ""
        "\"#{name}\"#{placeholder}"
        
      _ ->
        # For custom types, show key attributes
        attrs = semantic
          |> Map.drop([:type])
          |> Enum.map(fn {k, v} -> "#{k}: #{inspect(v, limit: 1)}" end)
          |> Enum.join(", ")
        
        if attrs == "", do: "#{semantic.type}", else: "#{attrs}"
    end
  end
  
  defp format_element_for_find(elem) do
    case elem.semantic.type do
      :text_buffer ->
        id = short_id(elem.semantic.buffer_id)
        preview = if elem.content && elem.content != "" do
          first_line = elem.content |> String.split("\n") |> List.first() |> String.slice(0, 40)
          " - \"#{first_line}...\""
        else
          " - (empty)"
        end
        "Buffer #{id}#{preview}"
        
      :button ->
        "\"#{elem.semantic.label}\""
        
      _ ->
        format_semantic_element(elem)
    end
  end
  
  # ============================================================================
  # Scene Analysis & Introspection
  # ============================================================================

  # Analyze the viewport and convert raw graph data into scene/component concepts
  defp analyze_scenes(viewport) do
    script_entries = :ets.tab2list(viewport.scene_script_table)
    semantic_entries = :ets.tab2list(viewport.semantic_table)
    
    # Combine script and semantic data
    combined_data = merge_scene_data(script_entries, semantic_entries)
    
    # Identify scene types and roles
    scenes = identify_scenes(combined_data)
    
    # Build component relationships
    components = extract_components(scenes)
    
    %{
      raw_graphs: combined_data,
      scenes: scenes,
      components: components,
      app_structure: build_app_structure(scenes, components)
    }
  end

  defp merge_scene_data(script_entries, semantic_entries) do
    # Create a map of graph_key -> combined data
    script_map = Map.new(script_entries)
    semantic_map = Map.new(semantic_entries)
    
    # Start with script data (which has hierarchy) and enhance with semantic data
    script_map
    |> Enum.map(fn {key, script_data} ->
      semantic_data = Map.get(semantic_map, key, %{elements: %{}, by_type: %{}})
      
      combined = Map.merge(script_data, %{
        semantic_elements: semantic_data.elements,
        semantic_by_type: Map.get(semantic_data, :by_type, %{})
      })
      
      {key, combined}
    end)
    |> Map.new()
  end

  defp identify_scenes(combined_data) do
    combined_data
    |> Enum.map(fn {key, data} ->
      scene_type = determine_scene_type(key, data)
      scene_name = determine_scene_name(key, data, scene_type)
      
      %{
        graph_key: key,
        scene_name: scene_name,
        scene_type: scene_type,
        parent: data.parent,
        children: data.children,
        elements: data.elements,
        semantic_elements: data.semantic_elements,
        interactive_elements: count_interactive_elements(data),
        purpose: determine_scene_purpose(data),
        depth: data.depth
      }
    end)
    |> Enum.sort_by(& &1.depth)
  end

  defp determine_scene_type(key, data) do
    cond do
      key == "_root_" -> :root
      key == "_main_" -> :main
      String.starts_with?(key, "_") -> :system
      map_size(data.elements) == 0 -> :container
      has_text_editing?(data) -> :editor
      has_buttons_or_menus?(data) -> :interface
      has_display_content?(data) -> :display
      true -> :component
    end
  end

  defp determine_scene_name(key, data, scene_type) do
    case scene_type do
      :root -> "Application Root"
      :main -> "Main Scene"
      :editor -> extract_editor_name(data) || "Text Editor"
      :interface -> extract_interface_name(data) || "UI Controls"
      :display -> "Display Area"
      :container -> "Layout Container"
      :component -> extract_component_name(data) || short_id(key)
      :system -> "System (#{short_id(key)})"
    end
  end

  defp extract_components(scenes) do
    scenes
    |> Enum.filter(fn scene -> scene.scene_type not in [:root, :main, :system] end)
    |> Enum.map(fn scene ->
      %{
        name: scene.scene_name,
        type: scene.scene_type,
        graph_key: scene.graph_key,
        capabilities: extract_capabilities(scene),
        interactive_count: scene.interactive_elements,
        purpose: scene.purpose
      }
    end)
  end

  defp build_app_structure(scenes, components) do
    root_scene = Enum.find(scenes, & &1.scene_type == :root)
    main_scene = Enum.find(scenes, & &1.scene_type == :main)
    
    %{
      entry_point: root_scene,
      main_interface: main_scene,
      component_count: length(components),
      scene_depth: Enum.map(scenes, & &1.depth) |> Enum.max(fn -> 0 end),
      interaction_points: Enum.sum(Enum.map(scenes, & &1.interactive_elements))
    }
  end

  # ============================================================================
  # Scene Display Functions
  # ============================================================================

  defp show_application_overview(analysis, detailed) do
    IO.puts("🎭 Application Scenes")
    IO.puts("━━━━━━━━━━━━━━━━━━━━")
    
    # Show the scene hierarchy with purpose and capabilities
    show_scene_tree(analysis.scenes, detailed)
    
    IO.puts("\n📊 Application Summary")
    IO.puts("━━━━━━━━━━━━━━━━━━━━━━")
    show_app_summary(analysis)
    
    if detailed do
      IO.puts("\n🧩 Components")
      IO.puts("━━━━━━━━━━━━━")
      show_components_summary(analysis.components)
    end
  end

  defp show_scene_tree(scenes, detailed) do
    # Find root and show hierarchy
    roots = Enum.filter(scenes, & &1.parent == nil)
    
    Enum.each(roots, fn root ->
      render_scene_tree(root, scenes, "", detailed)
    end)
  end

  defp render_scene_tree(scene, all_scenes, prefix, detailed) do
    icon = get_scene_icon(scene.scene_type)
    name = scene.scene_name
    
    info = if scene.interactive_elements > 0 do
      " (#{scene.interactive_elements} interactive)"
    else
      ""
    end
    
    purpose = if detailed and scene.purpose do
      " - #{scene.purpose}"
    else
      ""
    end
    
    IO.puts("#{prefix}#{icon} #{name}#{info}#{purpose}")
    
    # Show children
    children = Enum.filter(all_scenes, & &1.parent == scene.graph_key)
    
    Enum.with_index(children)
    |> Enum.each(fn {child, idx} ->
      is_last = idx == length(children) - 1
      child_prefix = prefix <> if is_last, do: "└── ", else: "├── "
      
      render_scene_tree(child, all_scenes, child_prefix, detailed)
    end)
  end

  defp show_app_summary(analysis) do
    structure = analysis.app_structure
    
    IO.puts("  Scenes: #{length(analysis.scenes)}")
    IO.puts("  Components: #{structure.component_count}")
    IO.puts("  Scene Depth: #{structure.scene_depth}")
    IO.puts("  Interactive Elements: #{structure.interaction_points}")
    
    # Show breakdown by scene type
    type_counts = analysis.scenes
      |> Enum.group_by(& &1.scene_type)
      |> Enum.map(fn {type, scenes} -> {type, length(scenes)} end)
      |> Enum.sort_by(fn {_, count} -> -count end)
    
    if length(type_counts) > 1 do
      IO.puts("\n  Scene Types:")
      Enum.each(type_counts, fn {type, count} ->
        icon = get_scene_icon(type)
        IO.puts("    #{icon} #{format_scene_type(type)}: #{count}")
      end)
    end
  end

  defp show_components_summary(components) do
    if components == [] do
      IO.puts("  No interactive components identified")
    else
      Enum.each(components, fn component ->
        icon = get_scene_icon(component.type)
        capabilities = Enum.join(component.capabilities, ", ")
        IO.puts("  #{icon} #{component.name}")
        if capabilities != "" do
          IO.puts("      Capabilities: #{capabilities}")
        end
        if component.interactive_count > 0 do
          IO.puts("      Interactive: #{component.interactive_count} elements")
        end
      end)
    end
  end

  defp show_scene_detail(analysis, scene_filter, _detailed) do
    scene = Enum.find(analysis.scenes, fn s ->
      String.contains?(String.downcase(s.scene_name), String.downcase(scene_filter)) or
      String.contains?(s.graph_key, scene_filter)
    end)
    
    if scene do
      show_component_explorer(scene, analysis)
    else
      IO.puts("🔍 Scene '#{scene_filter}' not found")
      IO.puts("\nAvailable scenes:")
      Enum.each(analysis.scenes, fn s ->
        icon = get_scene_icon(s.scene_type)
        IO.puts("  #{icon} #{s.scene_name} (#{s.graph_key})")
      end)
    end
  end

  defp show_component_explorer(component, analysis) do
    IO.puts("🔍 Exploring: #{component.scene_name}")
    IO.puts("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    IO.puts("📋 Component Details:")
    IO.puts("  Type: #{format_scene_type(component.scene_type)}")
    IO.puts("  Graph Key: #{component.graph_key}")
    IO.puts("  Purpose: #{component.purpose || "General component"}")
    
    if component.interactive_elements > 0 do
      IO.puts("\n🎯 Interactive Elements:")
      show_interactive_breakdown(component)
    end
    
    show_component_relationships(component, analysis)
    
    if map_size(component.elements) > 0 do
      IO.puts("\n🔧 Technical Details:")
      IO.puts("  Total Elements: #{map_size(component.elements)}")
      show_element_breakdown(component)
    end
  end

  defp show_architecture_overview(analysis) do
    IO.puts("\n📐 Structure Overview:")
    show_scene_tree(analysis.scenes, false)
    
    IO.puts("\n🔗 Component Relationships:")
    show_component_relationships_overview(analysis)
    
    IO.puts("\n🎯 Interaction Design:")
    show_interaction_analysis(analysis)
  end

  # ============================================================================
  # Scene Script Helpers
  # ============================================================================

  defp render_hierarchy_tree(key, data, all_entries, prefix, verbose) do
    element_count = map_size(data.elements)
    
    # Show type counts for the graph
    type_info = if element_count > 0 do
      semantic_types = Map.keys(data.by_type) |> Enum.join(", ")
      " (#{element_count} elements: #{semantic_types})"
    else
      " (empty)"
    end
    
    IO.puts("#{prefix}📊 #{short_id(key)}#{type_info}")
    
    # Show children
    children = Enum.filter(all_entries, fn {_child_key, child_data} ->
      child_data.parent == key
    end)
    
    Enum.with_index(children)
    |> Enum.each(fn {{child_key, child_data}, idx} ->
      is_last = idx == length(children) - 1
      child_prefix = prefix <> if is_last, do: "└── ", else: "├── "
      _next_prefix = prefix <> if is_last, do: "    ", else: "│   "
      
      render_hierarchy_tree(child_key, child_data, all_entries, child_prefix, verbose)
    end)
  end

  defp find_matching_elements(entries, opts) do
    type = Keyword.get(opts, :type)
    role = Keyword.get(opts, :role)
    primitive = Keyword.get(opts, :primitive)
    
    entries
    |> Enum.flat_map(fn {graph_key, data} ->
      matching_ids = []
      
      # Find by semantic type
      matching_ids = if type do
        Map.get(data.by_type, type, []) ++ matching_ids
      else
        matching_ids
      end
      
      # Find by role
      matching_ids = if role do
        Map.get(data.by_role, role, []) ++ matching_ids
      else
        matching_ids
      end
      
      # Find by primitive type
      matching_ids = if primitive do
        Map.get(data.by_primitive, primitive, []) ++ matching_ids
      else
        matching_ids
      end
      
      # If no filters specified, return all elements
      matching_ids = if type == nil and role == nil and primitive == nil do
        Map.keys(data.elements)
      else
        matching_ids |> Enum.uniq()
      end
      
      # Convert IDs to full element data
      Enum.map(matching_ids, fn id ->
        elem = Map.get(data.elements, id)
        {graph_key, id, elem}
      end)
    end)
  end

  defp display_found_elements(elements, opts) do
    if elements == [] do
      IO.puts("No matching elements found")
      suggest_available_options(opts)
    else
      filter_desc = describe_filters(opts)
      IO.puts("\n🔍 Found #{length(elements)} element(s)#{filter_desc}:")
      
      # Group by graph for cleaner display
      elements
      |> Enum.group_by(fn {graph_key, _, _} -> graph_key end)
      |> Enum.each(fn {graph_key, graph_elements} ->
        IO.puts("\nGraph \"#{short_id(graph_key)}\":")
        
        Enum.each(graph_elements, fn {_, id, elem} ->
          desc = format_element_detailed(elem)
          IO.puts("  • [#{id}] #{desc}")
        end)
      end)
    end
  end

  defp describe_filters(opts) do
    filters = []
    
    filters = if type = Keyword.get(opts, :type) do
      ["type: #{type}" | filters]
    else
      filters
    end
    
    filters = if role = Keyword.get(opts, :role) do
      ["role: #{role}" | filters]
    else
      filters
    end
    
    filters = if primitive = Keyword.get(opts, :primitive) do
      name = primitive |> to_string() |> String.split(".") |> List.last()
      ["primitive: #{name}" | filters]
    else
      filters
    end
    
    filters = if in_graph = Keyword.get(opts, :in_graph) do
      ["in graph: #{in_graph}" | filters]
    else
      filters
    end
    
    if filters != [] do
      " matching " <> Enum.join(filters, ", ")
    else
      ""
    end
  end

  defp format_element_detailed(elem) do
    type_info = if primitive_name = elem.type do
      name = primitive_name |> to_string() |> String.split(".") |> List.last()
      "#{name}"
    else
      "unknown"
    end
    
    semantic_info = if map_size(elem.semantic) > 0 do
      type = Map.get(elem.semantic, :type, "custom")
      " (#{type})"
    else
      ""
    end
    
    content_info = if elem.content do
      preview = elem.content |> String.slice(0, 30)
      " - \"#{preview}#{if String.length(elem.content) > 30, do: "...", else: ""}\""
    else
      ""
    end
    
    "#{type_info}#{semantic_info}#{content_info}"
  end

  defp suggest_available_options(_opts) do
    # This would show what options are actually available
    # For now, just show a helpful message
    IO.puts("\n💡 Try:")
    IO.puts("  • find_element(type: :text_buffer)")
    IO.puts("  • find_element(role: :button)")
    IO.puts("  • find_element(primitive: Scenic.Primitive.Text)")
    IO.puts("  • hierarchy()  # Show graph structure")
  end

  # ============================================================================
  # Scene Analysis Helper Functions
  # ============================================================================

  # Determine what this scene/component is for based on its elements
  defp determine_scene_purpose(data) do
    cond do
      has_text_editing?(data) -> "Text editing and content creation"
      has_form_elements?(data) -> "User input and form interaction"
      has_navigation?(data) -> "Application navigation"
      has_display_content?(data) -> "Content display and visualization"
      has_buttons_or_menus?(data) -> "User interface controls"
      map_size(data.elements) == 0 -> "Layout and structure"
      true -> "Component functionality"
    end
  end

  # Check what capabilities a scene/component has
  defp extract_capabilities(scene) do
    capabilities = []
    
    capabilities = if has_text_editing?(scene) do
      ["text editing" | capabilities]
    else
      capabilities
    end
    
    capabilities = if has_buttons_or_menus?(scene) do
      ["interactive controls" | capabilities]
    else
      capabilities
    end
    
    capabilities = if has_form_elements?(scene) do
      ["data input" | capabilities]
    else
      capabilities
    end
    
    capabilities = if has_display_content?(scene) do
      ["content display" | capabilities]
    else
      capabilities
    end
    
    if capabilities == [] do
      ["layout"]
    else
      capabilities
    end
  end

  # Scene type detection helpers
  defp has_text_editing?(data) do
    Map.get(data, :semantic_by_type, %{})
    |> Map.has_key?(:text_buffer)
  end

  defp has_buttons_or_menus?(data) do
    by_type = Map.get(data, :semantic_by_type, %{})
    Map.has_key?(by_type, :button) or Map.has_key?(by_type, :menu)
  end

  defp has_form_elements?(data) do
    by_type = Map.get(data, :semantic_by_type, %{})
    Map.has_key?(by_type, :text_input) or Map.has_key?(by_type, :checkbox)
  end

  defp has_navigation?(data) do
    by_type = Map.get(data, :semantic_by_type, %{})
    Map.has_key?(by_type, :menu) or Map.has_key?(by_type, :navigation)
  end

  defp has_display_content?(data) do
    by_primitive = Map.get(data, :by_primitive, %{})
    
    text_elements = Map.get(by_primitive, Scenic.Primitive.Text, [])
    other_visual = Map.get(by_primitive, Scenic.Primitive.Rectangle, []) ++
                   Map.get(by_primitive, Scenic.Primitive.Circle, [])
    
    length(text_elements) > 0 or length(other_visual) > 0
  end

  defp count_interactive_elements(data) do
    by_type = Map.get(data, :semantic_by_type, %{})
    
    button_count = length(Map.get(by_type, :button, []))
    menu_count = length(Map.get(by_type, :menu, []))
    input_count = length(Map.get(by_type, :text_input, []))
    buffer_count = length(Map.get(by_type, :text_buffer, []))
    
    button_count + menu_count + input_count + buffer_count
  end

  # Name extraction helpers
  defp extract_editor_name(data) do
    # Try to get buffer name or file path from semantic data
    text_buffers = Map.get(data, :semantic_elements, %{})
    |> Map.values()
    |> Enum.filter(fn elem -> 
      get_in(elem, [:semantic, :type]) == :text_buffer
    end)
    
    case text_buffers do
      [buffer | _] -> 
        file_path = get_in(buffer, [:semantic, :file_path])
        if file_path do
          "Editor (#{Path.basename(file_path)})"
        else
          nil
        end
      _ -> nil
    end
  end

  defp extract_interface_name(data) do
    # Try to identify the interface based on button labels
    buttons = Map.get(data, :semantic_elements, %{})
    |> Map.values()
    |> Enum.filter(fn elem -> 
      get_in(elem, [:semantic, :type]) == :button
    end)
    
    if length(buttons) > 2 do
      "Toolbar"
    else
      nil
    end
  end

  defp extract_component_name(data) do
    # Try to extract a meaningful name from semantic data
    elements = Map.get(data, :semantic_elements, %{})
    
    case Map.values(elements) do
      [elem | _] ->
        semantic = Map.get(elem, :semantic, %{})
        Map.get(semantic, :name) || Map.get(semantic, :label)
      _ -> nil
    end
  end

  # Display helpers for introspection
  defp get_scene_icon(scene_type) do
    case scene_type do
      :root -> "🏠"
      :main -> "🖥️"
      :editor -> "📝"
      :interface -> "🎛️"
      :display -> "📺"
      :container -> "📦"
      :component -> "🧩"
      :system -> "⚙️"
      _ -> "❓"
    end
  end

  defp format_scene_type(scene_type) do
    case scene_type do
      :root -> "Root Scene"
      :main -> "Main Interface"
      :editor -> "Text Editor"
      :interface -> "UI Controls"
      :display -> "Display Component"
      :container -> "Layout Container"
      :component -> "Component"
      :system -> "System Component"
      _ -> to_string(scene_type)
    end
  end

  defp format_app_name(viewport_name) do
    case viewport_name do
      :main_viewport -> "Scenic Application"
      name -> name |> to_string() |> String.replace("_", " ") |> String.split() |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
    end
  end

  defp show_introspection_tips do
    IO.puts("\n💡 Introspection Commands:")
    IO.puts("  • introspect(detailed: true)         # Detailed view")
    IO.puts("  • introspect(\"editor\")               # Focus on specific scene")
    IO.puts("  • explore(\"Text Editor\")             # Interactive exploration")
    IO.puts("  • architecture()                     # Component relationships")
  end

  # Stubs for functions that need implementation
  defp find_component_by_name(analysis, component_name) do
    Enum.find(analysis.scenes, fn scene ->
      String.contains?(String.downcase(scene.scene_name), String.downcase(component_name))
    end)
  end

  defp suggest_available_components(analysis) do
    IO.puts("\nAvailable components:")
    Enum.each(analysis.scenes, fn scene ->
      icon = get_scene_icon(scene.scene_type)
      IO.puts("  #{icon} #{scene.scene_name}")
    end)
  end

  defp show_interactive_breakdown(component) do
    if map_size(component.semantic_elements) > 0 do
      component.semantic_elements
      |> Map.values()
      |> Enum.filter(fn elem ->
        type = get_in(elem, [:semantic, :type])
        type in [:button, :text_buffer, :text_input, :menu]
      end)
      |> Enum.each(fn elem ->
        type_icon = get_type_icon(elem.semantic.type)
        name = get_in(elem, [:semantic, :label]) || 
               get_in(elem, [:semantic, :name]) || 
               "Unnamed #{elem.semantic.type}"
        IO.puts("    #{type_icon} #{name}")
      end)
    else
      IO.puts("    (No semantic annotations found)")
    end
  end

  defp show_component_relationships(component, analysis) do
    # Show parent and children
    if component.parent do
      parent = Enum.find(analysis.scenes, & &1.graph_key == component.parent)
      if parent do
        IO.puts("\n🔗 Relationships:")
        IO.puts("  Parent: #{get_scene_icon(parent.scene_type)} #{parent.scene_name}")
      end
    end
    
    children = Enum.filter(analysis.scenes, & &1.parent == component.graph_key)
    if children != [] do
      if component.parent == nil do
        IO.puts("\n🔗 Relationships:")
      end
      IO.puts("  Children:")
      Enum.each(children, fn child ->
        IO.puts("    #{get_scene_icon(child.scene_type)} #{child.scene_name}")
      end)
    end
  end

  defp show_element_breakdown(component) do
    by_primitive = component.by_primitive || %{}
    
    if map_size(by_primitive) > 0 do
      by_primitive
      |> Enum.sort_by(fn {_, ids} -> -length(ids) end)
      |> Enum.each(fn {primitive_type, ids} ->
        name = primitive_type |> to_string() |> String.split(".") |> List.last()
        IO.puts("    #{name}: #{length(ids)}")
      end)
    end
  end

  defp show_component_relationships_overview(analysis) do
    # Show how components connect to each other
    roots = Enum.filter(analysis.scenes, & &1.parent == nil)
    
    Enum.each(roots, fn root ->
      children = Enum.filter(analysis.scenes, & &1.parent == root.graph_key)
      if children != [] do
        IO.puts("  #{get_scene_icon(root.scene_type)} #{root.scene_name}")
        Enum.each(children, fn child ->
          IO.puts("    └── #{get_scene_icon(child.scene_type)} #{child.scene_name}")
        end)
      end
    end)
  end

  defp show_interaction_analysis(analysis) do
    total_interactive = Enum.sum(Enum.map(analysis.scenes, & &1.interactive_elements))
    
    IO.puts("  Total Interactive Elements: #{total_interactive}")
    
    # Show which scenes have the most interaction
    interactive_scenes = analysis.scenes
    |> Enum.filter(& &1.interactive_elements > 0)
    |> Enum.sort_by(& -&1.interactive_elements)
    
    if interactive_scenes != [] do
      IO.puts("  Most Interactive:")
      Enum.take(interactive_scenes, 3)
      |> Enum.each(fn scene ->
        IO.puts("    #{get_scene_icon(scene.scene_type)} #{scene.scene_name}: #{scene.interactive_elements}")
      end)
    end
  end

  # ============================================================================
  # Helper Functions
  # ============================================================================
  
  
  
  defp show_available_types(entries) do
    types = entries
      |> Enum.flat_map(fn {_, data} -> Map.keys(data.by_type) end)
      |> Enum.uniq()
      |> Enum.sort()
    
    if types != [] do
      IO.puts("\nAvailable types: #{Enum.join(types, ", ")}")
    end
  end
  
  defp get_type_icon(type) do
    case type do
      :text_buffer -> "📝"
      :button -> "🔘"
      :menu -> "📂"
      :menu_item -> "📄"
      :text_input -> "✏️"
      :list -> "📋"
      :checkbox -> "☑️"
      :radio -> "⭕"
      :slider -> "🎚️"
      :dropdown -> "📥"
      _ -> "🏷️"
    end
  end
  
  defp format_size({width, height}), do: "#{width}×#{height}"
  defp format_size(_), do: "unknown"
  
  defp short_id(id) when is_binary(id) and byte_size(id) > 12 do
    String.slice(id, 0, 8) <> "..."
  end
  defp short_id(id), do: to_string(id)
  
  defp get_viewport(viewport) when is_struct(viewport, ViewPort), do: {:ok, viewport}
  defp get_viewport(name) when is_atom(name) do
    case Process.whereis(name) do
      nil -> {:error, "ViewPort #{inspect(name)} not found"}
      pid -> ViewPort.info(pid)
    end
  end
  defp get_viewport(pid) when is_pid(pid), do: ViewPort.info(pid)
  
  # ============================================================================
  # Backwards Compatibility - Deprecated Functions
  # ============================================================================
  
  @doc false
  @deprecated "Scene hierarchy not available through public API"
  def scene_tree(_viewport_name \\ :main_viewport) do
    IO.puts("⚠️  Scene hierarchy is not available through the public ViewPort interface")
    IO.puts("Use inspect_viewport() to see graphs and semantic content instead")
  end
  
  @doc false  
  @deprecated "Use inspect_viewport/1 instead"
  def inspect_app(viewport_name \\ :main_viewport) do
    inspect_viewport(viewport: viewport_name)
  end
  
  @doc false
  def list_graphs(viewport_name \\ :main_viewport) do
    inspect_viewport(viewport: viewport_name, show: :graphs)
  end
  
  @doc false
  def semantic_summary(viewport_name \\ :main_viewport) do
    inspect_viewport(viewport: viewport_name, show: :semantic)
  end
  
  @doc false
  def find_semantic(type, viewport_name \\ :main_viewport) do
    find(type, viewport_name)
  end
  
  @doc false
  def show_semantic(viewport_name \\ :main_viewport) do
    semantic(viewport_name)
  end
  
  @doc false
  def inspect_scene(scene_id, viewport_name \\ :main_viewport) do
    IO.puts("📌 Note: Use inspect_viewport(graph: \"#{scene_id}\") for better output")
    inspect_viewport(viewport: viewport_name, graph: scene_id, verbose: true)
  end
  
  @doc false
  def inspect_graph(graph_key, viewport_name \\ :main_viewport) do
    inspect_viewport(viewport: viewport_name, graph: graph_key, verbose: true)
  end
end