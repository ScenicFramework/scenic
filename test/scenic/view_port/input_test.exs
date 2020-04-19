#
#  Created by Boyd Multerer on 2017-11-08.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.InputTest do
  use ExUnit.Case, async: true
  use Bitwise
  doctest Scenic.ViewPort.Input

  alias Scenic.Math.Matrix
  alias Scenic.Graph
  alias Scenic.Primitive
  # alias Scenic.ViewPort
  alias Scenic.ViewPort.Input
  alias Scenic.ViewPort.Context
  alias Scenic.ViewPort.Tables
  import Scenic.Primitives

  # import IEx

  @graph Graph.build()
         |> rect({10, 10}, t: {20, 20}, id: :rect)
         |> scene_ref(nil, id: :ref)

  @graph1 Graph.build()
          |> circle(10, t: {50, 50}, id: :circle)

  setup do
    {:ok, tables} = Tables.start_link(nil)

    on_exit(fn ->
      Process.exit(tables, :normal)
      Process.sleep(2)
    end)

    self = self()
    scene_ref = make_ref()
    graph_key = {:graph, scene_ref, nil}
    graph_key1 = {:graph, scene_ref, 1}
    master_graph_key = {:graph, make_ref(), nil}

    master_graph = %{
      0 => %{data: {Primitive.Group, [1]}, transforms: %{translate: {1.0, 1.0}}},
      1 => %{data: {Primitive.SceneRef, graph_key}}
    }

    graph = Graph.modify(@graph, :ref, &scene_ref(&1, graph_key1))

    graph =
      Enum.reduce(graph.primitives, %{}, fn {k, p}, g ->
        Map.put(g, k, Primitive.minimal(p))
      end)

    graph1 =
      Enum.reduce(@graph1.primitives, %{}, fn {k, p}, g ->
        Map.put(g, k, Primitive.minimal(p))
      end)

    Tables.register_scene(scene_ref, {self, self, self})

    Tables.insert_graph(graph_key1, self(), graph1, %{})
    Tables.insert_graph(graph_key, self(), graph, %{2 => graph_key1})
    Tables.insert_graph(master_graph_key, self(), master_graph, %{1 => graph_key})
    Process.sleep(10)

    # build a capture context for the nested graph
    tx = Matrix.build_translation({1, 1})
    inv = Matrix.invert(tx)

    context = %Context{
      graph_key: graph_key1,
      tx: tx,
      inverse_tx: inv
    }

    %{
      tables: tables,
      scene_ref: scene_ref,
      graph_key: graph_key,
      graph_key1: graph_key1,
      master_graph_key: master_graph_key,
      context: context
    }
  end

  # ============================================================================
  # capture input

  test "handle_cast :capture_input" do
    graph_key = {:graph, make_ref(), nil}

    {:noreply, state} =
      Input.handle_cast(
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

    {:noreply, state} =
      Input.handle_cast(
        {:release_input, [:key, :codepoint]},
        %{
          input_captures: %{
            :cursor_pos => graph_key,
            :key => graph_key,
            :codepoint => graph_key
          }
        }
      )

    assert state.input_captures == %{
             :cursor_pos => graph_key
           }
  end

  # ============================================================================
  # input - normal

  test "input is ignored until the master_key is set" do
    {:noreply, state} =
      Input.handle_cast(
        {:input, {:cursor_pos, {1, 2}}},
        %{master_graph_key: nil}
      )

    assert state == %{master_graph_key: nil}
  end

  test "continue_input is ignored until the master_key is set" do
    {:noreply, state} =
      Input.handle_cast(
        {:continue_input, {:cursor_pos, {1, 2}}},
        %{master_graph_key: nil}
      )

    assert state == %{master_graph_key: nil}
  end

  # ============================================================================
  # regular, non-captured input

  test "input codepoint", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:codepoint, :codepoint_input}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{}
        }
      )

    assert_received({:"$gen_cast", {:input, {:codepoint, :codepoint_input}, context}})
    assert context.graph_key == graph_key
    assert context.id == nil
    assert context.uid == nil
    assert context.viewport == self()
  end

  test "input key", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:codepoint, :key_input}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{}
        }
      )

    assert_received({:"$gen_cast", {:input, {:codepoint, :key_input}, context}})
    assert context.graph_key == graph_key
    assert context.id == nil
    assert context.uid == nil
    assert context.viewport == self()
  end

  test "input cursor_button", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_button, {:left, :press, 0, {1, 1}}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{},
          max_depth: 10
        }
      )

    refute_received({:"$gen_cast", {:input, _, _}})

    # over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_button, {:left, :press, 0, {25, 25}}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{},
          max_depth: 10
        }
      )

    assert_received(
      {:"$gen_cast", {:input, {:cursor_button, {:left, :press, 0, {24.0, 24.0}}}, context}}
    )

    assert context.graph_key == graph_key
    assert context.id == :rect
    assert context.uid == 1
    assert context.viewport == self()
  end

  test "input cursor_scroll", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_scroll, {{-1, -1}, {1, 1}}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{},
          max_depth: 10
        }
      )

    refute_received({:"$gen_cast", {:input, _, _}})

    # over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_scroll, {{-1, -1}, {25, 25}}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{},
          max_depth: 10
        }
      )

    assert_received({:"$gen_cast", {:input, {:cursor_scroll, {{-1, -1}, {24.0, 24.0}}}, context}})
    assert context.graph_key == graph_key
    assert context.id == :rect
    assert context.uid == 1
    assert context.viewport == self()
  end

  test "input cursor_pos when not over anything", %{
    graph_key: graph_key,
    master_graph_key: master_graph_key
  } do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_pos, {1, 1}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{},
          max_depth: 10,
          hover_primitive: nil
        }
      )

    refute_received({:"$gen_cast", {:input, _, _}})
  end

  test "input cursor_pos entering from nothing", %{
    graph_key: graph_key,
    master_graph_key: master_graph_key
  } do
    # over a primitive - entering
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_pos, {25, 25}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{},
          max_depth: 10,
          hover_primitive: nil
        }
      )

    assert_received({:"$gen_cast", {:input, {:cursor_enter, 1}, _}})
    assert_received({:"$gen_cast", {:input, {:cursor_pos, {24.0, 24.0}}, context}})
    refute_received({:"$gen_cast", {:input, {:cursor_exit, _}, _}})
    assert context.graph_key == graph_key
    assert context.id == :rect
    assert context.uid == 1
    assert context.viewport == self()
  end

  test "input cursor_pos entering nested graph", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    master_graph_key: master_graph_key
  } do
    # over a primitive - entering
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_pos, {50, 50}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{},
          max_depth: 10,
          hover_primitive: nil
        }
      )

    assert_received({:"$gen_cast", {:input, {:cursor_enter, 1}, _}})
    assert_received({:"$gen_cast", {:input, {:cursor_pos, {49.0, 49.0}}, context}})
    refute_received({:"$gen_cast", {:input, {:cursor_exit, _}, _}})
    assert context.graph_key == graph_key1
    assert context.id == :circle
    assert context.uid == 1
    assert context.viewport == self()
  end

  test "input cursor_pos staying within a primitive", %{
    graph_key: graph_key,
    master_graph_key: master_graph_key
  } do
    # over a primitive - staying in
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_pos, {26, 26}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{},
          max_depth: 10,
          hover_primitive: {1, graph_key}
        }
      )

    refute_received({:"$gen_cast", {:input, {:cursor_enter, _}, _}})
    assert_received({:"$gen_cast", {:input, {:cursor_pos, {25.0, 25.0}}, context}})
    refute_received({:"$gen_cast", {:input, {:cursor_exit, _}, _}})
    assert context.graph_key == graph_key
    assert context.id == :rect
    assert context.uid == 1
    assert context.viewport == self()
  end

  test "input cursor_pos leaving a primitive to nothing", %{
    graph_key: graph_key,
    master_graph_key: master_graph_key
  } do
    # not over a primitive - exiting to nothing
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_pos, {1, 1}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{},
          max_depth: 10,
          hover_primitive: {1, graph_key}
        }
      )

    refute_received({:"$gen_cast", {:input, {:cursor_enter, _}, _}})
    assert_received({:"$gen_cast", {:input, {:cursor_exit, 1}, _}})
    refute_received({:"$gen_cast", {:input, {:cursor_pos, _}, _}})
  end

  test "input cursor_pos going from one prim to another", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    master_graph_key: master_graph_key
  } do
    # going from one primitive to another
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_pos, {50, 50}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{},
          max_depth: 10,
          hover_primitive: {1, graph_key}
        }
      )

    assert_received({:"$gen_cast", {:input, {:cursor_exit, 1}, _}})
    assert_received({:"$gen_cast", {:input, {:cursor_enter, 1}, _}})
    assert_received({:"$gen_cast", {:input, {:cursor_pos, {49.0, 49.0}}, context}})
    assert context.graph_key == graph_key1
    assert context.id == :circle
    assert context.uid == 1
    assert context.viewport == self()
  end

  test "input viewport_enter", %{graph_key: graph_key} do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:viewport_enter, :viewport_enter_input}},
        %{
          root_graph_key: graph_key,
          input_captures: %{}
        }
      )

    assert_received({:"$gen_cast", {:input, {:viewport_enter, :viewport_enter_input}, context}})
  end

  test "input viewport_exit", %{graph_key: graph_key} do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:viewport_exit, :viewport_exit_input}},
        %{
          root_graph_key: graph_key,
          input_captures: %{}
        }
      )

    assert_received({:"$gen_cast", {:input, {:viewport_exit, :viewport_exit_input}, context}})
  end

  test "input other", %{graph_key: graph_key} do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:other, 123}},
        %{
          root_graph_key: graph_key,
          input_captures: %{}
        }
      )

    assert_received({:"$gen_cast", {:input, {:other, 123}, context}})
  end

  # ============================================================================
  # input - captured

  test "captured codepoint", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    context: context,
    master_graph_key: master_graph_key
  } do
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:codepoint, :codepoint_input}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{codepoint: context}
        }
      )

    assert_received({:"$gen_cast", {:input, {:codepoint, :codepoint_input}, context}})
    assert context.graph_key == graph_key1
    assert context.id == nil
    assert context.uid == nil
  end

  test "captured key", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    context: context,
    master_graph_key: master_graph_key
  } do
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:key, :key_input}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{key: context}
        }
      )

    assert_received({:"$gen_cast", {:input, {:key, :key_input}, context}})
    assert context.graph_key == graph_key1
    assert context.id == nil
    assert context.uid == nil
  end

  test "captured cursor_button", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    context: context,
    master_graph_key: master_graph_key
  } do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_button, {:left, :press, 0, {1, 1}}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{cursor_button: context},
          max_depth: 10
        }
      )

    assert_received(
      {:"$gen_cast", {:input, {:cursor_button, {:left, :press, 0, {0.0, 0.0}}}, context}}
    )

    assert context.graph_key == graph_key1
    assert context.id == nil
    assert context.uid == nil

    # over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_button, {:left, :press, 0, {50, 50}}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{cursor_button: context},
          max_depth: 10
        }
      )

    assert_received(
      {:"$gen_cast", {:input, {:cursor_button, {:left, :press, 0, {49.0, 49.0}}}, context}}
    )

    assert context.graph_key == graph_key1
    assert context.id == :circle
    assert context.uid == 1
  end

  test "captured cursor_scroll", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    context: context,
    master_graph_key: master_graph_key
  } do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_scroll, {{-1, -1}, {1, 1}}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{cursor_scroll: context},
          max_depth: 10
        }
      )

    assert_received({:"$gen_cast", {:input, {:cursor_scroll, {{-1, -1}, {0.0, 0.0}}}, context}})
    assert context.graph_key == graph_key1
    assert context.id == nil
    assert context.uid == nil

    # over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_scroll, {{-1, -1}, {50, 50}}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{cursor_scroll: context},
          max_depth: 10
        }
      )

    assert_received({:"$gen_cast", {:input, {:cursor_scroll, {{-1, -1}, {49.0, 49.0}}}, context}})
    assert context.graph_key == graph_key1
    assert context.id == :circle
    assert context.uid == 1
  end

  test "captured viewport_enter", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    context: context
  } do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:viewport_enter, :viewport_enter_input}},
        %{
          root_graph_key: graph_key,
          input_captures: %{viewport_enter: context}
        }
      )

    assert_received({:"$gen_cast", {:input, {:viewport_enter, :viewport_enter_input}, context}})
    assert context.graph_key == graph_key1
  end

  test "captured viewport_exit", %{graph_key: graph_key, graph_key1: graph_key1, context: context} do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:viewport_exit, :viewport_exit_input}},
        %{
          root_graph_key: graph_key,
          input_captures: %{viewport_exit: context}
        }
      )

    assert_received({:"$gen_cast", {:input, {:viewport_exit, :viewport_exit_input}, context}})
    assert context.graph_key == graph_key1
  end

  test "captured other", %{graph_key: graph_key, graph_key1: graph_key1, context: context} do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:other, 123}},
        %{
          root_graph_key: graph_key,
          input_captures: %{other: context}
        }
      )

    assert_received({:"$gen_cast", {:input, {:other, 123}, context}})
    assert context.graph_key == graph_key1
  end

  test "captured cursor_pos over nothing", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    context: context,
    master_graph_key: master_graph_key
  } do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_pos, {1, 1}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{cursor_pos: context},
          max_depth: 10,
          hover_primitive: nil
        }
      )

    assert_received({:"$gen_cast", {:input, {:cursor_pos, {0.0, 0.0}}, context}})
    assert context.graph_key == graph_key1
    assert context.id == nil
    assert context.uid == nil
  end

  test "captured cursor_pos over non-captured graph", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    context: context,
    master_graph_key: master_graph_key
  } do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_pos, {25, 25}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{cursor_pos: context},
          max_depth: 10,
          hover_primitive: nil
        }
      )

    assert_received({:"$gen_cast", {:input, {:cursor_pos, {24.0, 24.0}}, context}})
    assert context.graph_key == graph_key1
    assert context.id == nil
    assert context.uid == nil
  end

  test "captured cursor_pos enter primitive", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    context: context,
    master_graph_key: master_graph_key
  } do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_pos, {50, 50}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{cursor_pos: context},
          max_depth: 10,
          hover_primitive: nil
        }
      )

    assert_received({:"$gen_cast", {:input, {:cursor_pos, {49.0, 49.0}}, context}})
    refute_received({:"$gen_cast", {:input, {:cursor_exit, _}, _}})
    assert_received({:"$gen_cast", {:input, {:cursor_enter, 1}, _}})

    assert context.graph_key == graph_key1
    assert context.id == :circle
    assert context.uid == 1
  end

  test "captured cursor_pos exit primitive", %{
    graph_key: graph_key,
    graph_key1: graph_key1,
    context: context,
    master_graph_key: master_graph_key
  } do
    # start NOT over a primitive
    {:noreply, _} =
      Input.handle_cast(
        {:input, {:cursor_pos, {2, 2}}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{cursor_pos: context},
          max_depth: 10,
          hover_primitive: {1, graph_key1}
        }
      )

    assert_received({:"$gen_cast", {:input, {:cursor_pos, {1.0, 1.0}}, context}})
    assert_received({:"$gen_cast", {:input, {:cursor_exit, 1}, _}})
    refute_received({:"$gen_cast", {:input, {:cursor_enter, _}, _}})
  end

  # ============================================================================
  # continue input

  test "continue_input codepoint", %{graph_key: graph_key, master_graph_key: master_graph_key} do
    {:noreply, _} =
      Input.handle_cast(
        {:continue_input, {:codepoint, :codepoint_input}},
        %{
          master_graph_key: master_graph_key,
          root_graph_key: graph_key,
          input_captures: %{}
        }
      )

    assert_received({:"$gen_cast", {:input, {:codepoint, :codepoint_input}, context}})
    assert context.graph_key == graph_key
    assert context.id == nil
    assert context.uid == nil
    assert context.viewport == self()
  end
end
