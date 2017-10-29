defmodule Scenic.Utilities.MapTest do
  use ExUnit.Case, async: true
  doctest Scenic

  @map_1      %{a: 1, b: 2, c: 3, d: 4}
  @map_2      %{a: 1, c: 3, d: 14, f: 15}


  @nested_diff [{:put,{:b,:aa},4}, {:put,{:b,:bb},4},{:del,{:b,:ff}},{:put,{:b,{:cc,:aaa}},8},{:del,:c}]
  @nested_map_1 %{
    a: 1,
    b: %{aa: 2, ff: 8},
    c: 2
  }
  @nested_map_2 %{
    a: 1,
    b: %{aa: 4, bb: 4, cc: %{aaa: 8}}
  }

  @deep_map_1     %{a: %{b: 1}}
  @deep_map_2     %{a: %{b: %{c: 2}}}
  @deep_map_diff  [{:put, {:a,{:b,:c}},2}]


  test "difference returns a list of deltas" do
    assert is_list( Scenic.Utilities.Map.difference(@map_1, @map_2) )
  end

  test "difference returns a list of deltas with nested maps too" do
    assert is_list( Scenic.Utilities.Map.difference(@nested_map_1, @nested_map_2) )
  end

  test "difference creates a nested difference list" do
    map_1 = %{a: %{b: 1}}
    map_2 = %{a: %{b: 2}}
    assert Scenic.Utilities.Map.difference(map_1, map_2) == [{:put, {:a,:b},2}]
  end

  test "difference creates a deeply nested difference list" do
    assert Scenic.Utilities.Map.difference(@deep_map_1, @deep_map_2) == @deep_map_diff
  end

  test "applying the difference to map_1 creates a map that equals map_2" do
    diff = Scenic.Utilities.Map.difference(@map_1, @map_2)
    assert Scenic.Utilities.Map.apply_difference(@map_1, diff) == @map_2
  end

  test "applying the difference works for nested maps" do
    diff = Scenic.Utilities.Map.difference(@nested_map_1, @nested_map_2)
    assert Scenic.Utilities.Map.apply_difference(@nested_map_1, diff) == @nested_map_2
  end

  test "applying the nested difference works" do
    assert Scenic.Utilities.Map.apply_difference(@nested_map_1, @nested_diff) == @nested_map_2
  end

  test "applying deeply nested difference works" do
    assert Scenic.Utilities.Map.apply_difference(@deep_map_1, @deep_map_diff) == @deep_map_2
  end



#  test "diff2 and apply2 work" do
#    diff = Scenic.Utilities.Map.diff2(@map_1, @map_2)
#    assert Scenic.Utilities.Map.apply2(@map_1, diff) == @map_2
#  end

end