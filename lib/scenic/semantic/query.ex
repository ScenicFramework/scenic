defmodule Scenic.Semantic.Query do
  @moduledoc """
  Query API for semantic information in Scenic ViewPorts.
  
  Provides testing-friendly functions to find and inspect GUI elements
  based on their semantic meaning rather than visual properties.
  """
  
  @doc """
  Get semantic information for a graph.
  """
  def get_semantic_info(viewport, graph_key \\ :_root_) do
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
  def find_by_type(viewport, type, graph_key \\ :_root_) do
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
  def find_one(viewport, type, filter_fn, graph_key \\ :_root_) do
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
  def get_buffer_text(viewport, buffer_id, graph_key \\ :_root_) do
    with {:ok, buffer} <- find_one(viewport, :text_buffer, fn elem ->
           elem.semantic.buffer_id == buffer_id
         end, graph_key) do
      {:ok, buffer.content || ""}
    end
  end
  
  @doc """
  Find all buttons in the viewport.
  """
  def get_buttons(viewport, graph_key \\ :_root_) do
    find_by_type(viewport, :button, graph_key)
  end
  
  @doc """
  Find button by label.
  """
  def get_button_by_label(viewport, label, graph_key \\ :_root_) do
    find_one(viewport, :button, fn elem ->
      elem.semantic.label == label
    end, graph_key)
  end
  
  @doc """
  Get all editable text content.
  """
  def get_editable_content(viewport, graph_key \\ :_root_) do
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
  def inspect_semantic_tree(viewport, graph_key \\ :_root_) do
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