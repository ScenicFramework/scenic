#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.GraphTest do
  use ExUnit.Case, async: true
  doctest Scenic.Graph

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Primitive.Group
  alias Scenic.Primitive.Text
  alias Scenic.Primitive.Rectangle
  alias Scenic.Primitive.Line

  # import IEx

  @root_uid 0

  @tx_pin {10, 11}
  @tx_rot 0.1
  @transform %{pin: @tx_pin, rotate: @tx_rot}

  @graph_empty Graph.build()

  @graph_find Graph.build()
              |> Text.add_to_graph("Some sample text", id: :outer_text)
              |> Line.add_to_graph({{10, 10}, {100, 100}}, id: :outer_line)
              |> Group.add_to_graph(
                fn g ->
                  g
                  |> Text.add_to_graph("inner text", id: :inner_text)
                  |> Line.add_to_graph({{10, 10}, {100, 100}}, id: :inner_line)
                end,
                id: :group
              )

  @graph_ordered Graph.build()
                 |> Line.add_to_graph({{10, 10}, {100, 100}}, id: :line)
                 |> Text.add_to_graph("text", id: :text)
                 |> Line.add_to_graph({{30, 30}, {300, 300}}, id: :line)

  @graph_delete Graph.build()
                |> Text.add_to_graph("Some sample text", id: :outer_text)
                |> Line.add_to_graph({{10, 10}, {100, 100}}, id: :outer_line)
                |> Group.add_to_graph(
                  fn g ->
                    g
                    |> Text.add_to_graph("inner text", id: :inner_text)
                    |> Line.add_to_graph({{10, 10}, {100, 100}}, id: :inner_line)
                    |> Group.add_to_graph(
                      fn h ->
                        h
                        |> Text.add_to_graph("deep text", id: :deep_text)
                      end,
                      id: :inner_group
                    )
                  end,
                  id: :group
                )

  # ============================================================================
  # access to the basics. These concentrate knowledge of the internal format
  # into just a few functions

  # test "get_root returns the root node" do
  #   assert Graph.get_root(@graph_empty) == @empty_root
  # end

  # ============================================================================
  # build
  test "build builds a new graph" do
    %Graph{} = Graph.build()
  end

  test "build builds accepts an id for the root node " do
    graph = Graph.build(id: :test_root)
    assert graph.ids == %{test_root: [0], _root_: [0]}
  end

  test "new graphs start with id :root pointing to uid 0" do
    graph = Graph.build()
    assert Graph.count(graph) == 1
    assert graph.ids == %{_root_: [0]}
  end

  test "build puts styles on the root node" do
    graph = Graph.build(fill: :dark_slate_blue)

    assert graph.primitives[@root_uid]
      |> Primitive.get_styles()
      |> Map.get(:fill) == {:color, {:color_rgba, {72, 61, 139, 255}}}
  end

  test "build puts transforms on the root node" do
    graph = Graph.build(rotate: 1.3)

    assert graph.primitives[@root_uid]
           |> Primitive.get_transforms() == %{rotate: 1.3}
  end

  test "build puts other options on the root node" do
    graph = Graph.build(non_standard: "abc")

    assert graph.primitives[@root_uid]
           |> Map.get(:opts) == [non_standard: "abc"]
  end

  test "build accepts the :max_depth option" do
    graph = Graph.build(max_depth: 1)
    assert Map.get(graph, :max_depth) == 1
  end

  test "build honors fonts and font_sizes set directly" do
    graph = Graph.build(font: "fonts/roboto.ttf", font_size: 12)
    assert graph.primitives[@root_uid] |> Primitive.get_styles() |> Map.get(:font) == "fonts/roboto.ttf"
    assert graph.primitives[@root_uid] |> Primitive.get_styles() |> Map.get(:font_size) == 12
  end

  # ============================================================================
  # get - retrieve a primitive (or primtives) from a graph given an id

  test "get gets a primitive" do
    [%Primitive{module: Primitive.Line}] = Graph.get(@graph_find, :outer_line)
  end

  test "get gets multiple mapped primitives" do
    [%Primitive{module: Primitive.Line}, %Primitive{module: Primitive.Line}] =
      Graph.get(@graph_ordered, :line)
  end

  test "get! gets a primitive" do
    %Primitive{module: Primitive.Line} = Graph.get!(@graph_find, :outer_line)
  end

  test "get! raises if multiple mapped primitives" do
    assert_raise Scenic.Graph.Error, fn ->
      Graph.get!(@graph_ordered, :line)
    end
  end

  # ============================================================================
  # delete - removes nodes from the graph
  # can't just compare the expected graph as the add_to housekeeping will be off

  test "delete removes a primitive" do
    [uid] = @graph_find.ids[:outer_line]
    refute @graph_find.primitives[uid] == nil
    deleted = Graph.delete(@graph_find, :outer_line)
    assert deleted.primitives[uid] == nil
  end

  test "delete removes a unmaps the id" do
    refute Graph.get(@graph_find, :outer_line) == []
    deleted = Graph.delete(@graph_find, :outer_line)
    assert Graph.get(deleted, :outer_line) == []
    assert deleted.ids[:outer_line] == nil
  end

  test "delete removes a removes the reference from the parent" do
    [uid] = @graph_find.ids[:outer_line]
    # get the parent uid
    %{parent_uid: puid} = Graph.get!(@graph_find, :outer_line)
    # confirm the parent reference
    assert Enum.member?(@graph_find.primitives[puid].data, uid)

    # delete
    deleted = Graph.delete(@graph_find, :outer_line)

    # confirm the parent reference is cleared
    refute Enum.member?(deleted.primitives[puid].data, uid)
  end

  test "delete a group removes group children" do
    [tuid] = @graph_delete.ids[:inner_text]
    [luid] = @graph_delete.ids[:inner_line]
    [guid] = @graph_delete.ids[:inner_group]
    [duid] = @graph_delete.ids[:deep_text]
    refute @graph_delete.primitives[tuid] == nil
    refute @graph_delete.primitives[luid] == nil
    refute @graph_delete.primitives[guid] == nil
    refute @graph_delete.primitives[duid] == nil
    deleted = Graph.delete(@graph_delete, :group)
    assert Graph.get(deleted, :inner_text) == []
    assert deleted.ids[:inner_text] == nil
    assert Graph.get(deleted, :inner_line) == []
    assert deleted.ids[:inner_line] == nil
    assert Graph.get(deleted, :inner_group) == []
    assert deleted.ids[:inner_group] == nil
    assert Graph.get(deleted, :deep_text) == []
    assert deleted.ids[:deep_text] == nil
  end

  # ============================================================================
  # count - all nodes
  test "count returns 1 if only the root node exists" do
    assert Graph.count(@graph_empty) == 1
  end

  test "count counts the items in the graph" do
    assert Enum.count(@graph_find.primitives) == 6
    assert Graph.count(@graph_find) == 6
  end

  test "count counts the primitives with a given id" do
    assert Graph.count(@graph_ordered, :missing) == 0
    assert Graph.count(@graph_ordered, :text) == 1
    assert Graph.count(@graph_ordered, :line) == 2
  end

  # ============================================================================
  # count from the root
  test "count by root returns the number of elements in the tree via recursion" do
    assert Graph.count(@graph_find) == 6
  end

  # ============================================================================
  # get by developer id
  test "get gets an element by id" do
    [uid] = @graph_find.ids[:outer_text]
    p = Graph.get(@graph_find, :outer_text)
    assert [@graph_find.primitives[uid]] == p
  end

  test "get gets multiple elements by id" do
    [first_uid, second_uid] = @graph_ordered.ids[:line]

    gotten = Graph.get(@graph_ordered, :line)

    assert Enum.member?(gotten, @graph_ordered.primitives[first_uid])
    assert Enum.member?(gotten, @graph_ordered.primitives[second_uid])
  end

  # ============================================================================
  # get
  # returns a list of objects with the given id
  test "get returns a list of primitives with the given id" do
    [first_uid, second_uid] = @graph_ordered.ids[:line]
    [first, second] = Graph.get(@graph_ordered, :line)

    assert @graph_ordered.primitives[first_uid] == first
    assert @graph_ordered.primitives[second_uid] == second
  end

  # ============================================================================
  # get! returns a single object indicated by id

  test "get! returns a single primitive matching the id" do
    text = Graph.get!(@graph_ordered, :text)
    assert text.module == Text
  end

  test "get! raises if it doesn't fine any prmitives" do
    assert_raise Graph.Error, fn ->
      Graph.get!(@graph_ordered, :missing)
    end
  end

  test "get! raises if finds more than one primitive" do
    assert_raise Graph.Error, fn ->
      Graph.get!(@graph_ordered, :line)
    end
  end

  # ============================================================================
  test "find returns the matching items" do
    graph =
      Graph.build()
      |> Text.add_to_graph("text one", id: {:a, :one})
      |> Text.add_to_graph("text two", id: {:a, :two})
      |> Text.add_to_graph("text three", id: {:b, :three})

    # confirm result
    assert Graph.find(graph, &match?({:a, _}, &1)) == [
             Graph.get!(graph, {:a, :one}),
             Graph.get!(graph, {:a, :two})
           ]

    assert Graph.find(graph, &match?({:b, _}, &1)) == [
             Graph.get!(graph, {:b, :three})
           ]
  end


  # ============================================================================
  # add

  test "add a pre-built primitive to a graph" do
    p = Primitive.Line.build({{0, 0}, {2, 2}}, id: :added)
    graph = Graph.add(@graph_find, p)
    Graph.get!(graph, :added)
  end

  test "add a new primitive to a graph" do
    count = Graph.count(@graph_find)

    post_add_count =
      Graph.add(@graph_find, Primitive.Line, {{0, 0}, {2, 2}})
      |> Graph.count()

    assert post_add_count > count
  end

  # ============================================================================
  # add_to

  test "add_to adds to a specified group in a graph via a builder callback" do
    import Scenic.Primitives

    graph =
      Graph.build()
      |> group(fn g -> g end, id: :group_0)
      |> group(fn g -> g end, id: :group_1)
      |> group(fn g -> g end, id: :group_1)

    assert graph.ids == %{_root_: [0], group_0: [1], group_1: [3, 2]}
    assert graph.primitives[1].data == []
    assert graph.primitives[2].data == []
    assert graph.primitives[3].data == []

    # add to one
    graph_out =
      Graph.add_to(graph, :group_0, fn g ->
        line(g, {{0, 0}, {12, 23}}, id: :added_line)
      end)

    assert graph_out.add_to == 0
    assert graph_out.primitives[1].data == [4]
    assert graph_out.primitives[2].data == []
    assert graph_out.primitives[3].data == []
    assert graph_out.primitives[4].data == {{0, 0}, {12, 23}}
    refute graph_out.primitives[5]

    # add to multiple
    graph_out =
      Graph.add_to(graph, :group_1, fn g ->
        line(g, {{0, 0}, {12, 23}}, id: :added_line)
      end)

    assert graph_out.add_to == 0
    assert graph_out.primitives[1].data == []
    assert graph_out.primitives[2].data == [5]
    assert graph_out.primitives[3].data == [4]
    assert graph_out.primitives[4].data == {{0, 0}, {12, 23}}
    assert graph_out.primitives[5].data == {{0, 0}, {12, 23}}
    refute graph_out.primitives[6]
  end

  test "add_to ignores adding to non-groups" do
    import Scenic.Primitives

    graph =
      Graph.build()
      |> line({{0, 0}, {12, 23}}, id: :line)

    assert Graph.add_to(graph, :line, fn g ->
             line(g, {{0, 0}, {12, 23}}, id: :added_line)
           end) == graph
  end

  test "add_to raises if builder returns a non graph" do
    import Scenic.Primitives

    graph =
      Graph.build()
      |> group(fn g -> g end, id: :group_0)
      |> group(fn g -> g end, id: :group_1)
      |> group(fn g -> g end, id: :group_1)

    assert_raise Graph.Error, fn ->
      Graph.add_to(graph, :group_0, fn _ -> 123 end)
    end
  end

  # ============================================================================
  # def modify( graph, uid, action )

  test "modify transforms a single primitive by developer id" do
    # confirm setup
    assert Map.get(Graph.get!(@graph_find, :inner_text), :transforms) == %{}

    # modify the element by assigning a transform to it
    graph =
      Graph.modify(@graph_find, :inner_text, fn p ->
        Primitive.put_transforms(p, @transform)
      end)

    # confirm result
    assert Map.get(Graph.get!(graph, :inner_text), :transforms) == @transform
  end

  test "modify transforms a multiple primitives by developer id" do
    graph =
      Graph.build()
      |> Text.add_to_graph("Some text", id: :text)
      |> Text.add_to_graph("More text", id: :text)

    [uid_0, uid_1] = graph.ids[:text]

    # confirm setup
    assert Map.get(graph.primitives[uid_0], :transforms) == %{}
    assert Map.get(graph.primitives[uid_1], :transforms) == %{}

    # modify the element by assigning a transform to it
    graph =
      Graph.modify(graph, :text, fn p ->
        Primitive.put_transforms(p, @transform)
      end)

    # confirm result
    assert Map.get(graph.primitives[uid_0], :transforms) == @transform
    assert Map.get(graph.primitives[uid_1], :transforms) == @transform
  end

  test "modify modifies transforms" do
    graph =
      Graph.build(rotate: 1.1)
      |> Rectangle.add_to_graph({100, 200}, id: :rect, translate: {10, 11})

    [uid] = graph.ids[:rect]

    graph =
      Graph.modify(graph, :rect, fn p ->
        Primitive.put_transform(p, :rotate, 2.0)
      end)

    rect = graph.primitives[uid]
    assert Primitive.get_transforms(rect) == %{translate: {10, 11}, rotate: 2.0}
  end

  test "modify modifies styles" do
    graph =
      Graph.build(rotate: 1.1)
      |> Rectangle.add_to_graph({100, 200}, id: :rect, fill: :red)

    [uid] = graph.ids[:rect]

    graph =
      Graph.modify(graph, :rect, fn p ->
        Primitive.put_style(p, :stroke, {2, :blue})
      end)

    rect = graph.primitives[uid]
    assert Primitive.get_styles(rect) ==
      %{fill: {:color, {:color_rgba, {255, 0, 0, 255}}}, stroke: {2, {:color, {:color_rgba, {0, 0, 255, 255}}}}}
  end


  test "modify transforms a via a match function" do
    graph =
      Graph.build()
      |> Text.add_to_graph("text one", id: {:a, :one})
      |> Text.add_to_graph("text two", id: {:a, :two})
      |> Text.add_to_graph("text three", id: {:b, :three})

    # modify the element by assigning a transform to it
    graph =
      Graph.modify(graph, &match?({:a, _}, &1), fn p ->
        Primitive.put_transforms(p, @transform)
      end)

    # confirm result
    assert Map.get(Graph.get!(graph, {:a, :one}), :transforms) == @transform
    assert Map.get(Graph.get!(graph, {:a, :two}), :transforms) == @transform
    assert Map.get(Graph.get!(graph, {:b, :three}), :transforms) == %{}
  end

  # ============================================================================
  # reduce(graph, acc, action) - whole tree

  test "reduce recurses over entire tree" do
    assert Graph.reduce(@graph_find, 0, fn _, acc ->
             acc + 1
           end) == 6
  end

  # reduce(graph, id, acc, action) - just mapped to id
  test "reduce reduces just nodes mapped to a mapped id" do
    graph =
      Graph.build()
      |> Text.add_to_graph("Some text", id: :text)
      |> Text.add_to_graph("More text", id: :text)
      |> Text.add_to_graph("Other text", id: :other_text)

    assert Graph.reduce(graph, :text, 0, fn _, acc ->
             acc + 1
           end) == 2

    assert Graph.reduce(graph, :other_text, 0, fn _, acc ->
             acc + 1
           end) == 1
  end

  test "reduce honors max_depth" do
    graph = Map.put(@graph_find, :max_depth, 1)

    assert_raise Graph.Error, fn ->
      Graph.reduce(graph, 0, fn _, acc -> acc + 1 end)
    end
  end

  test "reduce honors max_depth default - with circular graph" do
    # set up a very simple circular graph
    graph = Graph.build()

    root =
      graph.primitives[@root_uid]
      |> Map.put(:data, [0])

    primitives =
      graph.primitives
      |> Map.put(@root_uid, root)

    graph = Map.put(graph, :primitives, primitives)

    assert_raise Graph.Error, fn ->
      Graph.reduce(graph, 0, fn _, acc -> acc + 1 end)
    end
  end

  # ============================================================================
  # map(graph, action) - whole tree
  test "map recurses over entire tree" do
    # confirm setup
    assert Graph.reduce(@graph_find, true, fn p, f ->
             f && Map.get(p, :transforms) == %{}
           end)

    graph =
      Graph.map(@graph_find, fn p ->
        Primitive.put_transforms(p, @transform)
      end)

    # confirm result
    assert Graph.reduce(graph, true, fn p, f ->
             f && Map.get(p, :transforms) == @transform
           end)
  end

  test "map honors max_depth" do
    graph = Map.put(@graph_find, :max_depth, 1)

    assert_raise Graph.Error, fn ->
      Graph.map(graph, fn p -> p end)
    end
  end

  test "map honors max_depth default - with circular graph" do
    # set up a very simple circular graph
    graph = Graph.build()

    root =
      graph.primitives[@root_uid]
      |> Map.put(:data, [0])

    primitives =
      graph.primitives
      |> Map.put(@root_uid, root)

    graph = Map.put(graph, :primitives, primitives)

    assert_raise Graph.Error, fn ->
      Graph.map(graph, fn p -> p end)
    end
  end

  # ============================================================================
  # map_id(graph, id, action) - just mapped to id
  test "map_id only maps nodes with a mapped id" do
    graph =
      Graph.build()
      |> Text.add_to_graph("Some text", id: :text)
      |> Text.add_to_graph("More text", id: :text)
      |> Text.add_to_graph("Other text", id: :other_text)

    [t0, t1] = graph.ids[:text]
    [other] = graph.ids[:other_text]

    # confirm setup
    assert Map.get(graph.primitives[t0], :transforms) == %{}
    assert Map.get(graph.primitives[t1], :transforms) == %{}
    assert Map.get(graph.primitives[other], :transforms) == %{}

    graph =
      Graph.map(graph, :text, fn p ->
        Primitive.put_transforms(p, @transform)
      end)

    # confirm result
    assert Map.get(graph.primitives[t0], :transforms) == @transform
    assert Map.get(graph.primitives[t1], :transforms) == @transform
    assert Map.get(graph.primitives[other], :transforms) == %{}
  end

  test "style_stack returns an empty map for invalid uid" do
    assert Graph.style_stack(@graph_find, 1234) == %{}
  end
end
