#
#  Created by Boyd Multerer on 11/08/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.InputTest do
  use ExUnit.Case, async: true
  use Bitwise
  doctest Scenic.ViewPort.Input

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.ViewPort.Input
  alias Scenic.ViewPort.Tables
  import Scenic.Primitives

   import IEx

  @graph Graph.build()
  |> rect({10, 10}, t: {20, 20}, id: :rect)



  setup do
    {:ok, tables} = Tables.start_link(nil)
    on_exit(fn -> Process.exit(tables, :normal) end)

    self = self()
    scene_ref = make_ref()
    graph_key = {:graph, scene_ref, nil}
    master_graph_key = {:graph, make_ref(), nil}

    master_graph = %{
      0 => %{data: {Primitive.Group, [1]}, transforms: %{translate: {1.0,1.0}}},
      1 => %{data: {Primitive.SceneRef, graph_key}}
    }

    graph = Enum.reduce(@graph.primitives, %{}, fn({k,p},g) ->
      Map.put(g, k, Primitive.minimal(p))
    end)

    Tables.register_scene(scene_ref, {self, self, self})

    Tables.insert_graph(graph_key, self(), graph, %{})
    Tables.insert_graph(master_graph_key, self(), master_graph, %{1 => graph_key})
    Process.sleep(10)

    %{
      tables: tables,
      scene_ref: scene_ref,
      graph_key: graph_key,
      master_graph_key: master_graph_key
    }
  end


  #============================================================================
  # capture input

  test "handle_cast :capture_input" do
    graph_key = {:graph, make_ref(), nil}

    {:noreply, state} = Input.handle_cast(
      {:capture_input, graph_key, [:key, :codepoint]},
      %{input_captures: %{:cursor_pos => graph_key}}
    )
    assert state.input_captures == %{
      :cursor_pos => graph_key,
      :key => graph_key,
      :codepoint => graph_key
    }
  end

  test "handle_cast :release_input" do
    graph_key = {:graph, make_ref(), nil}

    {:noreply, state} = Input.handle_cast(
      {:release_input, [:key, :codepoint]},
      %{input_captures: %{
        :cursor_pos => graph_key,
        :key => graph_key,
        :codepoint => graph_key
      }}
    )
    assert state.input_captures == %{
      :cursor_pos => graph_key
    }
  end

  #============================================================================
  # input

  test "input is ignored until the master_key is set" do
    {:noreply, state} = Input.handle_cast(
      {:input, {:cursor_pos, {1,2}}},
      %{ master_graph_key: nil }
    )
    assert state == %{ master_graph_key: nil }
  end

  test "continue_input is ignored until the master_key is set" do
    {:noreply, state} = Input.handle_cast(
      {:continue_input, {:cursor_pos, {1,2}}},
      %{ master_graph_key: nil }
    )
    assert state == %{ master_graph_key: nil }
  end

  #============================================================================
  # regular, non-captured input

  test "input codepoint", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    {:noreply, _} = Input.handle_cast(
      {:input, {:codepoint, :codepoint_input}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{}
      }
    )
    assert_received( {:"$gen_cast", {:input, {:codepoint, :codepoint_input}, context}} )
    assert context.graph_key == graph_key
    assert context.id == nil
    assert context.uid == nil
    assert context.viewport == self()
  end

  test "input key", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    {:noreply, _} = Input.handle_cast(
      {:input, {:codepoint, :key_input}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{}
      }
    )
    assert_received( {:"$gen_cast", {:input, {:codepoint, :key_input}, context}} )
    assert context.graph_key == graph_key
    assert context.id == nil
    assert context.uid == nil
    assert context.viewport == self()
  end

  test "input cursor_button", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    # start NOT over a primitive
    {:noreply, _} = Input.handle_cast(
      {:input, {:cursor_button, {:left, :press, 0, {1,1}}}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{},
        max_depth: 10
      }
    )
    refute_received( {:"$gen_cast", {:input, _, _}} )

    # over a primitive
    {:noreply, _} = Input.handle_cast(
      {:input, {:cursor_button, {:left, :press, 0, {25,25}}}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{},
        max_depth: 10
      }
    )
    assert_received( {:"$gen_cast",
      {:input, {:cursor_button, {:left, :press, 0, {24.0,24.0}}}, context}} )
    assert context.graph_key == graph_key
    assert context.id == :rect
    assert context.uid == 1
    assert context.viewport == self()
  end

  test "input cursor_scroll", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    # start NOT over a primitive
    {:noreply, _} = Input.handle_cast(
      {:input, {:cursor_scroll, {{-1,-1},{1,1}}}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{},
        max_depth: 10
      }
    )
    refute_received( {:"$gen_cast", {:input, _, _}} )

    # over a primitive
    {:noreply, _} = Input.handle_cast(
      {:input, {:cursor_scroll, {{-1,-1},{25,25}}}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{},
        max_depth: 10
      }
    )
    assert_received( {:"$gen_cast",
      {:input, {:cursor_scroll, {{-1,-1},{24.0,24.0}}}, context}} )
    assert context.graph_key == graph_key
    assert context.id == :rect
    assert context.uid == 1
    assert context.viewport == self()
  end

  test "input cursor_pos", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    # start NOT over a primitive
    {:noreply, _} = Input.handle_cast(
      {:input, {:cursor_pos, {1,1}}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{},
        max_depth: 10,
        hover_primitve: nil
      }
    )
    refute_received( {:"$gen_cast", {:input, _, _}} )

    # over a primitive - entering
    {:noreply, _} = Input.handle_cast(
      {:input, {:cursor_pos, {25,25}}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{},
        max_depth: 10,
        hover_primitve: nil
      }
    )
    assert_received( {:"$gen_cast", {:input, {:cursor_enter, 1}, _}} )
    assert_received( {:"$gen_cast", {:input, {:cursor_pos, {24.0,24.0}}, context}} )
    refute_received( {:"$gen_cast", {:input, {:cursor_exit,_}, _}} )
    assert context.graph_key == graph_key
    assert context.id == :rect
    assert context.uid == 1
    assert context.viewport == self()

    # over a primitive - staying in
    {:noreply, _} = Input.handle_cast(
      {:input, {:cursor_pos, {25,25}}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{},
        max_depth: 10,
        hover_primitve: {1, graph_key}
      }
    )
    refute_received( {:"$gen_cast", {:input, {:cursor_enter, _}, _}} )
    assert_received( {:"$gen_cast", {:input, {:cursor_pos, {24.0,24.0}}, context}} )
    refute_received( {:"$gen_cast", {:input, {:cursor_exit,_}, _}} )
    assert context.graph_key == graph_key
    assert context.id == :rect
    assert context.uid == 1
    assert context.viewport == self()

    # not over a primitive - exiting to nothing
    {:noreply, _} = Input.handle_cast(
      {:input, {:cursor_pos, {1,1}}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{},
        max_depth: 10,
        hover_primitve: {1, graph_key}
      }
    )
    refute_received( {:"$gen_cast", {:input, {:cursor_enter, _}, _}} )
    assert_received( {:"$gen_cast", {:input, {:cursor_exit, 1}, _}} )
    # assert_received( {:"$gen_cast", {:input, {:cursor_pos, {24.0,24.0}}, context}} )

    # not over a primitive - exiting to another
    {:noreply, _} = Input.handle_cast(
      {:input, {:cursor_pos, {25,25}}},
      %{
        master_graph_key: master_graph_key,
        root_graph_key: graph_key,
        input_captures: %{},
        max_depth: 10,
        hover_primitve: {2, graph_key}
      }
    )
    assert_received( {:"$gen_cast", {:input, {:cursor_enter, 1}, _}} )
    assert_received( {:"$gen_cast", {:input, {:cursor_exit, 2}, _}} )
    assert_received( {:"$gen_cast", {:input, {:cursor_pos, {24.0,24.0}}, context}} )
    assert context.graph_key == graph_key
    assert context.id == :rect
    assert context.uid == 1
    assert context.viewport == self()
  end

  test "input viewport_enter", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    # start NOT over a primitive
    {:noreply, _} = Input.handle_cast(
      {:input, {:viewport_enter, :viewport_enter_input}},
      %{
        root_graph_key: graph_key,
        input_captures: %{}
      }
    )
    assert_received( {:"$gen_cast", {:input, {:viewport_enter, :viewport_enter_input}, context}} )
  end

  test "input viewport_exit", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    # start NOT over a primitive
    {:noreply, _} = Input.handle_cast(
      {:input, {:viewport_exit, :viewport_exit_input}},
      %{
        root_graph_key: graph_key,
        input_captures: %{}
      }
    )
    assert_received( {:"$gen_cast", {:input, {:viewport_exit, :viewport_exit_input}, context}} )
  end

  test "input other", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    # start NOT over a primitive
    {:noreply, _} = Input.handle_cast(
      {:input, {:other, 123}},
      %{
        root_graph_key: graph_key,
        input_captures: %{}
      }
    )
    assert_received( {:"$gen_cast", {:input, {:other, 123}, context}} )
  end

end

































