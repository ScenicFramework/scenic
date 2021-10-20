#
#  Created by Boyd Multerer on 2021-02-07.
#  Copyright 2021 Kry10 Limited
#

defmodule Scenic.Graph.BoundsTest do
  use ExUnit.Case, async: true
  doctest Scenic.Graph.Bounds

  alias Scenic.Graph

  # import IEx

  import Scenic.Primitives

  defmodule ComponentBounds do
    use Scenic.Component
    def validate({l, t, r, b}), do: {:ok, {l, t, r, b}}
    def init(scene, _ltrb, _opts), do: {:ok, scene}
    def bounds(ltrb, _tyles), do: ltrb
  end

  defmodule ComponentNoBounds do
    use Scenic.Component
    def validate({l, t, r, b}), do: {:ok, {l, t, r, b}}
    def init(scene, _ltrb, _opts), do: {:ok, scene}
  end

  test "finds the natural bounds of an arc" do
    graph = Graph.build() |> arc({100, 1.2})
    {l, 0.0, 100.0, b} = Graph.bounds(graph)
    assert l > 36 && l < 37
    assert b > 93 && b < 94
  end

  test "finds the natural bounds of a circle" do
    graph = Graph.build() |> circle(50)
    {-50.0, -50.0, 50.0, 50.0} = Graph.bounds(graph)
  end

  test "component uses callback if set" do
    graph = Graph.build() |> ComponentBounds.add_to_graph({1, 2, 3, 4})
    assert Graph.bounds(graph) == {1, 2, 3, 4}
  end

  test "integrates Component callback" do
    graph =
      Graph.build()
      |> rect({100, 200}, t: {10, 10})
      |> ComponentBounds.add_to_graph({1, 2, 3, 4})

    assert Graph.bounds(graph) == {1, 2, 110, 210}
  end

  test "component bounds are nil no callback" do
    graph = Graph.build() |> ComponentNoBounds.add_to_graph({1, 2, 3, 4})
    assert Graph.bounds(graph) == nil
  end

  test "ignores nil Component callback" do
    graph =
      Graph.build()
      |> rect({100, 200})
      |> ComponentNoBounds.add_to_graph({1, 2, 3, 4})

    assert Graph.bounds(graph) == {0, 0, 100, 200}
  end

  test "finds the natural bounds of an ellipse" do
    graph = Graph.build() |> ellipse({50, 100})
    {-50.0, -100.0, 50.0, 100.0} = Graph.bounds(graph)
  end

  test "finds the natural bounds of things in a group" do
    graph =
      Graph.build()
      |> group(fn g ->
        g
        |> circle(50)
        |> rect({200, 10})
      end)

    {-50.0, -50.0, 200.0, 50.0} = Graph.bounds(graph)
  end

  test "finds the natural bounds of a line" do
    graph = Graph.build() |> line({{10, 20}, {30, 40}})
    assert Graph.bounds(graph) == {10, 20, 30, 40}
  end

  test "finds the natural bounds of a path - line to" do
    graph =
      Graph.build()
      |> path([
        {:move_to, 10, 20},
        {:line_to, 40, 3},
        {:line_to, 20, 30}
      ])

    {10.0, 3.0, 40.0, 30.0} = Graph.bounds(graph)
  end

  test "finds the natural bounds of a path - arc to" do
    graph =
      Graph.build()
      |> path([
        {:move_to, 10, 20},
        {:arc_to, 100, 20, 100, 30, 10}
      ])

    {10.0, 20.0, 100.0, 30.0} = Graph.bounds(graph)
  end

  test "finds the natural bounds of a path - bezier to" do
    graph =
      Graph.build()
      |> path([
        {:move_to, 10, 20},
        {:bezier_to, 80, 30, 40, 80, 100, 100}
      ])

    {10.0, 20.0, 100.0, 100.0} = Graph.bounds(graph)
  end

  test "finds the natural bounds of a path - quadratic to" do
    graph =
      Graph.build()
      |> path([
        {:move_to, 10, 20},
        {:quadratic_to, 80, 30, 100, 100}
      ])

    {10.0, 20.0, 100.0, 100.0} = Graph.bounds(graph)
  end

  test "finds the natural bounds of a quad" do
    graph = Graph.build() |> quad({{10, 20}, {30, 20}, {40, 60}, {-10, 20}})
    assert Graph.bounds(graph) == {-10.0, 20.0, 40.0, 60.0}
  end

  test "finds the natural bounds of a rect" do
    graph = Graph.build() |> rect({100, 200})
    assert Graph.bounds(graph) == {0, 0, 100, 200}
  end

  test "finds the natural bounds of a rrect" do
    graph = Graph.build() |> rrect({100, 200, 8})
    assert Graph.bounds(graph) == {0, 0, 100, 200}
  end

  test "finds the natural bounds of a sector" do
    graph = Graph.build() |> sector({100, 1.2})
    {0.0, 0.0, 100.0, b} = Graph.bounds(graph)
    assert b > 93 && b < 94
  end

  test "finds the natural bounds of a single sprite" do
    graph = Graph.build() |> sprites({:parrot, [{{0, 0}, {10, 10}, {10, 20}, {30, 15}}]})
    {10.0, 20.0, 40.0, 35.0} = Graph.bounds(graph)
  end

  test "finds the natural bounds of a set of sprites" do
    graph =
      Graph.build()
      |> sprites(
        {:parrot,
         [
           {{0, 0}, {10, 10}, {10, 20}, {30, 15}},
           {{0, 0}, {10, 10}, {40, -3}, {30, 15}}
         ]}
      )

    assert Graph.bounds(graph) == {10.0, -3.0, 70.0, 35.0}
  end

  test "finds the natural bounds of a single line of text" do
    graph =
      Graph.build(
        font: :roboto_mono,
        font_size: 20,
        text_align: :left,
        text_base: :top
      )
      |> text("This is a test")

    {0.0, 0.0, w, h} = Graph.bounds(graph)
    assert w > 168 && w < 169
    assert h > 26 && h < 27
  end

  test "finds the natural bounds of a multi-line text" do
    graph =
      Graph.build(
        font: :roboto_mono,
        font_size: 20,
        text_align: :left,
        text_base: :top,
        line_height: 1.2
      )
      |> text("This is a test\nMulti line")

    {0.0, 0.0, w, h} = Graph.bounds(graph)

    assert w > 168 && w < 169
    assert h > 58 && h < 59
  end

  test "finds the natural bounds of a triangle" do
    graph = Graph.build() |> triangle({{10, 20}, {20, 60}, {40, 40}})
    assert Graph.bounds(graph) == {10.0, 20.0, 40.0, 60.0}
  end
end
