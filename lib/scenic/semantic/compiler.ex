#
#  Semantic Compiler for Scenic
#  Compiles scene graphs into semantic trees for testing/automation
#

defmodule Scenic.Semantic.Compiler do
  @moduledoc """
  Compiles scene graphs into semantic trees with element registration.

  This module walks a Scenic graph and extracts semantic information about
  elements (buttons, text fields, etc.) that have IDs or explicit semantic
  metadata. This enables Playwright-like testing and AI automation.

  ## Phase 1 Limitations

  This is Phase 1 implementation with simplified coordinate calculation:
  - Basic bounds from primitive data
  - No transform matrix calculations yet (Phase 2)
  - No component sub-scene handling yet (Phase 3)
  """

  alias Scenic.Graph

  defmodule Entry do
    @moduledoc """
    Represents a semantic element in the scene graph.

    Contains all information needed to find, query, and interact with
    an element programmatically.
    """

    @type bounds :: %{
            left: number(),
            top: number(),
            width: number(),
            height: number()
          }

    @type t :: %__MODULE__{
            id: atom() | binary(),
            type: atom(),
            module: module(),
            parent_id: atom() | binary() | nil,
            children: list(atom() | binary()),
            local_bounds: bounds(),
            screen_bounds: bounds(),
            clickable: boolean(),
            focusable: boolean(),
            label: String.t() | nil,
            role: atom() | nil,
            value: any(),
            hidden: boolean(),
            z_index: integer(),
            metadata: map()
          }

    defstruct [
      :id,
      :type,
      :module,
      :parent_id,
      children: [],
      local_bounds: %{left: 0, top: 0, width: 0, height: 0},
      screen_bounds: %{left: 0, top: 0, width: 0, height: 0},
      clickable: false,
      focusable: false,
      label: nil,
      role: nil,
      value: nil,
      hidden: false,
      z_index: 0,
      metadata: %{}
    ]
  end

  @doc """
  Compiles a graph into semantic entries.

  ## Options

  - `:parent_id` - ID of parent scene (for component sub-scenes)

  ## Returns

  `{:ok, entries}` where entries is a list of `Entry` structs
  """
  @spec compile(Graph.t(), keyword()) :: {:ok, list(Entry.t())}
  def compile(%Graph{primitives: primitives}, opts \\ []) do
    parent_id = opts[:parent_id]

    # Start from root primitive (uid 0)
    {entries, _} =
      compile_primitive(
        [],
        0,
        primitives,
        parent_id,
        0
      )

    {:ok, Enum.reverse(entries)}
  end

  # Compile a single primitive and its children
  defp compile_primitive(entries, uid, all_primitives, parent_id, z_index) do
    primitive = all_primitives[uid]

    # Skip if primitive doesn't exist
    if primitive == nil do
      {entries, z_index}
    else
      # Check if this primitive should be registered
      if should_register?(primitive) do
        # Build semantic entry
        entry = build_semantic_entry(primitive, parent_id, z_index)

        # Add to entries
        entries = [entry | entries]

        # Process children with this entry as parent
        compile_children(
          entries,
          primitive,
          all_primitives,
          entry.id,
          z_index + 1
        )
      else
        # Not registered, but process children anyway
        compile_children(
          entries,
          primitive,
          all_primitives,
          parent_id,
          z_index
        )
      end
    end
  end

  # Process children primitives
  defp compile_children(entries, primitive, all_primitives, parent_id, z_index) do
    case primitive.module do
      Scenic.Primitive.Group ->
        # Group has list of child UIDs in its data
        child_uids = primitive.data || []

        Enum.reduce(child_uids, {entries, z_index}, fn child_uid, {acc_entries, acc_z} ->
          compile_primitive(acc_entries, child_uid, all_primitives, parent_id, acc_z)
        end)

      Scenic.Primitive.Component ->
        # Components create sub-scenes - Phase 3 will handle this
        # For now, just register the component itself
        {entries, z_index}

      _ ->
        # Other primitives don't have children
        {entries, z_index}
    end
  end

  # Determine if a primitive should be registered in the semantic table
  defp should_register?(primitive) do
    # Register if:
    # 1. Has explicit :id field (not :_root_)
    # 2. Has explicit :semantic metadata in opts
    # 3. Is a semantic primitive (button, text_field, etc.) - Phase 3

    has_id = primitive.id != nil && primitive.id != :_root_
    has_semantic = get_in(normalize_opts(primitive.opts), [:semantic]) != nil

    has_id or has_semantic
  end

  # Normalize opts to always be a map (can be a list or map)
  defp normalize_opts(opts) when is_map(opts), do: opts
  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(_), do: %{}

  # Build a semantic entry from a primitive
  defp build_semantic_entry(primitive, parent_id, z_index) do
    local_bounds = calculate_local_bounds(primitive)
    screen_bounds = apply_transforms(local_bounds, primitive.transforms)

    %Entry{
      id: get_semantic_id(primitive),
      type: get_semantic_type(primitive),
      module: primitive.module,
      parent_id: parent_id,
      local_bounds: local_bounds,
      screen_bounds: screen_bounds,
      # Extract semantic properties
      clickable: is_clickable?(primitive),
      focusable: is_focusable?(primitive),
      label: get_label(primitive),
      role: get_role(primitive),
      value: primitive.data,
      hidden: Map.get(primitive.styles || %{}, :hidden, false),
      z_index: z_index
    }
  end

  # Apply transforms to local bounds to get screen bounds
  # Phase 1: Only handles translate transform
  defp apply_transforms(bounds, nil), do: bounds
  defp apply_transforms(bounds, transforms) when map_size(transforms) == 0, do: bounds

  defp apply_transforms(bounds, transforms) do
    case Map.get(transforms, :translate) do
      {tx, ty} when is_number(tx) and is_number(ty) ->
        %{bounds | left: bounds.left + tx, top: bounds.top + ty}

      _ ->
        bounds
    end
  end

  # Extract semantic ID from primitive
  defp get_semantic_id(primitive) do
    # Scenic stores ID in primitive.id field, not in opts
    primitive.id ||
      get_in(normalize_opts(primitive.opts), [:semantic, :id]) ||
      :unnamed
  end

  # Determine semantic type
  defp get_semantic_type(primitive) do
    opts = normalize_opts(primitive.opts)
    # Try explicit semantic type first
    case get_in(opts, [:semantic, :type]) do
      nil ->
        # Infer from module
        case primitive.module do
          Scenic.Primitive.Component -> :component
          Scenic.Primitive.Group -> :group
          Scenic.Primitive.Text -> :text
          Scenic.Primitive.Rectangle -> :rect
          Scenic.Primitive.RoundedRectangle -> :rounded_rect
          Scenic.Primitive.Circle -> :circle
          Scenic.Primitive.Line -> :line
          _ -> :unknown
        end

      type ->
        type
    end
  end

  # Calculate local bounds from primitive data
  defp calculate_local_bounds(primitive) do
    case primitive.module do
      Scenic.Primitive.Rectangle ->
        # Rectangle data: {width, height}
        case primitive.data do
          {w, h} -> %{left: 0, top: 0, width: w, height: h}
          _ -> default_bounds()
        end

      Scenic.Primitive.RoundedRectangle ->
        # RoundedRectangle data: {width, height, radius}
        case primitive.data do
          {w, h, _r} -> %{left: 0, top: 0, width: w, height: h}
          _ -> default_bounds()
        end

      Scenic.Primitive.Circle ->
        # Circle data: radius
        case primitive.data do
          r when is_number(r) ->
            %{left: -r, top: -r, width: r * 2, height: r * 2}

          _ ->
            default_bounds()
        end

      Scenic.Primitive.Text ->
        # Text - we don't know bounds without font metrics
        # Phase 2 will improve this
        %{left: 0, top: 0, width: 100, height: 20}

      Scenic.Primitive.Component ->
        # Components store dimensions in opts as :width and :height
        opts = normalize_opts(primitive.opts)

        # Try explicit semantic bounds first, then fall back to opts
        case get_in(opts, [:semantic, :bounds]) do
          %{} = bounds ->
            bounds

          _ ->
            # Read width/height from opts (common for buttons, etc.)
            width = Map.get(opts, :width, 0)
            height = Map.get(opts, :height, 0)
            %{left: 0, top: 0, width: width, height: height}
        end

      _ ->
        default_bounds()
    end
  end

  defp default_bounds() do
    %{left: 0, top: 0, width: 0, height: 0}
  end

  # Determine if primitive is clickable
  defp is_clickable?(primitive) do
    opts = normalize_opts(primitive.opts)
    # Explicit semantic metadata
    case get_in(opts, [:semantic, :clickable]) do
      nil ->
        # Infer from type
        case primitive.module do
          Scenic.Primitive.Component -> true
          _ -> false
        end

      clickable ->
        clickable
    end
  end

  # Determine if primitive is focusable
  defp is_focusable?(primitive) do
    get_in(normalize_opts(primitive.opts), [:semantic, :focusable]) || false
  end

  # Extract label
  defp get_label(primitive) do
    opts = normalize_opts(primitive.opts)
    # Try semantic label first
    case get_in(opts, [:semantic, :label]) do
      nil ->
        # For text primitives, use the text itself
        case primitive.module do
          Scenic.Primitive.Text when is_binary(primitive.data) ->
            primitive.data

          _ ->
            nil
        end

      label ->
        label
    end
  end

  # Extract role
  defp get_role(primitive) do
    get_in(normalize_opts(primitive.opts), [:semantic, :role])
  end
end
