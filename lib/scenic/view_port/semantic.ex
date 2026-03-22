#
#  Semantic Query API for Scenic ViewPort
#  Provides functions to find, query, and interact with semantic elements
#

defmodule Scenic.ViewPort.Semantic do
  @moduledoc """
  Query API for semantic elements in a Scenic ViewPort.

  This module provides functions to find and interact with elements by their
  semantic IDs, similar to how Playwright/Puppeteer work with web elements.

  ## Example

      {:ok, viewport} = Scenic.ViewPort.info(:main_viewport)

      # Find element by ID
      {:ok, button} = Scenic.ViewPort.Semantic.find_element(viewport, :save_button)

      # Find all clickable elements
      {:ok, elements} = Scenic.ViewPort.Semantic.find_clickable_elements(viewport)

      # Click element by ID
      {:ok, center} = Scenic.ViewPort.Semantic.click_element(viewport, :save_button)
  """

  alias Scenic.ViewPort
  alias Scenic.Semantic.Compiler.Entry

  @doc """
  Find element by ID.

  Returns the full semantic entry with bounds and metadata.

  ## Parameters

  - `viewport` - ViewPort struct or PID
  - `element_id` - Atom or string ID of the element

  ## Returns

  - `{:ok, entry}` - Entry struct with element data
  - `{:error, :not_found}` - Element not found
  - `{:error, :semantic_disabled}` - Semantic system not enabled
  """
  @spec find_element(ViewPort.t() | pid(), atom() | tuple() | binary()) ::
          {:ok, Entry.t()} | {:error, atom()}
  def find_element(viewport, element_id)

  def find_element(%ViewPort{} = viewport, element_id) do
    case find_element_with_scene(viewport, element_id) do
      {:ok, entry, _scene_name} -> {:ok, entry}
      error -> error
    end
  end

  def find_element(pid, element_id) when is_pid(pid) or is_atom(pid) do
    case ViewPort.info(pid) do
      {:ok, viewport} -> find_element(viewport, element_id)
      error -> error
    end
  end

  @doc """
  Find all clickable elements, optionally filtered.

  ## Parameters

  - `viewport` - ViewPort struct or PID
  - `filter` - Optional map with filter criteria:
    - `:id` - Match element ID (partial string match)
    - `:type` - Match element type
    - `:label` - Match label text (partial string match)

  ## Returns

  - `{:ok, elements}` - List of Entry structs
  - `{:error, reason}` - Error occurred
  """
  @spec find_clickable_elements(ViewPort.t() | pid(), map()) ::
          {:ok, list(Entry.t())} | {:error, atom()}
  def find_clickable_elements(viewport, filter \\ %{})

  def find_clickable_elements(%ViewPort{} = viewport, filter) do
    if viewport.semantic_enabled do
      elements =
        viewport.semantic_table
        |> :ets.tab2list()
        |> Enum.map(&elem(&1, 1))
        |> Enum.filter(& &1.clickable)
        |> apply_filters(filter)
        |> Enum.sort_by(& &1.z_index)

      {:ok, elements}
    else
      {:error, :semantic_disabled}
    end
  end

  def find_clickable_elements(pid, filter) when is_pid(pid) or is_atom(pid) do
    case ViewPort.info(pid) do
      {:ok, viewport} -> find_clickable_elements(viewport, filter)
      error -> error
    end
  end

  @doc """
  Get element at screen coordinates.

  Returns the top-most clickable element at the given point.

  ## Parameters

  - `viewport` - ViewPort struct or PID
  - `x` - X coordinate
  - `y` - Y coordinate

  ## Returns

  - `{:ok, entry}` - Element at point
  - `{:error, :not_found}` - No element at point
  """
  @spec element_at_point(ViewPort.t() | pid(), number(), number()) ::
          {:ok, Entry.t()} | {:error, atom()}
  def element_at_point(viewport, x, y)

  def element_at_point(%ViewPort{} = viewport, x, y) do
    if viewport.semantic_enabled do
      result =
        viewport.semantic_table
        |> :ets.tab2list()
        |> Enum.map(&elem(&1, 1))
        |> Enum.filter(fn entry ->
          bounds = entry.screen_bounds

          x >= bounds.left &&
            x <= bounds.left + bounds.width &&
            y >= bounds.top &&
            y <= bounds.top + bounds.height
        end)
        |> Enum.max_by(& &1.z_index, fn -> nil end)

      case result do
        nil -> {:error, :not_found}
        entry -> {:ok, entry}
      end
    else
      {:error, :semantic_disabled}
    end
  end

  def element_at_point(pid, x, y) when is_pid(pid) or is_atom(pid) do
    case ViewPort.info(pid) do
      {:ok, viewport} -> element_at_point(viewport, x, y)
      error -> error
    end
  end

  @doc """
  Click element by ID.

  Finds the element, calculates its center, and sends mouse click events.
  Uses SSM screen_bounds (full transform chain) for accurate coordinates.

  ## Options

  - `:via` - How to deliver the click event:
    - `:driver` (default) — simulates real user input through the driver stack.
      Best for integration testing since it exercises the full pipeline.
    - `:viewport` — sends input directly to the viewport GenServer.
      Faster, works headless (no driver needed), same hit-testing.

  ## Parameters

  - `viewport` - ViewPort struct or PID
  - `element_id` - Atom or string ID of the element
  - `opts` - Keyword list of options

  ## Returns

  - `{:ok, {x, y}}` - Clicked at coordinates
  - `{:error, reason}` - Failed to click
  """
  @spec click_element(ViewPort.t() | pid(), atom() | binary(), keyword()) ::
          {:ok, {number(), number()}} | {:error, atom()}
  def click_element(viewport, element_id, opts \\ [])

  def click_element(%ViewPort{} = viewport, element_id, opts) do
    via = Keyword.get(opts, :via, :driver)

    with {:ok, element, scene_name} <- find_element_with_scene(viewport, element_id),
         {:ok, local_center} <- calculate_center(element.screen_bounds),
         {:ok, screen_center} <- to_screen_coords(viewport, scene_name, local_center) do
      do_click(viewport, screen_center, via)
      {:ok, screen_center}
    end
  end

  def click_element(pid, element_id, opts) when is_pid(pid) or is_atom(pid) do
    case ViewPort.info(pid) do
      {:ok, viewport} -> click_element(viewport, element_id, opts)
      error -> error
    end
  end

  @doc """
  Hover over element by ID.

  Moves the cursor to the element's center, triggering SSM-powered
  cursor_enter/cursor_leave events. Useful for testing hover effects.

  ## Options

  Same `:via` options as `click_element/3`.

  ## Returns

  - `{:ok, {x, y}}` - Hovered at coordinates
  - `{:error, reason}` - Failed to hover
  """
  @spec hover_element(ViewPort.t() | pid(), atom() | binary(), keyword()) ::
          {:ok, {number(), number()}} | {:error, atom()}
  def hover_element(viewport, element_id, opts \\ [])

  def hover_element(%ViewPort{} = viewport, element_id, opts) do
    via = Keyword.get(opts, :via, :driver)

    with {:ok, element, scene_name} <- find_element_with_scene(viewport, element_id),
         {:ok, local_center} <- calculate_center(element.screen_bounds),
         {:ok, screen_center} <- to_screen_coords(viewport, scene_name, local_center) do
      do_hover(viewport, screen_center, via)
      {:ok, screen_center}
    end
  end

  def hover_element(pid, element_id, opts) when is_pid(pid) or is_atom(pid) do
    case ViewPort.info(pid) do
      {:ok, viewport} -> hover_element(viewport, element_id, opts)
      error -> error
    end
  end

  @doc """
  Get hierarchical tree of semantic elements.

  ## Parameters

  - `viewport` - ViewPort struct or PID
  - `root_id` - Root element ID (default: "_root")

  ## Returns

  - `{:ok, tree}` - Nested map with element and children
  - `{:error, reason}` - Failed to build tree
  """
  @spec get_semantic_tree(ViewPort.t() | pid(), atom() | binary()) ::
          {:ok, map()} | {:error, atom()}
  def get_semantic_tree(viewport, root_id \\ :_root_)

  def get_semantic_tree(%ViewPort{} = viewport, root_id) do
    if viewport.semantic_enabled do
      tree = build_tree(viewport, root_id)
      {:ok, tree}
    else
      {:error, :semantic_disabled}
    end
  end

  def get_semantic_tree(pid, root_id) when is_pid(pid) or is_atom(pid) do
    case ViewPort.info(pid) do
      {:ok, viewport} -> get_semantic_tree(viewport, root_id)
      error -> error
    end
  end

  # Private helpers

  # Find element and return its scene_name (needed for transform chain lookup)
  defp find_element_with_scene(%ViewPort{} = viewport, element_id) do
    if viewport.semantic_enabled do
      case lookup_in_index(viewport.semantic_index, element_id) do
        {:ok, {scene_name, _entry_id} = key} ->
          case :ets.lookup(viewport.semantic_table, key) do
            [{^key, entry}] -> {:ok, entry, scene_name}
            [] -> {:error, :not_found}
          end

        :not_found ->
          {:error, :not_found}
      end
    else
      {:error, :semantic_disabled}
    end
  end

  # Convert local coordinates to screen coordinates by walking the scene transform chain.
  # Uses the viewport's scene_transforms (built from input_list component placement).
  defp to_screen_coords(%ViewPort{pid: pid}, scene_name, local_point) do
    case GenServer.call(pid, {:fetch_scene_tx, scene_name}) do
      {:ok, scene_tx} ->
        screen_point = Scenic.Math.Matrix.project_vector(scene_tx, local_point)
        {:ok, screen_point}

      {:error, :not_found} ->
        # Root scene or no transform found — local coords ARE screen coords
        {:ok, local_point}
    end
  end

  # Click via viewport — direct to GenServer, no driver needed
  defp do_click(viewport, center, :viewport) do
    ViewPort.input(viewport, {:cursor_button, {:btn_left, 1, [], center}})
    Process.sleep(10)
    ViewPort.input(viewport, {:cursor_button, {:btn_left, 0, [], center}})
  end

  # Click via driver — full pipeline integration test
  defp do_click(viewport, center, :driver) do
    case get_driver_state(viewport) do
      {:ok, driver_state} ->
        Scenic.Driver.send_input(driver_state, {:cursor_button, {:btn_left, 1, [], center}})
        Process.sleep(10)
        Scenic.Driver.send_input(driver_state, {:cursor_button, {:btn_left, 0, [], center}})

      {:error, _reason} ->
        # Fall back to viewport-direct if no driver available (headless)
        do_click(viewport, center, :viewport)
    end
  end

  # Hover via viewport — direct cursor_pos to trigger SSM hover tracking
  defp do_hover(viewport, center, :viewport) do
    ViewPort.input(viewport, {:cursor_pos, center})
  end

  # Hover via driver — full pipeline
  defp do_hover(viewport, center, :driver) do
    case get_driver_state(viewport) do
      {:ok, driver_state} ->
        Scenic.Driver.send_input(driver_state, {:cursor_pos, center})

      {:error, _reason} ->
        do_hover(viewport, center, :viewport)
    end
  end

  defp get_driver_state(%ViewPort{pid: viewport_pid}) do
    case :sys.get_state(viewport_pid, 5000) do
      %{driver_pids: [driver_pid | _]} ->
        {:ok, :sys.get_state(driver_pid, 5000)}

      %{driver_pids: []} ->
        {:error, :no_driver}

      _ ->
        {:error, :invalid_viewport_state}
    end
  rescue
    _ -> {:error, :driver_state_failed}
  end

  # Lookup element key in index table
  defp lookup_in_index(semantic_index, element_id) do
    id =
      case element_id do
        id when is_atom(id) -> id
        id when is_tuple(id) -> id
        id when is_binary(id) -> String.to_existing_atom(id)
      end

    case :ets.lookup(semantic_index, id) do
      [{^id, key}] -> {:ok, key}
      [] -> :not_found
    end
  rescue
    ArgumentError -> :not_found
  end

  # Apply filter criteria to element list
  defp apply_filters(elements, filter) when filter == %{} do
    elements
  end

  defp apply_filters(elements, filter) do
    elements
    |> filter_by_id(Map.get(filter, :id))
    |> filter_by_type(Map.get(filter, :type))
    |> filter_by_label(Map.get(filter, :label))
  end

  defp filter_by_id(elements, nil), do: elements

  defp filter_by_id(elements, id_filter) do
    Enum.filter(elements, fn entry ->
      id_str = Atom.to_string(entry.id)
      String.contains?(id_str, String.trim_leading(id_filter, ":"))
    end)
  end

  defp filter_by_type(elements, nil), do: elements

  defp filter_by_type(elements, type) do
    Enum.filter(elements, fn entry -> entry.type == type end)
  end

  defp filter_by_label(elements, nil), do: elements

  defp filter_by_label(elements, label_filter) do
    Enum.filter(elements, fn entry ->
      entry.label != nil && String.contains?(entry.label, label_filter)
    end)
  end

  # Calculate center point from bounds
  defp calculate_center(%{left: x, top: y, width: w, height: h}) do
    {:ok, {x + w / 2, y + h / 2}}
  end

  defp calculate_center(_), do: {:error, :invalid_bounds}

  # Build hierarchical tree from flat semantic table
  defp build_tree(viewport, parent_id) do
    case find_element(viewport, parent_id) do
      {:ok, parent} ->
        # Find children
        children =
          viewport.semantic_table
          |> :ets.tab2list()
          |> Enum.map(&elem(&1, 1))
          |> Enum.filter(fn entry -> entry.parent_id == parent_id end)
          |> Enum.map(fn child -> build_tree(viewport, child.id) end)

        parent
        |> Map.from_struct()
        |> Map.put(:children, children)

      {:error, _} ->
        %{id: parent_id, error: :not_found}
    end
  end
end
