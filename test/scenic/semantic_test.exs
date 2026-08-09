defmodule Scenic.SemanticTest do
  use ExUnit.Case
  alias Scenic.{ViewPort, Graph, Semantic}
  alias Scenic.Semantic.Query
  
  setup_all do
    # Start the Scenic supervisor if not already started
    case Process.whereis(:scenic) do
      nil ->
        {:ok, _} = Scenic.start_link([])
      _pid ->
        :ok
    end
    :ok
  end
  
  setup do
    # Generate a unique name for each test
    name = :"semantic_test_vp_#{System.unique_integer([:positive])}"
    
    {:ok, viewport} = ViewPort.start([
      name: name,
      size: {800, 600},
      default_scene: {Scenic.Scene, nil}
    ])
    
    on_exit(fn ->
      # Clean up the viewport
      ViewPort.stop(viewport)
    end)
    
    {:ok, viewport: viewport}
  end
  
  test "semantic info is stored when graph is put", %{viewport: viewport} do
    graph = 
      Graph.build()
      |> Scenic.Primitives.rect({100, 40}, semantic: Semantic.button("Click me"))
      |> Scenic.Primitives.text("Click me", semantic: %{type: :label, for: :button})
    
    ViewPort.put_graph(viewport, :test_graph, graph)
    
    assert {:ok, info} = Query.get_semantic_info(viewport, :test_graph)
    assert map_size(info.elements) == 2
    assert info.by_type.button != nil
  end
  
  test "can query buttons by label", %{viewport: viewport} do
    graph = 
      Graph.build()
      |> Scenic.Primitives.rect({100, 40}, semantic: Semantic.button("Submit"))
      |> Scenic.Primitives.rect({100, 40}, semantic: Semantic.button("Cancel"))
    
    ViewPort.put_graph(viewport, :test_graph, graph)
    
    assert {:ok, submit_btn} = Query.get_button_by_label(viewport, "Submit", :test_graph)
    assert submit_btn.semantic.label == "Submit"
    
    assert {:ok, buttons} = Query.get_buttons(viewport, :test_graph)
    assert length(buttons) == 2
  end
  
  test "can query text buffer content", %{viewport: viewport} do
    buffer_content = "Hello, World!"
    
    graph = 
      Graph.build()
      |> Scenic.Primitives.text(buffer_content, 
           semantic: Semantic.text_buffer(buffer_id: 1))
    
    ViewPort.put_graph(viewport, :test_graph, graph)
    
    assert {:ok, ^buffer_content} = Query.get_buffer_text(viewport, 1, :test_graph)
  end
end