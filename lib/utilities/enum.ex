defmodule Scenic.Utilities.Enum do
  @moduledoc false

  # ============================================================================
  def filter_reduce(enumerable, acc, action) when is_list(enumerable) do
    {filtered, acc} = do_filter_reduce_list(enumerable, {[], acc}, action)
    {Enum.reverse(filtered), acc}
  end

  def filter_reduce(enumerable, acc, action) when is_map(enumerable) do
    Enum.reduce(enumerable, {%{}, acc}, fn {k, v}, {filtered, acc} ->
      case action.({k, v}, acc) do
        {true, acc} -> {Map.put(filtered, k, v), acc}
        {false, acc} -> {filtered, acc}
      end
    end)
  end

  defp do_filter_reduce_list(enumerable, internal_acc, action)
  defp do_filter_reduce_list([], {filtered, acc}, _), do: {filtered, acc}

  defp do_filter_reduce_list([head | tail], {filtered, acc}, action) do
    case action.(head, acc) do
      {true, acc} -> do_filter_reduce_list(tail, {[head | filtered], acc}, action)
      {false, acc} -> do_filter_reduce_list(tail, {filtered, acc}, action)
    end
  end

  # ============================================================================
  # filter and map in one pass. Unlike Enum.filter_map, it does it with a single
  # callback, which allows filtering and mapping at the same time, which means
  # the code that ran during the filter can also affect the mapping
  def filter_map(enumerable, filter_mapper) when is_list(enumerable) do
    do_filter_map_list(enumerable, filter_mapper)
    |> Enum.reverse()
  end

  def filter_map(enumerable, filter_mapper) when is_map(enumerable) do
    Enum.reduce(enumerable, %{}, fn {k, v}, acc ->
      case filter_mapper.({k, v}) do
        {true, {k, v}} -> Map.put(acc, k, v)
        _ -> acc
      end
    end)
  end

  defp do_filter_map_list(enumerable, filter_mapper, filtered \\ [])
  defp do_filter_map_list([], _, filtered), do: filtered

  defp do_filter_map_list([head | tail], filter_mapper, filtered) do
    case filter_mapper.(head) do
      {true, mapped} -> do_filter_map_list(tail, filter_mapper, [mapped | filtered])
      _ -> do_filter_map_list(tail, filter_mapper, filtered)
    end
  end

  # ============================================================================
  # filter and map and reduce in one pass. Unlike Enum.filter_map, it does it with a single
  # callback, which allows filtering and mapping and reducing at the same time. This means
  # the code that ran during the filter can also affect the mapping and/or reduction

  def filter_map_reduce(enumerable, acc, action) when is_list(enumerable) do
    {new_list, acc} = do_filter_map_reduce_list(enumerable, acc, action)
    {Enum.reverse(new_list), acc}
  end

  def filter_map_reduce(enumerable, acc, action) when is_map(enumerable) do
    Enum.reduce(enumerable, {%{}, acc}, fn {k, v}, {mapped, acc} ->
      case action.({k, v}, acc) do
        {true, {k, v}, acc} -> {Map.put(mapped, k, v), acc}
        {_, acc} -> {mapped, acc}
      end
    end)
  end

  defp do_filter_map_reduce_list(enumerable, acc, action, new_list \\ [])
  defp do_filter_map_reduce_list([], acc, _, new_list), do: {new_list, acc}

  defp do_filter_map_reduce_list([head | tail], acc, action, new_list) do
    case action.(head, acc) do
      {true, item, acc} -> do_filter_map_reduce_list(tail, acc, action, [item | new_list])
      {_, acc} -> do_filter_map_reduce_list(tail, acc, action, new_list)
    end
  end
end
