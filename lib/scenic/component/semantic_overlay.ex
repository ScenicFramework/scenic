defmodule Scenic.Component.SemanticOverlay do
  @moduledoc """
  A component that visualizes semantic information as an overlay on your scene.
  
  This is useful during development to see what semantic annotations are
  available on different GUI elements.
  
  ## Usage
  
  Add to your scene's graph:
  
      @graph Graph.build()
        |> semantic_overlay(viewport: viewport, enabled: true)
  
  Toggle visibility with:
  
      Scene.cast(scene_pid, {:semantic_overlay, :toggle})
      Scene.cast(scene_pid, {:semantic_overlay, :show})
      Scene.cast(scene_pid, {:semantic_overlay, :hide})
  """
  
  use Scenic.Component
  
  alias Scenic.{Graph, ViewPort}
  
  # Component callbacks
  
  @impl Scenic.Component
  def validate(params) when is_list(params) do
    if Keyword.has_key?(params, :viewport) do
      {:ok, params}
    else
      {:error, "SemanticOverlay requires a :viewport option"}
    end
  end

  def validate(_), do: {:error, "SemanticOverlay params must be a keyword list with :viewport"}
  
  @impl Scenic.Scene
  def init(scene, params, _opts) do
    viewport = Keyword.fetch!(params, :viewport)
    enabled = Keyword.get(params, :enabled, false)
    graph_key = Keyword.get(params, :graph_key, :main)
    
    graph = Graph.build()
    
    if enabled do
      Process.send_after(self(), :update_overlay, 100)
    end
    
    scene =
      scene
      |> assign(
        viewport: viewport,
        enabled: enabled,
        graph_key: graph_key
      )
      |> push_graph(graph)
    
    {:ok, scene}
  end
  
  @impl GenServer
  def handle_cast({:semantic_overlay, :toggle}, scene) do
    enabled = scene.assigns.enabled
    
    if not enabled do
      send(self(), :update_overlay)
    end
    
    new_enabled = not enabled
    
    graph = if new_enabled do
      build_overlay(scene.assigns)
    else
      Graph.build()
    end
    
    scene =
      scene
      |> assign(enabled: new_enabled)
      |> push_graph(graph)
    
    {:noreply, scene}
  end
  
  def handle_cast({:semantic_overlay, :show}, scene) do
    if not scene.assigns.enabled do
      send(self(), :update_overlay)
    end
    
    graph = build_overlay(scene.assigns)
    
    scene =
      scene
      |> assign(enabled: true)
      |> push_graph(graph)
    
    {:noreply, scene}
  end
  
  def handle_cast({:semantic_overlay, :hide}, scene) do
    graph = Graph.build()
    
    scene =
      scene
      |> assign(enabled: false)
      |> push_graph(graph)
    
    {:noreply, scene}
  end
  
  @impl GenServer
  def handle_info(:update_overlay, %{assigns: %{enabled: false}} = scene) do
    {:noreply, scene}
  end
  
  def handle_info(:update_overlay, %{assigns: %{enabled: true}} = scene) do
    graph = build_overlay(scene.assigns)
    
    # Schedule next update
    Process.send_after(self(), :update_overlay, 1000)
    
    scene = push_graph(scene, graph)
    
    {:noreply, scene}
  end
  
  # Private functions
  
  defp build_overlay(assigns) do
    case ViewPort.get_semantic(assigns.viewport, assigns.graph_key) do
      {:ok, info} ->
        build_semantic_visualization(info)
      {:error, _} ->
        Graph.build()
        |> Scenic.Primitives.text("No semantic info available",
            font_size: 12,
            translate: {10, 20},
            fill: :red
          )
    end
  end
  
  defp build_semantic_visualization(info) do
    # Start with base graph
    graph = Graph.build()
    
    # Add background for readability
    graph = graph
    |> Scenic.Primitives.rect({300, 400},
        fill: {:black, 200},
        translate: {10, 10}
      )
    
    # Add title
    graph = graph
    |> Scenic.Primitives.text("Semantic Overlay",
        font_size: 16,
        translate: {20, 30},
        fill: :white
      )
    
    # Add summary
    elem_count = map_size(info.elements)
    type_count = map_size(info.by_type)
    
    graph = graph
    |> Scenic.Primitives.text("#{elem_count} elements, #{type_count} types",
        font_size: 12,
        translate: {20, 50},
        fill: :light_gray
      )
    
    # List elements by type
    {graph, _y_offset} = 
      info.by_type
      |> Enum.sort()
      |> Enum.reduce({graph, 70}, fn {type, ids}, {g, y} ->
        # Type header
        g = g
        |> Scenic.Primitives.text("#{type}:",
            font_size: 14,
            translate: {20, y},
            fill: :cyan
          )
        
        # List elements of this type
        {g, y} = Enum.reduce(ids, {g, y + 20}, fn id, {g2, y2} ->
          elem = Map.get(info.elements, id)
          label = format_element(elem)
          
          g2 = g2
          |> Scenic.Primitives.text(label,
              font_size: 11,
              translate: {30, y2},
              fill: :white
            )
          
          {g2, y2 + 15}
        end)
        
        {g, y + 10}
      end)
    
    graph
  end
  
  defp format_element(elem) do
    case elem.semantic.type do
      :button ->
        "Button: \"#{elem.semantic.label}\""
      :text_buffer ->
        content_preview = if elem.content do
          String.slice(elem.content || "", 0, 20)
        else
          "(empty)"
        end
        "Buffer #{elem.semantic.buffer_id}: #{content_preview}"
      :text_input ->
        "Input: #{elem.semantic.name}"
      :menu ->
        "Menu: #{elem.semantic.name}"
      _other ->
        "#{inspect(elem.id)}: #{inspect(elem.semantic)}"
    end
  end
end
