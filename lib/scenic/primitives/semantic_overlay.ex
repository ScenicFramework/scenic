defmodule Scenic.Primitives.SemanticOverlay do
  @moduledoc """
  Convenience functions for adding a semantic overlay to your scene.
  
  The semantic overlay displays real-time information about semantic
  annotations in your GUI, useful for development and debugging.
  """
  
  alias Scenic.Graph
  alias Scenic.Component.SemanticOverlay
  
  @doc """
  Add a semantic overlay component to a graph.
  
  ## Examples
  
      @graph Graph.build()
        |> semantic_overlay(viewport: viewport)
        
      # With options
      @graph Graph.build()  
        |> semantic_overlay(
          viewport: viewport,
          enabled: true,
          translate: {500, 10}
        )
  """
  def semantic_overlay(graph, opts \\ [])
  
  def semantic_overlay(%Graph{} = graph, opts) do
    # Extract component options
    viewport = Keyword.fetch!(opts, :viewport)
    enabled = Keyword.get(opts, :enabled, false)
    graph_key = Keyword.get(opts, :graph_key, :main)
    
    # Extract primitive options
    styles = Keyword.take(opts, [:translate, :scale, :rotate, :pin, :hidden])
    
    # Add the component
    Graph.add_to(
      graph,
      {SemanticOverlay, [viewport: viewport, enabled: enabled, graph_key: graph_key]},
      Keyword.merge([id: :semantic_overlay], styles)
    )
  end
end