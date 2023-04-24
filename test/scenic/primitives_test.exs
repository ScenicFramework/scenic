#
#  Created by Boyd Multerer on 2018-04-30.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

defmodule Scenic.PrimitivesTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitives

  alias Scenic.Graph
  # alias Scenic.Primitive
  alias Scenic.Primitives

  @graph Graph.build()

  # @tau    2.0 * :math.pi();

  # import IEx

  # ============================================================================
  test "arc adds to a graph - default opts" do
    g = Primitives.arc(@graph, {10, 20})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Arc
    assert p.data == {10, 20}
  end

  test "arc adds to a graph" do
    p =
      Primitives.arc(@graph, {10, 20}, id: :arc)
      |> Graph.get!(:arc)

    assert p.module == Scenic.Primitive.Arc
    assert p.data == {10, 20}
    assert p.id == :arc
  end

  test "arc modifies primitive data" do
    p =
      Primitives.arc(@graph, {10, 20}, id: :arc)
      |> Graph.get!(:arc)
      |> Primitives.arc({11, 200}, id: :modified)

    assert p.data == {11, 200}
    assert p.id == :modified
  end

  test "arc adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.arc_spec({10, 20}, id: :arc)
      ])
      |> Graph.get!(:arc)

    assert p.module == Scenic.Primitive.Arc
    assert p.data == {10, 20}
    assert p.id == :arc
  end

  test "arc rejects old format" do
    assert_raise FunctionClauseError, fn ->
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.arc_spec({10, 11, 20}, id: :arc)
      ])
      |> Graph.get!(:arc)
    end
  end

  # ============================================================================
  test "circle adds to a graph - default opts" do
    g = Primitives.circle(@graph, 20)
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Circle
    assert p.data == 20
  end

  test "circle adds to a graph" do
    p =
      Primitives.circle(@graph, 20, id: :circle)
      |> Graph.get!(:circle)

    assert p.module == Scenic.Primitive.Circle
    assert p.data == 20
    assert p.id == :circle
  end

  test "circle modifies primitive with simple data" do
    p =
      Primitives.circle(@graph, 20, id: :circle)
      |> Graph.get!(:circle)
      |> Primitives.circle(40, id: :modified)

    assert p.data == 40
    assert p.id == :modified
  end

  test "circle adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.circle_spec(20, id: :circle)
      ])
      |> Graph.get!(:circle)

    assert p.module == Scenic.Primitive.Circle
    assert p.data == 20
    assert p.id == :circle
  end

  # ============================================================================
  test "ellipse adds to a graph - default opts" do
    g = Primitives.ellipse(@graph, {20, 30})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Ellipse
    assert p.data == {20, 30}
  end

  test "ellipse adds to a graph" do
    p =
      Primitives.ellipse(@graph, {20, 30}, id: :ellipse)
      |> Graph.get!(:ellipse)

    assert p.module == Scenic.Primitive.Ellipse
    assert p.data == {20, 30}
    assert p.id == :ellipse
  end

  test "ellipse modifies primitive with simple data" do
    p =
      Primitives.ellipse(@graph, {20, 30}, id: :ellipse)
      |> Graph.get!(:ellipse)
      |> Primitives.ellipse({40, 50}, id: :modified)

    assert p.data == {40, 50}
    assert p.id == :modified
  end

  test "ellipse adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.ellipse_spec({20, 30}, id: :ellipse)
      ])
      |> Graph.get!(:ellipse)

    assert p.module == Scenic.Primitive.Ellipse
    assert p.data == {20, 30}
    assert p.id == :ellipse
  end

  # ============================================================================
  test "group adds to a graph - default opts" do
    g = Primitives.group(@graph, fn g -> g end)
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Group
    assert p.data == []
  end

  test "group adds to a graph" do
    p =
      Primitives.group(@graph, fn g -> g end, id: :group)
      |> Graph.get!(:group)

    assert p.module == Scenic.Primitive.Group
    assert p.data == []
    assert p.id == :group
  end

  test "group adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.group_spec([], id: :group)
      ])
      |> Graph.get!(:group)

    assert p.module == Scenic.Primitive.Group
    assert p.data == []
    assert p.id == :group
  end

  test "group adds via reverse spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.group_spec_r([id: :group], [])
      ])
      |> Graph.get!(:group)

    assert p.module == Scenic.Primitive.Group
    assert p.data == []
    assert p.id == :group
  end

  # ============================================================================
  test "line adds to a graph - default opts" do
    g = Primitives.line(@graph, {{0, 0}, {10, 100}})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Line
    assert p.data == {{0, 0}, {10, 100}}
  end

  test "line adds to a graph" do
    p =
      Primitives.line(@graph, {{0, 0}, {10, 100}}, id: :line)
      |> Graph.get!(:line)

    assert p.module == Scenic.Primitive.Line
    assert p.data == {{0, 0}, {10, 100}}
    assert p.id == :line
  end

  test "line modifies primitive with full data" do
    p =
      Primitives.line(@graph, {{0, 0}, {10, 100}}, id: :line)
      |> Graph.get!(:line)
      |> Primitives.line({{10, 20}, {100, 200}}, id: :modified)

    assert p.data == {{10, 20}, {100, 200}}
    assert p.id == :modified
  end

  test "line adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.line_spec({{0, 0}, {10, 100}}, id: :line)
      ])
      |> Graph.get!(:line)

    assert p.module == Scenic.Primitive.Line
    assert p.data == {{0, 0}, {10, 100}}
    assert p.id == :line
  end

  # ============================================================================
  test "path adds to a graph - default opts" do
    g = Primitives.path(@graph, [])
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Path
    assert p.data == [:begin]
  end

  test "path adds empty list to the graph" do
    actions = []

    p =
      Primitives.path(@graph, actions, id: :path)
      |> Graph.get!(:path)

    assert p.module == Scenic.Primitive.Path
    assert p.data == [:begin]
    assert p.id == :path
  end

  test "path adds actions to the graph" do
    actions = [
      :begin,
      {:move_to, 1, 2},
      {:line_to, 3, 4},
      {:line_to, 3, 5}
    ]

    p =
      Primitives.path(@graph, actions, id: :path)
      |> Graph.get!(:path)

    assert p.module == Scenic.Primitive.Path
    assert p.data == actions
    assert p.id == :path
  end

  test "path modifies primitive" do
    actions = [
      {:move_to, 1, 2},
      {:line_to, 3, 4},
      {:line_to, 3, 5}
    ]

    p =
      Primitives.path(@graph, actions, id: :path)
      |> Graph.get!(:path)

    actions2 = [
      :begin,
      {:move_to, 1, 2},
      {:line_to, 3, 4},
      {:bezier_to, 10, 11, 20, 21, 30, 40}
    ]

    p = Primitives.path(p, actions2, id: :modified)
    assert p.data == actions2
    assert p.id == :modified
  end

  test "path adds via spec" do
    actions = [
      :begin,
      {:move_to, 1, 2},
      {:line_to, 3, 4},
      {:line_to, 3, 5}
    ]

    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.path_spec(actions, id: :path)
      ])
      |> Graph.get!(:path)

    assert p.module == Scenic.Primitive.Path
    assert p.data == actions
    assert p.id == :path
  end

  # ============================================================================
  test "quad adds to a graph - default opts" do
    g = Primitives.quad(@graph, {{1, 2}, {3, 4}, {3, 10}, {2, 8}})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Quad
    assert p.data == {{1, 2}, {3, 4}, {3, 10}, {2, 8}}
  end

  test "quad adds to a graph" do
    p =
      Primitives.quad(@graph, {{1, 2}, {3, 4}, {3, 10}, {2, 8}}, id: :quad)
      |> Graph.get!(:quad)

    assert p.module == Scenic.Primitive.Quad
    assert p.data == {{1, 2}, {3, 4}, {3, 10}, {2, 8}}
    assert p.id == :quad
  end

  test "quad modifies primitive with full data" do
    p =
      Primitives.quad(@graph, {{1, 2}, {3, 4}, {3, 10}, {2, 8}}, id: :quad)
      |> Graph.get!(:quad)
      |> Primitives.quad({{10, 20}, {30, 40}, {30, 100}, {20, 80}}, id: :modified)

    assert p.data == {{10, 20}, {30, 40}, {30, 100}, {20, 80}}
    assert p.id == :modified
  end

  test "quad adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.quad_spec({{10, 20}, {30, 40}, {30, 100}, {20, 80}}, id: :quad)
      ])
      |> Graph.get!(:quad)

    assert p.module == Scenic.Primitive.Quad
    assert p.data == {{10, 20}, {30, 40}, {30, 100}, {20, 80}}
    assert p.id == :quad
  end

  # ============================================================================
  test "rect adds to a graph - default opts" do
    g = Primitives.rect(@graph, {200, 100})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Rectangle
    assert p.data == {200, 100}
  end

  test "rect adds to a graph" do
    p =
      Primitives.rect(@graph, {200, 100}, id: :rect)
      |> Graph.get!(:rect)

    assert p.module == Scenic.Primitive.Rectangle
    assert p.data == {200, 100}
    assert p.id == :rect
  end

  test "rect modifies primitive" do
    p =
      Primitives.rect(@graph, {200, 100}, id: :rect)
      |> Graph.get!(:rect)
      |> Primitives.rect({20, 10}, id: :modified)

    assert p.data == {20, 10}
    assert p.id == :modified
  end

  test "rect adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.rect_spec({200, 100}, id: :rect)
      ])
      |> Graph.get!(:rect)

    assert p.module == Scenic.Primitive.Rectangle
    assert p.data == {200, 100}
    assert p.id == :rect
  end

  # ============================================================================
  test "rectangle adds to a graph - default opts" do
    g = Primitives.rectangle(@graph, {200, 100})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Rectangle
    assert p.data == {200, 100}
  end

  test "rectangle adds to a graph" do
    p =
      Primitives.rectangle(@graph, {200, 100}, id: :rectangle)
      |> Graph.get!(:rectangle)

    assert p.module == Scenic.Primitive.Rectangle
    assert p.data == {200, 100}
    assert p.id == :rectangle
  end

  test "rectangle modifies primitive" do
    p =
      Primitives.rectangle(@graph, {200, 100}, id: :rectangle)
      |> Graph.get!(:rectangle)
      |> Primitives.rectangle({20, 10}, id: :modified)

    assert p.data == {20, 10}
    assert p.id == :modified
  end

  test "rectangle adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.rectangle_spec({200, 100}, id: :rectangle)
      ])
      |> Graph.get!(:rectangle)

    assert p.module == Scenic.Primitive.Rectangle
    assert p.data == {200, 100}
    assert p.id == :rectangle
  end

  # ============================================================================
  test "rrect adds to a graph - default opts" do
    g = Primitives.rrect(@graph, {200, 100, 5})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.RoundedRectangle
    assert p.data == {200, 100, 5}
  end

  test "rrect adds to a graph" do
    p =
      Primitives.rrect(@graph, {200, 100, 5}, id: :rrect)
      |> Graph.get!(:rrect)

    assert p.module == Scenic.Primitive.RoundedRectangle
    assert p.data == {200, 100, 5}
    assert p.id == :rrect
  end

  test "rrect modifies primitive" do
    p =
      Primitives.rrect(@graph, {200, 100, 5}, id: :rrect)
      |> Graph.get!(:rrect)
      |> Primitives.rrect({20, 10, 2}, id: :modified)

    assert p.data == {20, 10, 2}
    assert p.id == :modified
  end

  test "rrect adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.rrect_spec({20, 10, 2}, id: :rounded_rectangle)
      ])
      |> Graph.get!(:rounded_rectangle)

    assert p.module == Scenic.Primitive.RoundedRectangle
    assert p.data == {20, 10, 2}
    assert p.id == :rounded_rectangle
  end

  # ============================================================================
  test "rounded_rectangle adds to a graph - default opts" do
    g = Primitives.rounded_rectangle(@graph, {200, 100, 5})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.RoundedRectangle
    assert p.data == {200, 100, 5}
  end

  test "rounded_rectangle adds to a graph" do
    p =
      Primitives.rounded_rectangle(@graph, {200, 100, 5}, id: :rounded_rectangle)
      |> Graph.get!(:rounded_rectangle)

    assert p.module == Scenic.Primitive.RoundedRectangle
    assert p.data == {200, 100, 5}
    assert p.id == :rounded_rectangle
  end

  test "rounded_rectangle modifies primitive" do
    p =
      Primitives.rounded_rectangle(@graph, {200, 100, 5}, id: :rounded_rectangle)
      |> Graph.get!(:rounded_rectangle)
      |> Primitives.rounded_rectangle({20, 10, 2}, id: :modified)

    assert p.data == {20, 10, 2}
    assert p.id == :modified
  end

  test "rounded_rectangle adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.rounded_rectangle_spec({20, 10, 2}, id: :rounded_rectangle)
      ])
      |> Graph.get!(:rounded_rectangle)

    assert p.module == Scenic.Primitive.RoundedRectangle
    assert p.data == {20, 10, 2}
    assert p.id == :rounded_rectangle
  end

  # ============================================================================
  test "script adds a script to a graph - default opts" do
    g = Primitives.script(@graph, "some_script_name")
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Script
    assert p.data == "some_script_name"
  end

  test "script adds a script to a graph" do
    p =
      Primitives.script(@graph, "some_script_name", id: :script)
      |> Graph.get!(:script)

    assert p.module == Scenic.Primitive.Script
    assert p.data == "some_script_name"
    assert p.id == :script
  end

  test "script modifies primitive" do
    p =
      Primitives.script(@graph, "some_script_name", id: :script)
      |> Graph.get!(:script)
      |> Primitives.script("some_other_name", id: :modified)

    assert p.data == "some_other_name"
    assert p.id == :modified
  end

  test "script adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.script_spec("some_script_name", id: :script)
      ])
      |> Graph.get!(:script)

    assert p.module == Scenic.Primitive.Script
    assert p.data == "some_script_name"
    assert p.id == :script
  end

  # ============================================================================
  test "sector adds to a graph - default opts" do
    g = Primitives.sector(@graph, {10, 20})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Sector
    assert p.data == {10, 20}
  end

  test "sector adds to a graph" do
    p =
      Primitives.sector(@graph, {10, 20}, id: :sector)
      |> Graph.get!(:sector)

    assert p.module == Scenic.Primitive.Sector
    assert p.data == {10, 20}
    assert p.id == :sector
  end

  test "sector modifies primitive" do
    p =
      Primitives.sector(@graph, {10, 20}, id: :sector)
      |> Graph.get!(:sector)
      |> Primitives.sector({15, 22}, id: :modified)

    assert p.data == {15, 22}
    assert p.id == :modified
  end

  test "sector adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.sector_spec({15, 22}, id: :sector)
      ])
      |> Graph.get!(:sector)

    assert p.module == Scenic.Primitive.Sector
    assert p.data == {15, 22}
    assert p.id == :sector
  end

  test "sector rejects old format" do
    assert_raise FunctionClauseError, fn ->
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.sector_spec({1, 1.5, 22}, id: :sector)
      ])
      |> Graph.get!(:sector)
    end
  end

  # ============================================================================
  test "text adds to a graph - default opts" do
    g = Primitives.text(@graph, "test text")
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Text
    assert p.data == "test text"
  end

  test "text adds default to a graph" do
    p =
      Primitives.text(@graph, "test text", id: :text)
      |> Graph.get!(:text)

    assert p.module == Scenic.Primitive.Text
    assert p.data == "test text"
    assert p.id == :text
  end

  test "text modifies primitive" do
    p =
      Primitives.text(@graph, "Hello", id: :text)
      |> Graph.get!(:text)
      |> Primitives.text("World", id: :modified)

    assert p.data == "World"
    assert p.id == :modified
  end

  test "text adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.text_spec("test text", id: :text)
      ])
      |> Graph.get!(:text)

    assert p.module == Scenic.Primitive.Text
    assert p.data == "test text"
    assert p.id == :text
  end

  # ============================================================================
  test "triangle adds to a graph - default opts" do
    g = Primitives.triangle(@graph, {{0, 0}, {10, 100}, {100, 40}})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Triangle
    assert p.data == {{0, 0}, {10, 100}, {100, 40}}
  end

  test "triangle adds to a graph" do
    p =
      Primitives.triangle(@graph, {{0, 0}, {10, 100}, {100, 40}}, id: :triangle)
      |> Graph.get!(:triangle)

    assert p.module == Scenic.Primitive.Triangle
    assert p.data == {{0, 0}, {10, 100}, {100, 40}}
    assert p.id == :triangle
  end

  test "triangle modifies primitive" do
    p =
      Primitives.triangle(@graph, {{0, 0}, {10, 100}, {100, 40}}, id: :triangle)
      |> Graph.get!(:triangle)
      |> Primitives.triangle({{1, 2}, {11, 102}, {101, 42}}, id: :modified)

    assert p.data == {{1, 2}, {11, 102}, {101, 42}}
    assert p.id == :modified
  end

  test "triangle adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.triangle_spec({{1, 2}, {11, 102}, {101, 42}}, id: :triangle)
      ])
      |> Graph.get!(:triangle)

    assert p.module == Scenic.Primitive.Triangle
    assert p.data == {{1, 2}, {11, 102}, {101, 42}}
    assert p.id == :triangle
  end

  # ============================================================================
  test "test update_opts" do
    p =
      Primitives.rect(@graph, {10, 20}, id: :rect)
      |> Graph.get!(:rect)
      |> Primitives.update_opts(id: :modified)

    assert p.data == {10, 20}
    assert p.id == :modified
  end

  test "test update_opts is additive to existing opts" do
    p =
      Primitives.rect(@graph, {10, 20}, id: :rect, translate: {1, 2})
      |> Graph.get!(:rect)
      |> Primitives.update_opts(rotate: 1)

    assert p.data == {10, 20}
    assert p.id == :rect
    assert p.transforms == %{rotate: 1, translate: {1, 2}}
  end
end
