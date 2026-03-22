defmodule Scenic.SSM.Compiler do
  @moduledoc """
  Unified graph compiler for the Semantic Scene Model.

  Walks the graph once and produces both:
  - Input routing list (7-tuples, backwards-compatible with ViewPort hit-testing)
  - Semantic entries (%Entry{} structs for ETS storage and queries)

  Replaces the previous two-pass approach (compile_input + Semantic.Compiler).
  """

  alias Scenic.{Graph, Math, Primitive}
  alias Scenic.Primitive.Transform
  alias Scenic.Semantic.Compiler.Entry

  @doc """
  Compile a graph into SSM data.

  Returns `{:ok, {input_list, input_types, semantic_entries}}` where:
  - `input_list` — list of 7-tuples for hit-testing (same format as old compile_input)
  - `input_types` — flat list of all input types declared across all primitives
  - `semantic_entries` — list of %Entry{} structs for ETS storage
  """
  @spec compile(Graph.t()) :: {:ok, {list(), list(), list(Entry.t())}}
  def compile(%Graph{primitives: primitives}) do
    acc = %{input: [], semantic: [], z_index: 0}

    result = walk(acc, 0, primitives, nil, Math.Matrix.identity(), nil)

    # Extract input types from the compiled input list
    input_types =
      result.input
      |> Enum.flat_map(fn {_mod, _data, _tx, _pid, types, _id, _scissor} -> types end)
      |> Enum.uniq()

    {:ok, {result.input, input_types, Enum.reverse(result.semantic)}}
  end

  # ── Graph walker — unified traversal ──

  defp walk(acc, uid, primitives, parent_id, parent_tx, scissor) do
    case primitives[uid] do
      nil -> acc
      primitive -> walk_primitive(acc, primitive, primitives, parent_id, parent_tx, scissor)
    end
  end

  # Skip hidden primitives
  defp walk_primitive(acc, %Primitive{styles: %{hidden: true}}, _, _, _, _), do: acc

  # Skip script primitives
  defp walk_primitive(acc, %Primitive{module: Primitive.Script}, _, _, _, _), do: acc

  # Groups: compute transform + scissor, recurse into children
  defp walk_primitive(
         acc,
         %Primitive{module: Primitive.Group, data: ids, transforms: txs, styles: styles} = prim,
         primitives,
         parent_id,
         parent_tx,
         scissor
       ) do
    local_tx = compose_tx(txs, parent_tx)

    # Groups can set scissor clipping for children
    child_scissor =
      case Map.get(styles, :scissor) do
        {w, h} -> {local_tx, w, h}
        _ -> scissor
      end

    # Register group in semantic table if it has an id
    group_id = if has_semantic_id?(prim), do: prim.id, else: parent_id

    acc = if has_semantic_id?(prim) do
      entry = build_semantic_entry(prim, parent_id, acc.z_index, local_tx)
      %{acc | semantic: [entry | acc.semantic], z_index: acc.z_index + 1}
    else
      acc
    end

    # Recurse into children
    Enum.reduce(ids || [], acc, fn child_uid, child_acc ->
      walk(child_acc, child_uid, primitives, group_id, local_tx, child_scissor)
    end)
  end

  # Components: produce input tuple + semantic entry
  defp walk_primitive(
         acc,
         %Primitive{module: Primitive.Component, data: {_, _, name}, transforms: txs} = prim,
         _primitives,
         parent_id,
         parent_tx,
         scissor
       ) do
    local_tx = compose_tx(txs, parent_tx)

    # Always add to input list (components are hit-test containers)
    input = [{Primitive.Component, name, local_tx, self(), [], nil, scissor} | acc.input]

    # Add to semantic table if it has an id or semantic metadata
    semantic = if has_semantic_id?(prim) or has_semantic_meta?(prim) do
      entry = build_semantic_entry(prim, parent_id, acc.z_index, local_tx)
      [entry | acc.semantic]
    else
      acc.semantic
    end

    %{acc | input: input, semantic: semantic, z_index: acc.z_index + 1}
  end

  # Primitives with input: styles — produce input tuple + maybe semantic entry
  defp walk_primitive(
         acc,
         %Primitive{styles: %{input: input_types}, id: id, module: module, data: data, transforms: txs} = prim,
         _primitives,
         parent_id,
         parent_tx,
         scissor
       ) do
    local_tx = compose_tx(txs, parent_tx)

    # Add to input list (has input handlers)
    input = [{module, data, local_tx, self(), input_types, id, scissor} | acc.input]

    # Add to semantic table if it has an id or semantic metadata
    semantic = if has_semantic_id?(prim) or has_semantic_meta?(prim) do
      entry = build_semantic_entry(prim, parent_id, acc.z_index, local_tx)
      [entry | acc.semantic]
    else
      acc.semantic
    end

    %{acc | input: input, semantic: semantic, z_index: acc.z_index + 1}
  end

  # Primitives without input but with semantic id — semantic only
  defp walk_primitive(acc, %Primitive{} = prim, _primitives, parent_id, parent_tx, _scissor) do
    if has_semantic_id?(prim) or has_semantic_meta?(prim) do
      local_tx = compose_tx(prim.transforms, parent_tx)
      entry = build_semantic_entry(prim, parent_id, acc.z_index, local_tx)
      %{acc | semantic: [entry | acc.semantic], z_index: acc.z_index + 1}
    else
      acc
    end
  end

  # ── Helpers ──

  defp has_semantic_id?(prim), do: prim.id != nil and prim.id != :_root_

  defp has_semantic_meta?(prim) do
    opts = normalize_opts(prim.opts)
    get_in(opts, [:semantic]) != nil
  end

  defp compose_tx(txs, parent_tx) do
    cond do
      txs == %{} -> parent_tx
      txs -> Math.Matrix.mul(parent_tx, Transform.combine(txs))
    end
  end

  # ── Semantic entry building ──

  defp build_semantic_entry(primitive, parent_id, z_index, _screen_tx) do
    local_bounds = calculate_local_bounds(primitive)
    # Phase 1: screen_bounds from primitive transforms only
    # Phase 2: will use full screen_tx matrix
    screen_bounds = apply_transforms(local_bounds, primitive.transforms)

    input_types = Map.get(primitive.styles || %{}, :input, [])

    %Entry{
      id: semantic_id(primitive),
      type: semantic_type(primitive),
      module: primitive.module,
      parent_id: parent_id,
      local_bounds: local_bounds,
      screen_bounds: screen_bounds,
      clickable: is_clickable?(primitive, input_types),
      focusable: is_focusable?(primitive),
      label: get_label(primitive),
      role: get_role(primitive),
      value: primitive.data,
      hidden: Map.get(primitive.styles || %{}, :hidden, false),
      z_index: z_index
    }
  end

  defp semantic_id(prim) do
    prim.id ||
      get_in(normalize_opts(prim.opts), [:semantic, :id]) ||
      :unnamed
  end

  defp semantic_type(prim) do
    case get_in(normalize_opts(prim.opts), [:semantic, :type]) do
      nil ->
        case prim.module do
          Primitive.Component -> :component
          Primitive.Group -> :group
          Scenic.Primitive.Text -> :text
          Scenic.Primitive.Rectangle -> :rect
          Scenic.Primitive.RoundedRectangle -> :rounded_rect
          Scenic.Primitive.Circle -> :circle
          Scenic.Primitive.Line -> :line
          _ -> :unknown
        end
      type -> type
    end
  end

  defp calculate_local_bounds(primitive) do
    case primitive.module do
      Scenic.Primitive.Rectangle ->
        case primitive.data do
          {w, h} -> %{left: 0, top: 0, width: w, height: h}
          _ -> %{left: 0, top: 0, width: 0, height: 0}
        end

      Scenic.Primitive.RoundedRectangle ->
        case primitive.data do
          {w, h, _r} -> %{left: 0, top: 0, width: w, height: h}
          _ -> %{left: 0, top: 0, width: 0, height: 0}
        end

      Scenic.Primitive.Circle ->
        case primitive.data do
          r when is_number(r) -> %{left: -r, top: -r, width: r * 2, height: r * 2}
          _ -> %{left: 0, top: 0, width: 0, height: 0}
        end

      Scenic.Primitive.Text ->
        %{left: 0, top: 0, width: 100, height: 20}

      Primitive.Component ->
        opts = normalize_opts(primitive.opts)
        case get_in(opts, [:semantic, :bounds]) do
          %{} = bounds -> bounds
          _ ->
            w = Map.get(opts, :width, 0)
            h = Map.get(opts, :height, 0)
            %{left: 0, top: 0, width: w, height: h}
        end

      _ ->
        %{left: 0, top: 0, width: 0, height: 0}
    end
  end

  defp apply_transforms(bounds, nil), do: bounds
  defp apply_transforms(bounds, txs) when map_size(txs) == 0, do: bounds
  defp apply_transforms(bounds, txs) do
    case Map.get(txs, :translate) do
      {tx, ty} when is_number(tx) and is_number(ty) ->
        %{bounds | left: bounds.left + tx, top: bounds.top + ty}
      _ -> bounds
    end
  end

  defp is_clickable?(primitive, input_types) do
    case get_in(normalize_opts(primitive.opts), [:semantic, :clickable]) do
      nil ->
        primitive.module == Primitive.Component or
          :cursor_button in input_types
      clickable -> clickable
    end
  end

  defp is_focusable?(primitive) do
    get_in(normalize_opts(primitive.opts), [:semantic, :focusable]) || false
  end

  defp get_label(primitive) do
    case get_in(normalize_opts(primitive.opts), [:semantic, :label]) do
      nil ->
        if primitive.module == Scenic.Primitive.Text and is_binary(primitive.data) do
          primitive.data
        end
      label -> label
    end
  end

  defp get_role(primitive) do
    get_in(normalize_opts(primitive.opts), [:semantic, :role])
  end

  defp normalize_opts(opts) when is_map(opts), do: opts
  defp normalize_opts(opts) when is_list(opts), do: Enum.into(opts, %{})
  defp normalize_opts(_), do: %{}
end
