defmodule Scenic.Utilities.Map do
  @moduledoc false
  #  @default_uid_length   4

  # ============================================================================
  @doc """
    Convenience wrapper around Kernel.pop_in that allows for use in a simple pipeline.

    See Kernel.pop_in

    Returns the map directly
  """
  def delete_in(data, keys)

  def delete_in(data, keys) do
    #    do_delete_in(map, path)
    {_, data} = pop_in(data, keys)
    data
  end

  # ============================================================================
  # ============================================================================
  # Generate a unique uid for an element. Currently uses uuid4, which in
  # turn uses psuedo-random bytes. Odds of a collision are very low
  #  def generate_uid( map, uid_length \\ @default_uid_length )
  #  def generate_uid( map = %{}, uid_length ) when is_integer(uid_length) do
  #    uid = Scenic.Utilities.rand_string( uid_length )
  #    case Map.get(map, uid) do
  #      nil ->  uid                                 # unique
  #      _ ->    generate_uid(map, uid_length + 1)   # collision
  #    end
  #  end

  # ============================================================================
  # similar to List.meyers_difference, the below code compares two maps
  # and generates a list of actions that can be applied to the first map
  # to transform it into the second map.

  # if recurse_nested is true, the result is a flat list that includes differences into
  # any nested maps in the map

  # --------------------------------------------------------
  def difference(map_1, map_2, recurse_nested \\ true)
  def difference(map_1, map_2, _) when map_1 == map_2, do: []
  def difference(nil, map_2, recurse_nested), do: difference(%{}, map_2, recurse_nested)

  def difference(map_1, map_2, recurse) when is_map(map_1) and is_map(map_2) do
    # remove any keys from map_1 that are simply not present (at all) in map_2
    diff_list =
      Enum.reduce(map_1, [], fn {k, _}, d ->
        case Map.has_key?(map_2, k) do
          false -> [{:del, k} | d]
          true -> d
        end
      end)

    # add any puts for keys that have changed between map_2 to map_1
    Enum.reduce(map_2, diff_list, fn {k, v}, d ->
      case Map.has_key?(map_1, k) do
        true ->
          v1 = Map.get(map_1, k)

          # credo:disable-for-next-line Credo.Check.Refactor.Nesting
          case v1 == v do
            true -> d
            false -> add_difference(d, k, v1, v, recurse)
          end

        false ->
          add_difference(d, k, nil, v, recurse)
      end
    end)
    |> List.flatten()
  end

  # ----------------------------------------------
  defp add_difference(diff_list, k1, v1, v2, recurse)

  defp add_difference(diff_list, k1, v1, v2, true) when not is_map(v1) do
    add_difference(diff_list, k1, %{}, v2, true)
  end

  defp add_difference(diff_list, k1, v1, v2, true) when is_map(v2) do
    diff =
      difference(v1, v2, true)
      |> Enum.map(fn delta ->
        case delta do
          {:put, k, v} -> {:put, {k1, k}, v}
          {:del, k} -> {:del, {k1, k}}
        end
      end)

    [diff | diff_list]
  end

  defp add_difference(diff_list, k1, _, v2, _) do
    [{:put, k1, v2} | diff_list]
  end

  # --------------------------------------------------------
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def apply_difference(map, diff_list, delete_empty \\ false)
      when is_map(map) and is_list(diff_list) do
    Enum.reduce(diff_list, map, fn diff, acc ->
      case diff do
        {:put, {k0, k1}, v} ->
          map = Map.get(acc, k0, %{})

          if is_map(map) do
            map
          else
            %{}
          end
          |> apply_difference([{:put, k1, v}], delete_empty)
          |> (&Map.put(acc, k0, &1)).()

        {:put, k, v} ->
          Map.put(acc, k, v)

        {:del, {k0, k1}} ->
          map =
            Map.get(acc, k0, %{})
            |> apply_difference([{:del, k1}], delete_empty)

          # credo:disable-for-next-line Credo.Check.Refactor.Nesting
          case delete_empty && map == %{} do
            true -> Map.delete(acc, k0)
            false -> Map.put(acc, k0, map)
          end

        {:del, k} ->
          Map.delete(acc, k)
      end
    end)
  end

  # --------------------------------------------------------
  def merge_difference(diff_old, diff_new) when is_list(diff_old) and is_list(diff_new) do
    # enumerate through the new items, applying them to the old one at a time
    Enum.reduce(diff_new, diff_old, fn diff, acc ->
      case diff do
        {:del, key} ->
          acc = delete_diff_by_key(acc, key)
          [{:del, key} | acc]

        {:put, key, value} ->
          acc = delete_diff_by_key(acc, key)
          [{:put, key, value} | acc]
      end
    end)
  end

  defp delete_diff_by_key(diff_list, key) do
    Enum.reject(diff_list, fn diff ->
      case diff do
        {:del, diff_key} ->
          diff_key == key

        {:put, diff_key, _} ->
          diff_key == key
      end
    end)
  end
end
