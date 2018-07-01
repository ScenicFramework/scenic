#
#  Created by Boyd Multerer on 4/3/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.AnimationTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Graph
  alias Scenic.Animation
  alias Scenic.Primitive

  # import IEx

  @graph Graph.build()
    |> Primitive.Text.add_to_graph({{10,10}, "hello"}, id: :text_id)


  defmodule TestAnimation do
    use Scenic.Animation
    alias Scenic.Graph
    alias Scenic.Primitive

    def tick( graph, _elapsed_ms, {id, count} ) do
      count = count + 1
      cond do
        count < 10 ->
          graph = Graph.modify(graph, id, fn(p) ->
            Primitive.Text.put(p, to_string(count))
          end)
          { :continue, graph, {id, count} }

        count >= 10 ->
          graph = Graph.modify(graph, id, fn(p) ->
            Primitive.Text.put(p, to_string(count))
          end)
          { :stop, graph }
      end
    end

    def stop( graph, _elapsed_ms, {id, _} ) do
      graph = Graph.modify(graph, id, fn(p) ->
        Primitive.Text.put(p, to_string(-1))
      end)
      {:ok, graph }
    end
  end

  #============================================================================
  # make

  test "make works with a module" do
    {animations, {:animation, _} = ref} = Animation.make(
      %{}, {:text_id, 3}, TestAnimation
    )
    assert animations[ref] == {TestAnimation, {:text_id, 3}, nil}
  end

  test "make works with a single callback" do
    {animations, {:animation, _} = ref} = Animation.make(
      %{}, {:text_id, 3}, fn(g, _, _) -> {:stop, g} end
    )
    {{tick_action, nil}, {:text_id, 3}, nil} = animations[ref]
    assert is_function(tick_action, 3)
  end

  test "make works with a double callback" do
    {animations, {:animation, _} = ref} = Animation.make(
      %{}, {:text_id, 3},
      fn(g, _, _) -> {:stop, g} end,
      fn(g, _, _) -> {:ok, g} end
    )
    {{tick_action, stop_action}, {:text_id, 3}, nil} = animations[ref]
    assert is_function(tick_action, 3)
    assert is_function(stop_action, 3)
  end

  #============================================================================
  # make!

  test "make! works with a module" do
    animations = Animation.make!( %{},{:text_id, 3}, TestAnimation )
    assert is_map(animations)
    assert Enum.count(animations) == 1
  end

  test "make! works with a single callback" do
    animations = Animation.make!( %{},{:text_id, 3}, fn(g, _, _) -> {:stop, g} end )
    assert is_map(animations)
    assert Enum.count(animations) == 1
  end

  test "make! works with a double callback" do
    animations = Animation.make!( %{},{:text_id, 3},
      fn(g, _, _) -> {:stop, g} end,
      fn(g, _, _) -> {:ok, g} end
    )
    assert is_map(animations)
    assert Enum.count(animations) == 1
  end

  #============================================================================
  # tick

  test "tick calls the animations, updates the graph and updates states whith continue" do
    # create a simple animation entry
    {animations, ref} = Animation.make(%{}, {:text_id, 1}, TestAnimation)
    # prove that it was set up correctly with nil last time
    {TestAnimation, {:text_id, 1}, time_0} = animations[ref]
    assert Graph.get_id!(@graph, :text_id).data == {{10,10}, "hello"}
    refute time_0

    # Tick the animation for the first time. This should set a last_time
    {animations, %Graph{} = graph} = Animation.tick(animations, @graph)
    # prove the time was set
    {TestAnimation, {:text_id, 2}, time_1} = animations[ref]
    assert Graph.get_id!(graph, :text_id).data == {{10,10}, "2"}
    assert time_1
  end

  test "tick calls the animations, updates the graph and allows the animations to stop" do
    {animations, ref} = Animation.make(%{}, {:text_id, 8}, TestAnimation)
    {TestAnimation, {:text_id, 8}, _} = animations[ref]
    assert Graph.get_id!(@graph, :text_id).data == {{10,10}, "hello"}

    {animations, %Graph{} = graph} = Animation.tick(animations, @graph)
    {TestAnimation, {:text_id, 9}, _} = animations[ref]
    assert Graph.get_id!(graph, :text_id).data == {{10,10}, "9"}

    {animations, %Graph{} = graph} = Animation.tick(animations, graph)
    refute animations[ref]
    assert Graph.get_id!(graph, :text_id).data == {{10,10}, "-1"}
  end

  #============================================================================
  # stop

  test "stop removes the animation from the list" do
    {animations, ref0} = Animation.make(%{}, {:text_id, 1}, TestAnimation)
    {animations, ref1} = Animation.make(animations, {:id_two, 2}, TestAnimation)
    assert Map.has_key?(animations, ref0)
    assert Map.has_key?(animations, ref1)

    {graph, animations} = Animation.stop(@graph, animations, ref0)
    
    refute Map.has_key?(animations, ref0)
    assert Map.has_key?(animations, ref1)

    {_, animations} = Animation.stop(graph, animations, ref1)
    assert animations == %{}
  end

  test "stop calls stop on the animation module" do
    {animations, ref0} = Animation.make(%{}, {:text_id, 1}, TestAnimation)
    {graph, animations} = Animation.stop(@graph, animations, ref0)
    assert animations == %{}
    assert Graph.get_id!(graph, :text_id).data == {{10,10}, "-1"}
  end

  test "stop with nil stop callback is OK" do
   {animations, ref0} = Animation.make(%{}, {:text_id, 1}, fn(g, _, _) -> {:continue, g, {:text_id, 2}} end)
   {_, animations} = Animation.stop(@graph, animations, ref0)
   assert animations == %{}
  end

  test "stop with ref that isn't a member does nothing" do
    {animations, ref0} = Animation.make(%{}, {:text_id, 1}, TestAnimation)
    {_, ref1} = Animation.make(animations, {:id_two, 2}, TestAnimation)
    assert Map.has_key?(animations, ref0)
    refute Map.has_key?(animations, ref1)

   {_, ani0} = Animation.stop(@graph, animations, ref1)
   assert animations == ani0
  end

end
































