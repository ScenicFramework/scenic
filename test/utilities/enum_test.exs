defmodule Scenic.Utilities.EnumTest do
  use ExUnit.Case, async: true
  doctest Exui

  @test_list  [0, 1, 2, 3, 4, 5, 6]
  @test_map   %{a: 0, b: 1, c: 2, d: 3, e: 4, f: 5, g: 6}

  #============================================================================
  # filter_reduce
  test "filter_reduce filters a list (in the right order) and reduces" do
    {even, odd} = Scenic.Utilities.Enum.filter_reduce(@test_list, [], fn(e, acc) ->
      case rem( e, 2 ) do
        0 -> {true, acc}
        _ -> {false, [e | acc]}
      end
    end)
    odd = Enum.reverse(odd)

    assert even == [0, 2, 4, 6]
    assert odd == [1, 3, 5]
  end

  test "filter_reduce filters and reduces a map" do
    {even, odd} = Scenic.Utilities.Enum.filter_reduce(@test_map, %{}, fn({k,v}, acc) ->
      case rem( v, 2 ) do
        0 -> {true, acc}
        _ -> {false, Map.put(acc, k, v)}
      end
    end)
    assert even == %{a: 0, c: 2, e: 4, g: 6}
    assert odd == %{b: 1, d: 3, f: 5}
  end

  #============================================================================
  # filter_map
  test "filter_map filters a list (in the right order) and maps in one pass" do
    assert Scenic.Utilities.Enum.filter_map(@test_list, fn(e) ->
      case rem( e, 2 ) do
        0 -> {true, e * 2}
        _ -> false
      end
    end) == [0, 4, 8, 12]
  end

  test "filter_map filters and maps a map in one pass" do
    assert Scenic.Utilities.Enum.filter_map(@test_map, fn({k,v}) ->
      case rem( v, 2 ) do
        0 -> {true, {k, v * 2} }
        _ -> false
      end
    end) == %{a: 0, c: 4, e: 8, g: 12}
  end

  #============================================================================
  # filter_map_reduce
  test "filter_map_reduce filters and maps and reduces a list (in the right order) in one pass" do
    {filter_mapped, count} = Scenic.Utilities.Enum.filter_map_reduce(@test_list, 0, fn(e, acc) ->
      case rem( e, 2 ) do
        0 -> {true, e * 2, acc + 1}
        _ -> {false, acc}
      end
    end)
    assert filter_mapped == [0, 4, 8, 12]
    assert count == 4
  end

  test "filter_map_reduce filters and maps and reduces a map in one pass" do
    {filter_mapped, count} = Scenic.Utilities.Enum.filter_map_reduce(@test_map, 0, fn({k,v}, acc) ->
      case rem( v, 2 ) do
        0 -> {true, {k, v * 2}, acc + 1}
        _ -> {false, acc}
      end
    end)
    assert filter_mapped == %{a: 0, c: 4, e: 8, g: 12}
    assert count == 4
  end

end