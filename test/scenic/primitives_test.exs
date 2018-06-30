#
#  Created by Boyd Multerer on April 30, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.PrimitivesTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitives
  alias Scenic.Graph
  # alias Scenic.Primitive
  alias Scenic.Primitives

  @graph  Graph.build()

  # @tau    2.0 * :math.pi();

 # import IEx


  #============================================================================
  test "arc adds simple default to a graph" do
    p = Primitives.arc(@graph, {0, 1, 20}, id: :arc)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Arc
    assert p.data == {{0,0}, 0, 1, 20}
    assert p.id == :arc
  end

  test "arc adds x, y default to a graph" do
    p = Primitives.arc(@graph, {{1,2}, 0, 1, 20}, id: :arc)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Arc
    assert p.data == {{1,2}, 0, 1, 20}
    assert p.id == :arc
  end

  test "arc modifies primitive with simple data" do
    p = Primitives.arc(@graph, {0, 1, 20}, id: :arc)
    |> Graph.get(1)
    |> Primitives.arc({0, 1.5, 200}, id: :modified)
    assert p.data == {{0,0}, 0, 1.5, 200}
    assert p.id == :modified
  end

  test "arc modifies primitive with full data" do
    p = Primitives.arc(@graph, {0, 1, 20}, id: :arc)
    |> Graph.get(1)
    |> Primitives.arc({{10, 20}, 0, 1.5, 200}, id: :modified)
    assert p.data == {{10, 20}, 0, 1.5, 200}
    assert p.id == :modified
  end

  #============================================================================
  test "circle adds default to a graph" do
    p = Primitives.circle(@graph, 20, id: :circle)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Circle
    assert p.data == {{0,0}, 20}
    assert p.id == :circle
  end

  test "circle adds positioned circle to a graph" do
    p = Primitives.circle(@graph, {{1,2}, 20}, id: :circle)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Circle
    assert p.data == {{1,2}, 20}
    assert p.id == :circle
  end


  test "circle modifies primitive with simple data" do
    p = Primitives.circle(@graph, 20, id: :circle)
    |> Graph.get(1)
    |> Primitives.circle(40, id: :modified)
    assert p.data == {{0,0}, 40}
    assert p.id == :modified
  end

  test "circle modifies primitive with full data" do
    p = Primitives.circle(@graph, 20, id: :circle)
    |> Graph.get(1)
    |> Primitives.circle({{10, 20}, 40}, id: :modified)
    assert p.data == {{10, 20}, 40}
    assert p.id == :modified
  end


  #============================================================================
  test "ellipse adds to a graph" do
    p = Primitives.ellipse(@graph, {20,30}, id: :ellipse)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Ellipse
    assert p.data == {{0,0}, 20, 30}
    assert p.id == :ellipse
  end

  test "ellipse adds with position to a graph" do
    p = Primitives.ellipse(@graph, {{1,2}, 20, 30}, id: :ellipse)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Ellipse
    assert p.data == {{1,2}, 20, 30}
    assert p.id == :ellipse
  end


  #============================================================================
  test "group adds to a graph" do
    p = Primitives.group(@graph, fn(g) -> g end, id: :group)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Group
    assert p.id == :group
  end


  #============================================================================
  test "line adds to a graph" do
    p = Primitives.line(@graph, {{0,0}, {10, 100}}, id: :line)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Line
    assert p.data == {{0, 0}, {10, 100}}
    assert p.id == :line
  end


  #============================================================================
  test "path adds empty list to the graph" do
    actions = []
    p = Primitives.path( @graph, actions, id: :path )
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Path
    assert p.data == actions
    assert p.id == :path
  end

  test "path adds actions to the graph" do
    actions = [
      {:move_to, 1, 2},
      {:line_to, 3, 4},
      {:line_to, 3, 5},
    ]
    p = Primitives.path( @graph, actions, id: :path )
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Path
    assert p.data == actions
    assert p.id == :path
  end


  #============================================================================
  test "quad adds to a graph" do
    p = Primitives.quad(@graph, {{1,2}, {3,4}, {3, 10}, {2, 8}}, id: :quad)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Quad
    assert p.data == {{1,2}, {3,4}, {3, 10}, {2, 8}}
    assert p.id == :quad
  end


  #============================================================================
  test "rect adds default to a graph" do
    p = Primitives.rect(@graph, {200, 100}, id: :rect)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Rectangle
    assert p.data == {{0,0}, 200, 100}
    assert p.id == :rect
  end

  test "rect adds to a graph" do
    p = Primitives.rect(@graph, {{10,20}, 200, 100}, id: :rect)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Rectangle
    assert p.data == {{10,20}, 200, 100}
    assert p.id == :rect
  end


  #============================================================================
  test "rectangle adds default to a graph" do
    p = Primitives.rectangle(@graph, {200, 100}, id: :rectangle)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Rectangle
    assert p.data == {{0,0}, 200, 100}
    assert p.id == :rectangle
  end

  test "rectangle adds to a graph" do
    p = Primitives.rectangle(@graph, {{10,20}, 200, 100}, id: :rectangle)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Rectangle
    assert p.data == {{10,20}, 200, 100}
    assert p.id == :rectangle
  end


  #============================================================================
  test "rrect adds default to a graph" do
    p = Primitives.rrect(@graph, {200, 100, 5}, id: :rrect)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.RoundedRectangle
    assert p.data == {{0,0}, 200, 100, 5}
    assert p.id == :rrect
  end

  test "rrect adds to a graph" do
    p = Primitives.rrect(@graph, {{10,20}, 200, 100, 5}, id: :rrect)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.RoundedRectangle
    assert p.data == {{10,20}, 200, 100, 5}
    assert p.id == :rrect
  end


  #============================================================================
  test "rounded_rectangle adds default to a graph" do
    p = Primitives.rounded_rectangle(@graph, {200, 100, 5}, id: :rounded_rectangle)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.RoundedRectangle
    assert p.data == {{0,0}, 200, 100, 5}
    assert p.id == :rounded_rectangle
  end

  test "rounded_rectangle adds to a graph" do
    p = Primitives.rounded_rectangle(@graph, {{10,20}, 200, 100, 5}, id: :rounded_rectangle)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.RoundedRectangle
    assert p.data == {{10,20}, 200, 100, 5}
    assert p.id == :rounded_rectangle
  end


  #============================================================================
  test "scene_ref adds graph key reference to a graph" do
    key = {:graph, make_ref(), 123}
    p = Primitives.scene_ref(@graph, key, id: :ref)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == key
    assert p.id == :ref
  end

  test "scene_ref adds named scene reference to a graph" do
    p = Primitives.scene_ref(@graph, :scene_name, id: :ref)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == {:scene_name, nil}
    assert p.id == :ref
  end

  test "scene_ref adds pid scene reference to a graph" do
    p = Primitives.scene_ref(@graph, self(), id: :ref)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == {self(), nil}
    assert p.id == :ref
  end

  test "scene_ref adds named scene with id reference to a graph" do
    p = Primitives.scene_ref(@graph, {:scene_name, 123}, id: :ref)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == {:scene_name, 123}
    assert p.id == :ref
  end

  test "scene_ref adds pid with id reference to a graph" do
    p = Primitives.scene_ref(@graph, {self(), 123}, id: :ref)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == {self(), 123}
    assert p.id == :ref
  end

  test "scene_ref adds dynamic reference to a graph" do
    p = Primitives.scene_ref(@graph, {{:mod, "abc"}, 123}, id: :ref)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.SceneRef
    assert p.data == {{:mod, "abc"}, 123}
    assert p.id == :ref
  end


  #============================================================================
  test "sector adds simple default to a graph" do
    p = Primitives.sector(@graph, {0, 1, 20}, id: :sector)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Sector
    assert p.data == {{0,0}, 0, 1, 20}
    assert p.id == :sector
  end

  test "sector adds x, y default to a graph" do
    p = Primitives.sector(@graph, {{1,2}, 0, 1, 20}, id: :sector)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Sector
    assert p.data == {{1,2}, 0, 1, 20}
    assert p.id == :sector
  end


  #============================================================================
  test "text adds default to a graph" do
    p = Primitives.text(@graph, "test text", id: :text)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Text
    assert p.data == {{0, 0}, "test text"}
    assert p.id == :text
  end

  test "text adds to a graph" do
    p = Primitives.text(@graph, {{10, 100}, "test text"}, id: :text)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Text
    assert p.data == {{10, 100}, "test text"}
    assert p.id == :text
  end


  #============================================================================
  test "triangle adds to a graph" do
    p = Primitives.triangle(@graph, {{0,0}, {10, 100}, {100, 40}}, id: :triangle)
    |> Graph.get(1)
    assert p.module == Scenic.Primitive.Triangle
    assert p.data == {{0,0}, {10, 100}, {100, 40}}
    assert p.id == :triangle
  end

end