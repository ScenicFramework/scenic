#
#  Created by Boyd Multerer on 2018-04-30.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
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
    g = Primitives.arc(@graph, {0, 1, 20})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Arc
    assert p.data == {0, 1, 20}
  end

  test "arc adds to a graph" do
    p =
      Primitives.arc(@graph, {0, 1, 20}, id: :arc)
      |> Graph.get!(:arc)

    assert p.module == Scenic.Primitive.Arc
    assert p.data == {0, 1, 20}
    assert p.id == :arc
  end

  test "arc modifies primitive data" do
    p =
      Primitives.arc(@graph, {0, 1, 20}, id: :arc)
      |> Graph.get!(:arc)
      |> Primitives.arc({0, 1.5, 200}, id: :modified)

    assert p.data == {0, 1.5, 200}
    assert p.id == :modified
  end

  test "arc adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.arc_spec({0, 1, 20}, id: :arc)
      ])
      |> Graph.get!(:arc)

    assert p.module == Scenic.Primitive.Arc
    assert p.data == {0, 1, 20}
    assert p.id == :arc
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

  # test "group modifies primitive" do
  #   p = Primitives.group(@graph, fn(g) -> g end, id: :group)
  #   |> Graph.get!(1)
  #   |> Primitives.group(fn(g) ->
  #     Primitives.ellipse(g, {20,30})
  #   end, id: :modified)
  #   assert p.module == Scenic.Primitive.Group
  #   assert Enum.count(p.data) == 1
  #   assert p.id == :group
  # end

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
    assert p.data == []
  end

  test "path adds empty list to the graph" do
    actions = []

    p =
      Primitives.path(@graph, actions, id: :path)
      |> Graph.get!(:path)

    assert p.module == Scenic.Primitive.Path
    assert p.data == actions
    assert p.id == :path
  end

  test "path adds actions to the graph" do
    actions = [
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
  test "scene_ref adds to a graph - default opts" do
    key = {:graph, make_ref(), 123}

    g = Primitives.scene_ref(@graph, key)
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == key
  end

  test "scene_ref adds graph key reference to a graph" do
    key = {:graph, make_ref(), 123}

    p =
      Primitives.scene_ref(@graph, key, id: :ref)
      |> Graph.get!(:ref)

    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == key
    assert p.id == :ref
  end

  test "scene_ref adds named scene reference to a graph" do
    p =
      Primitives.scene_ref(@graph, :scene_name, id: :ref)
      |> Graph.get!(:ref)

    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == :scene_name
    assert p.id == :ref
  end

  test "scene_ref adds pid scene reference to a graph" do
    p =
      Primitives.scene_ref(@graph, self(), id: :ref)
      |> Graph.get!(:ref)

    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == {self(), nil}
    assert p.id == :ref
  end

  test "scene_ref adds named scene with id reference to a graph" do
    p =
      Primitives.scene_ref(@graph, {:scene_name, 123}, id: :ref)
      |> Graph.get!(:ref)

    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == {:scene_name, 123}
    assert p.id == :ref
  end

  test "scene_ref adds pid with id reference to a graph" do
    p =
      Primitives.scene_ref(@graph, {self(), 123}, id: :ref)
      |> Graph.get!(:ref)

    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == {self(), 123}
    assert p.id == :ref
  end

  test "scene_ref adds dynamic reference to a graph" do
    p =
      Primitives.scene_ref(@graph, {{:mod, "abc"}, 123}, id: :ref)
      |> Graph.get!(:ref)

    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == {{:mod, "abc"}, 123}
    assert p.id == :ref
  end

  test "scene_ref modifies primitive" do
    p =
      Primitives.scene_ref(@graph, {{:mod, "abc"}, 123}, id: :ref)
      |> Graph.get!(:ref)
      |> Primitives.scene_ref({{:new_mod, "abcd"}, 456}, id: :modified)

    assert p.data == {{:new_mod, "abcd"}, 456}
    assert p.id == :modified
  end

  test "scene_ref adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.scene_ref_spec({self(), 123}, id: :scene_ref)
      ])
      |> Graph.get!(:scene_ref)

    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == {self(), 123}
    assert p.id == :scene_ref
  end

  # ============================================================================
  test "sector adds to a graph - default opts" do
    g = Primitives.sector(@graph, {0, 1, 20})
    p = g.primitives[1]

    assert p.module == Scenic.Primitive.Sector
    assert p.data == {0, 1, 20}
  end

  test "sector adds to a graph" do
    p =
      Primitives.sector(@graph, {0, 1, 20}, id: :sector)
      |> Graph.get!(:sector)

    assert p.module == Scenic.Primitive.Sector
    assert p.data == {0, 1, 20}
    assert p.id == :sector
  end

  test "sector modifies primitive" do
    p =
      Primitives.sector(@graph, {1, 1, 20}, id: :sector)
      |> Graph.get!(:sector)
      |> Primitives.sector({1, 1.5, 22}, id: :modified)

    assert p.data == {1, 1.5, 22}
    assert p.id == :modified
  end

  test "sector adds via spec" do
    p =
      @graph
      |> Primitives.add_specs_to_graph([
        Primitives.sector_spec({1, 1.5, 22}, id: :sector)
      ])
      |> Graph.get!(:sector)

    assert p.module == Scenic.Primitive.Sector
    assert p.data == {1, 1.5, 22}
    assert p.id == :sector
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
      Primitives.arc(@graph, {0, 1, 20}, id: :arc)
      |> Graph.get!(:arc)
      |> Primitives.update_opts(id: :modified)

    assert p.data == {0, 1, 20}
    assert p.id == :modified
  end

  test "test update_opts is additive to existing opts" do
    p =
      Primitives.arc(@graph, {0, 1, 20}, id: :arc, translate: {1, 2})
      |> Graph.get!(:arc)
      |> Primitives.update_opts(rotate: 1)

    assert p.data == {0, 1, 20}
    assert p.id == :arc
    assert p.transforms == %{rotate: 1, translate: {1, 2}}
  end
end
