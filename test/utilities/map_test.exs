defmodule Scenic.Utilities.MapTest do
  use ExUnit.Case, async: true
  doctest Scenic.Utilities.Map

  alias Scenic.Utilities

  @map_1 %{a: 1, b: 2, c: 3, d: 4}
  @map_2 %{a: 1, c: 3, d: 14, f: 15}

  @nested_diff [
    {:put, {:b, :aa}, 4},
    {:put, {:b, :bb}, 4},
    {:del, {:b, :ff}},
    {:put, {:b, {:cc, :aaa}}, 8},
    {:del, :c}
  ]
  @nested_map_1 %{
    a: 1,
    b: %{aa: 2, ff: 8},
    c: 2
  }
  @nested_map_2 %{
    a: 1,
    b: %{aa: 4, bb: 4, cc: %{aaa: 8}}
  }

  @deep_map_1 %{a: %{b: 1}}
  @deep_map_2 %{a: %{b: %{c: 2}}}
  @deep_map_diff [{:put, {:a, {:b, :c}}, 2}]

  test "difference returns a list of deltas" do
    assert is_list(Utilities.Map.difference(@map_1, @map_2))
  end

  test "difference returns a list of deltas with nested maps too" do
    assert is_list(Utilities.Map.difference(@nested_map_1, @nested_map_2))
  end

  test "difference creates a nested difference list" do
    map_1 = %{a: %{b: 1}}
    map_2 = %{a: %{b: 2}}
    assert Utilities.Map.difference(map_1, map_2) == [{:put, {:a, :b}, 2}]
  end

  test "difference creates a deeply nested difference list" do
    assert Utilities.Map.difference(@deep_map_1, @deep_map_2) == @deep_map_diff
  end

  # ============================================================================
  # apply_difference

  test "applying the difference to map_1 creates a map that equals map_2" do
    diff = Utilities.Map.difference(@map_1, @map_2)
    assert Utilities.Map.apply_difference(@map_1, diff) == @map_2
  end

  test "applying the difference works for nested maps" do
    diff = Utilities.Map.difference(@nested_map_1, @nested_map_2)
    assert Utilities.Map.apply_difference(@nested_map_1, diff) == @nested_map_2
  end

  test "applying the nested difference works" do
    assert Utilities.Map.apply_difference(@nested_map_1, @nested_diff) == @nested_map_2
  end

  test "applying deeply nested difference works" do
    assert Utilities.Map.apply_difference(@deep_map_1, @deep_map_diff) == @deep_map_2
  end

  # ============================================================================
  # merge_difference
  @merge_diff [{:put, {:b, :aa}, 4}, {:del, {:b, :ff}}, {:put, {:b, :bb}, 5}]

  test "merge_difference adds new entries" do
    assert Utilities.Map.merge_difference(@merge_diff, [{:put, {:b, :bc}, 6}]) ==
             [{:put, {:b, :bc}, 6}, {:put, {:b, :aa}, 4}, {:del, {:b, :ff}}, {:put, {:b, :bb}, 5}]
  end

  test "merge_difference overrides old entries" do
    assert Utilities.Map.merge_difference(@merge_diff, [{:put, {:b, :bb}, 6}]) ==
             [{:put, {:b, :bb}, 6}, {:put, {:b, :aa}, 4}, {:del, {:b, :ff}}]
  end

  test "merge_difference deletes old entries" do
    assert Utilities.Map.merge_difference(@merge_diff, [{:del, {:b, :bb}}]) ==
             [{:del, {:b, :bb}}, {:put, {:b, :aa}, 4}, {:del, {:b, :ff}}]
  end

  test "merge_difference overrides old deletions" do
    assert Utilities.Map.merge_difference(@merge_diff, [{:put, {:b, :ff}, 42}]) ==
             [{:put, {:b, :ff}, 42}, {:put, {:b, :aa}, 4}, {:put, {:b, :bb}, 5}]
  end

  test "merge_difference does nothing deleting an old deletion" do
    assert Utilities.Map.merge_difference(@merge_diff, [{:del, {:b, :ff}}]) ==
             [{:del, {:b, :ff}}, {:put, {:b, :aa}, 4}, {:put, {:b, :bb}, 5}]
  end

  # ============================================================================
  # delete_in

  test "delete_in deletes a nested map member" do
    map = %{a: %{b: %{c: 123, d: 456}}, e: 789}
    assert Utilities.Map.delete_in(map, [:a, :b, :c]) == %{a: %{b: %{d: 456}}, e: 789}
    assert Utilities.Map.delete_in(map, [:a, :b, :d]) == %{a: %{b: %{c: 123}}, e: 789}
    assert Utilities.Map.delete_in(map, [:a, :b]) == %{a: %{}, e: 789}
  end

  test "delete_in does nothing if the final member is absent" do
    map = %{a: %{b: %{c: 123, d: 456}}, e: 789}
    assert Utilities.Map.delete_in(map, [:a, :b, :f]) == map
  end

  test "delete_in does nothing if middle members are absent" do
    map = %{a: %{b: %{c: 123, d: 456}}, e: 789}
    assert Utilities.Map.delete_in(map, [:a, :g, :e]) == map
    assert Utilities.Map.delete_in(map, [:g, :c]) == map
  end

  # ============================================================================
  # put_set

  test "put_set puts a truthy value" do
    assert Utilities.Map.put_set(%{}, :value, 123) == %{value: 123}
  end

  test "put_set accepts a false value" do
    assert Utilities.Map.put_set(%{}, :value, false) == %{value: false}
  end

  test "put_set ignores a nil value" do
    assert Utilities.Map.put_set(%{}, :value, nil) == %{}
  end
end
