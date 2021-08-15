#
#  Created by Boyd Multerer on 2021-02-07.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.ViewPort.GraphCompilerTest do
  use ExUnit.Case, async: true
  doctest Scenic.ViewPort.GraphCompiler

  alias Scenic.Graph
  alias Scenic.ViewPort.GraphCompiler

  # import IEx

  import Scenic.Primitives

  # ---------------------------------------------------------
  test "simple_styles graph works" do
    {:ok, list} =
      Graph.build()
      |> rect({200, 100}, fill: :blue)
      |> rrect({200, 100, 80}, fill: :blue, stroke: {4, :purple})
      |> GraphCompiler.compile()

    assert list == [
             {:fill_color, {:color_rgba, {0, 0, 255, 255}}},
             {:draw_rect, {200, 100, :fill}},
             {:stroke_width, 4},
             {:stroke_color, {:color_rgba, {128, 0, 128, 255}}},
             {:draw_rrect, {200, 100, 50.0, :fill_stroke}}
           ]
  end

  # ---------------------------------------------------------
  test "simple_text graph works" do
    {:ok, list} =
      Graph.build(font: :roboto, font_size: 27)
      |> text("blue", fill: :blue)
      |> text("blue_mono", font: :roboto_mono, fill: :blue)
      |> GraphCompiler.compile()

    assert list == [
             {:font, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"},
             {:font_size, 27},
             {:text_align, :left},
             {:text_base, :alphabetic},
             {:fill_color, {:color_rgba, {0, 0, 255, 255}}},
             {:draw_text, "blue"},
             {:font, "seffyKC7EpKVq50qdgz9W7Kk1oj4SPnnSIr66hYTPPA"},
             {:draw_text, "blue_mono"}
           ]
  end

  # ---------------------------------------------------------
  # line/stroke oriented styles compile
  test "line/stroke oriented styles compile" do
    {:ok, list} =
      Graph.build()
      |> rect({10, 20}, stroke: {1, :white}, miter_limit: 2)
      |> rect({10, 20}, stroke: {1, :white}, join: :round)
      |> line({{0, 0}, {10, 10}}, stroke: {1, :white}, cap: :round)
      |> GraphCompiler.compile()

    assert list == [
             {:stroke_width, 1},
             {:stroke_color, {:color_rgba, {255, 255, 255, 255}}},
             {:miter_limit, 2},
             {:draw_rect, {10, 20, :stroke}},
             {:join, :round},
             {:draw_rect, {10, 20, :stroke}},
             {:cap, :round},
             {:draw_line, {0, 0, 10, 10, :stroke}}
           ]
  end

  # ---------------------------------------------------------
  test "simple_theme graph works" do
    {:ok, list} =
      Graph.build(font: :roboto, font_size: 26, theme: :dark)
      |> text("theme")
      |> GraphCompiler.compile()

    assert list == [
             {:font, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"},
             {:font_size, 26},
             {:text_align, :left},
             {:text_base, :alphabetic},
             {:fill_color, {:color_rgba, {255, 255, 255, 255}}},
             {:draw_text, "theme"}
           ]
  end

  # ---------------------------------------------------------
  test "simple_transforms graph works" do
    {:ok, list} =
      Graph.build()
      |> rect({200, 100}, fill: :blue, t: {10, 20})
      |> rrect({200, 100, 80}, fill: :blue, t: {20, 30})
      |> GraphCompiler.compile()

    assert list == [
             :push_state,
             {:translate, {10, 20}},
             {:fill_color, {:color_rgba, {0, 0, 255, 255}}},
             {:draw_rect, {200, 100, :fill}},
             :pop_push_state,
             {:translate, {20, 30}},
             {:fill_color, {:color_rgba, {0, 0, 255, 255}}},
             {:draw_rrect, {200, 100, 50.0, :fill}},
             :pop_state
           ]
  end

  # ---------------------------------------------------------
  test "hidden shortcuts rendering" do
    {:ok, list} =
      Graph.build()
      |> rect({200, 100}, fill: :red)
      |> group(&text(&1, "This is a test", font_size: 64), hidden: true)
      |> rrect({200, 100, 80}, stroke: {4, :purple}, translate: {200, 30}, hidden: true)
      |> GraphCompiler.compile()

    assert list == [
             {:fill_color, {:color_rgba, {255, 0, 0, 255}}},
             {:draw_rect, {200.0, 100.0, :fill}}
           ]
  end

  # ---------------------------------------------------------
  # note that the repeated colors should only be rendered once
  test "primitives graph works" do
    {:ok, list} =
      Graph.build()
      |> circle(10, fill: :red)
      |> ellipse({10, 20}, fill: :red)
      |> line({{20, 160}, {200, 60}}, fill: :red)
      |> quad({{1, 2}, {3, 4}, {5, 6}, {7, 8}}, fill: :green)
      |> rect({1, 2}, fill: :green)
      |> rrect({10, 20, 3}, fill: :green)
      |> text("This is white text", fill: :white)
      |> triangle({{1, 2}, {3, 4}, {5, 6}}, fill: :green)
      |> GraphCompiler.compile()

    assert list == [
             {:fill_color, {:color_rgba, {255, 0, 0, 255}}},
             {:draw_circle, {10.0, :fill}},
             {:draw_ellipse, {10.0, 20.0, :fill}},
             {:fill_color, {:color_rgba, {0, 128, 0, 255}}},
             {:draw_quad, {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, :fill}},
             {:draw_rect, {1.0, 2.0, :fill}},
             {:draw_rrect, {10.0, 20.0, 3.0, :fill}},
             {:font, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"},
             {:font_size, 24.0},
             {:text_align, :left},
             {:text_base, :alphabetic},
             {:fill_color, {:color_rgba, {255, 255, 255, 255}}},
             {:draw_text, "This is white text"},
             {:fill_color, {:color_rgba, {0, 128, 0, 255}}},
             {:draw_triangle, {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, :fill}}
           ]
  end

  # ---------------------------------------------------------
  test "graph with path works" do
    {:ok, list} =
      Graph.build()
      |> path(
        [
          :begin,
          {:move_to, 0, 0},
          {:bezier_to, 0, 20, 0, 50, 40, 50},
          {:bezier_to, 60, 50, 60, 20, 80, 20},
          {:bezier_to, 100, 20, 110, 0, 120, 0},
          {:bezier_to, 140, 0, 160, 30, 160, 50}
        ],
        stroke: {2, :red}
      )
      |> GraphCompiler.compile()

    assert list == [
             {:stroke_width, 2},
             {:stroke_color, {:color_rgba, {255, 0, 0, 255}}},
             :begin_path,
             {:move_to, {0, 0}},
             {:bezier_to, {0, 20, 0, 50, 40, 50}},
             {:bezier_to, {60, 50, 60, 20, 80, 20}},
             {:bezier_to, {100, 20, 110, 0, 120, 0}},
             {:bezier_to, {140, 0, 160, 30, 160, 50}},
             :stroke_path
           ]
  end

  # ---------------------------------------------------------
  test "graph with sprites works" do
    cmds = [
      {{0, 1}, {10, 11}, {2, 3}, {12, 13}},
      {{2, 3}, {10, 11}, {4, 5}, {12, 13}}
    ]

    {:ok, list} =
      Graph.build()
      # |> sprites({{:test_assets, "images/parrot.png"}, cmds})
      |> sprites({:parrot, cmds})
      |> GraphCompiler.compile()

    assert list == [
             {:draw_sprites, {"VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns", cmds}}
           ]
  end

  # ---------------------------------------------------------
  # using cicles because the default pin is {0,0}, which is the same as no pin
  test "transform_origin graph works" do
    {:ok, list} =
      Graph.build(fill: :red)
      |> circle(8, scale: {7, 8})
      |> circle(8, rotate: 9)
      |> circle(8, translate: {11, 21})
      |> circle(8, scale: {7, 8}, rotate: 9)
      |> circle(8, scale: {7, 8}, translate: {11, 21})
      |> circle(8, rotate: 9, translate: {11, 21})
      |> circle(8, scale: {7, 8}, rotate: 9, translate: {11, 21})
      |> GraphCompiler.compile()

    assert [
             {:fill_color, {:color_rgba, {255, 0, 0, 255}}},
             :push_state,
             {:scale, {7, 8}},
             {:draw_circle, {8, :fill}},
             :pop_push_state,
             {:rotate, 9},
             {:draw_circle, {8, :fill}},
             :pop_push_state,
             {:translate, {11, 21}},
             {:draw_circle, {8, :fill}},
             :pop_push_state,
             {:rotate, 9},
             {:scale, {7, 8}},
             {:draw_circle, {8, :fill}},
             :pop_push_state,
             {:scale, {7, 8}},
             {:translate, {11, 21}},
             {:draw_circle, {8, :fill}},
             :pop_push_state,
             {:rotate, 9},
             {:translate, {11, 21}},
             {:draw_circle, {8, :fill}},
             :pop_push_state,
             {:transform, {_, _, _, _, _, _}},
             {:draw_circle, {8, :fill}},
             :pop_state
           ] = list
  end

  # ---------------------------------------------------------
  # Should correctly compile fill and stroke. Note that 
  # primitives with neither fill nor stroke are eliminated completely
  test "fill and stroke are compiled correctly" do
    {:ok, list} =
      Graph.build()
      |> circle(1, fill: :red)
      |> circle(2, fill: :purple)
      |> circle(3, stroke: {1, :green})
      |> circle(4, fill: :red, stroke: {1, :green})
      |> circle(5, scale: {7, 8}, rotate: 9)
      |> circle(6, scale: {7, 8}, translate: {11, 21})
      |> circle(7, rotate: 9, translate: {11, 21})
      |> circle(8, scale: {7, 8}, rotate: 9, translate: {11, 21})
      |> GraphCompiler.compile()

    assert list == [
             {:fill_color, {:color_rgba, {255, 0, 0, 255}}},
             {:draw_circle, {1, :fill}},
             {:fill_color, {:color_rgba, {128, 0, 128, 255}}},
             {:draw_circle, {2, :fill}},
             {:stroke_width, 1},
             {:stroke_color, {:color_rgba, {0, 128, 0, 255}}},
             {:draw_circle, {3, :stroke}},
             {:fill_color, {:color_rgba, {255, 0, 0, 255}}},
             {:draw_circle, {4, :fill_stroke}}
           ]
  end

  # ---------------------------------------------------------
  # rect has a non-zero default pin
  test "pinned transforms graph works" do
    {:ok, list} =
      Graph.build(fill: :yellow, stroke: {3, :purple})
      |> rect({10, 20}, scale: {7, 8}, translate: {10, 20})
      |> circle(10, scale: {7, 8}, translate: {10, 20}, pin: {10, 10})
      |> rect({10, 20}, rotate: 9, translate: {10, 20})
      |> circle(10, rotate: 9, translate: {10, 20}, pin: {10, 10})
      |> rect({10, 20}, rotate: 10, scale: {7, 8}, translate: {10, 20})
      |> circle(10, rotate: 10, scale: {7, 8}, translate: {10, 20})
      |> circle(10, rotate: 10, scale: {7, 8}, translate: {10, 20}, pin: {10, 10})
      |> GraphCompiler.compile()

    assert [
             {:fill_color, {:color_rgba, {255, 255, 0, 255}}},
             :push_state,
             {:transform, {7.0, 0.0, 0.0, 8.0, -20.0, -50.0}},
             {:stroke_width, 3},
             {:stroke_color, {:color_rgba, {128, 0, 128, 255}}},
             {:draw_rect, {10, 20, :fill_stroke}},
             :pop_push_state,
             {:transform, {7.0, 0.0, 0.0, 8.0, -50.0, -50.0}},
             {:stroke_width, 3},
             {:stroke_color, {:color_rgba, {128, 0, 128, 255}}},
             {:draw_circle, {10, :fill_stroke}},
             :pop_push_state,
             {:transform, {_, _, _, _, _, _}},
             {:stroke_width, 3},
             {:stroke_color, {:color_rgba, {128, 0, 128, 255}}},
             {:draw_rect, {10, 20, :fill_stroke}},
             :pop_push_state,
             {:transform, {_, _, _, _, _, _}},
             {:stroke_width, 3},
             {:stroke_color, {:color_rgba, {128, 0, 128, 255}}},
             {:draw_circle, {10, :fill_stroke}},
             :pop_push_state,
             {:transform, {_, _, _, _, _, _}},
             {:stroke_width, 3},
             {:stroke_color, {:color_rgba, {128, 0, 128, 255}}},
             {:draw_rect, {10, 20, :fill_stroke}},
             :pop_push_state,
             {:transform, {_, _, _, _, _, _}},
             {:stroke_width, 3},
             {:stroke_color, {:color_rgba, {128, 0, 128, 255}}},
             {:draw_circle, {10, :fill_stroke}},
             :pop_push_state,
             {:transform, {_, _, _, _, _, _}},
             {:stroke_width, 3},
             {:stroke_color, {:color_rgba, {128, 0, 128, 255}}},
             {:draw_circle, {10, :fill_stroke}},
             :pop_state
           ] = list
  end

  # ---------------------------------------------------------
  test "line_styles graph works" do
    {:ok, list} =
      Graph.build(stroke: {2, :green})
      |> line({{1, 2}, {10, 20}}, cap: :butt)
      |> line({{1, 2}, {10, 20}}, cap: :round)
      |> line({{1, 2}, {10, 20}}, cap: :square)
      |> GraphCompiler.compile()

    assert list == [
             {:stroke_width, 2},
             {:stroke_color, {:color_rgba, {0, 128, 0, 255}}},
             {:cap, :butt},
             {:draw_line, {1.0, 2.0, 10.0, 20.0, :stroke}},
             {:cap, :round},
             {:draw_line, {1.0, 2.0, 10.0, 20.0, :stroke}},
             {:cap, :square},
             {:draw_line, {1.0, 2.0, 10.0, 20.0, :stroke}}
           ]
  end

  # ---------------------------------------------------------

  test "join_styles graph works" do
    {:ok, list} =
      Graph.build(stroke: {1, :green})
      |> rect({10, 20}, join: :bevel)
      |> rect({10, 20}, join: :round, fill: :orange)
      |> rect({10, 20}, join: :miter)
      |> GraphCompiler.compile()

    assert list == [
             {:stroke_width, 1},
             {:stroke_color, {:color_rgba, {0, 128, 0, 255}}},
             {:join, :bevel},
             {:draw_rect, {10.0, 20.0, :stroke}},
             {:fill_color, {:color_rgba, {255, 165, 0, 255}}},
             {:join, :round},
             {:draw_rect, {10.0, 20.0, :fill_stroke}},
             {:join, :miter},
             {:draw_rect, {10.0, 20.0, :stroke}}
           ]
  end

  # ---------------------------------------------------------
  test "font_styles graph works" do
    {:ok, list} =
      Graph.build(theme: :dark)
      |> text("roboto", font: :roboto)
      |> text("size_64", font_size: 64)
      |> text("left", text_align: :left)
      |> text("center", text_align: :center)
      |> text("right", text_align: :right)
      |> text("top", text_base: :top)
      |> text("middle", text_base: :middle)
      |> text("alphabetic", text_base: :alphabetic)
      |> text("bottom", text_base: :bottom, fill: :yellow)
      |> GraphCompiler.compile()

    assert list == [
             {:font, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"},
             {:font_size, 24},
             {:text_align, :left},
             {:text_base, :alphabetic},
             {:fill_color, {:color_rgba, {255, 255, 255, 255}}},
             {:draw_text, "roboto"},
             {:font_size, 64},
             {:draw_text, "size_64"},
             {:font_size, 24},
             {:draw_text, "left"},
             {:text_align, :center},
             {:draw_text, "center"},
             {:text_align, :right},
             {:draw_text, "right"},
             {:text_align, :left},
             {:text_base, :top},
             {:draw_text, "top"},
             {:text_base, :middle},
             {:draw_text, "middle"},
             {:text_base, :alphabetic},
             {:draw_text, "alphabetic"},
             {:text_base, :bottom},
             {:fill_color, {:color_rgba, {255, 255, 0, 255}}},
             {:draw_text, "bottom"}
           ]
  end

  # ---------------------------------------------------------
  test "fuchsia_text graph shows text in fuchsia" do
    {:ok, list} =
      Graph.build()
      |> text("test")
      |> GraphCompiler.compile()

    assert list == [
             font: "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE",
             font_size: 24.0,
             text_align: :left,
             text_base: :alphabetic,
             fill_color: Scenic.Color.to_rgba(:fuchsia),
             draw_text: "test"
           ]
  end

  # ---------------------------------------------------------
  test "fill_colors graph works" do
    {:ok, list} =
      Graph.build()
      |> circle(10, fill: :red)
      |> circle(10, fill: {:color, :red})
      |> circle(10, fill: {:color, {0, 1, 2}})
      |> circle(10, fill: {:color, {0, 1, 2, 3}})
      |> GraphCompiler.compile()

    assert list == [
             {:fill_color, {:color_rgba, {255, 0, 0, 255}}},
             {:draw_circle, {10.0, :fill}},
             {:draw_circle, {10.0, :fill}},
             {:fill_color, {:color_rgba, {0, 1, 2, 255}}},
             {:draw_circle, {10.0, :fill}},
             {:fill_color, {:color_rgba, {0, 1, 2, 3}}},
             {:draw_circle, {10.0, :fill}}
           ]
  end

  # ---------------------------------------------------------
  test "fill_gradients graph works" do
    {:ok, list} =
      Graph.build()
      |> rect({100, 200}, fill: {:linear, {1, 2, 3, 4, :red, :green}})
      |> rect({100, 200}, fill: {:radial, {10, 20, 1, 2, :blue, :purple}})
      |> GraphCompiler.compile()

    assert list == [
             {:fill_linear,
              {1.0, 2.0, 3.0, 4.0, {:color_rgba, {255, 0, 0, 255}},
               {:color_rgba, {0, 128, 0, 255}}}},
             {:draw_rect, {100.0, 200.0, :fill}},
             {:fill_radial,
              {10.0, 20.0, 1.0, 2.0, {:color_rgba, {0, 0, 255, 255}},
               {:color_rgba, {128, 0, 128, 255}}}},
             {:draw_rect, {100.0, 200.0, :fill}}
           ]
  end

  # ---------------------------------------------------------
  test "fill_images works" do
    {:ok, list} =
      Graph.build()
      |> rect({100, 200}, fill: {:image, :parrot})
      |> rect({100, 200}, stroke: {4, {:image, :parrot}})
      |> GraphCompiler.compile()

    assert list == [
             {:fill_image, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"},
             {:draw_rect, {100.0, 200.0, :fill}},
             {:stroke_width, 4},
             {:stroke_image, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"},
             {:draw_rect, {100.0, 200.0, :stroke}}
           ]
  end

  # ---------------------------------------------------------
  test "fill_streams graph works" do
    {:ok, list} =
      Graph.build()
      |> rect({100, 200}, fill: {:stream, "some_stream_name"})
      |> rect({100, 200}, stroke: {4, {:stream, "some_stream_name"}})
      |> GraphCompiler.compile()

    assert list == [
             {:fill_stream, "some_stream_name"},
             {:draw_rect, {100.0, 200.0, :fill}},
             {:stroke_width, 4},
             {:stroke_stream, "some_stream_name"},
             {:draw_rect, {100.0, 200.0, :stroke}}
           ]
  end

  # ---------------------------------------------------------
  test "stroke graph works" do
    {:ok, list} =
      Graph.build()
      |> line({{1, 2}, {10, 20}}, stroke: {2.5, :yellow})
      |> line({{1, 2}, {10, 20}}, stroke: {2.5, :green})
      |> line({{1, 2}, {10, 20}}, stroke: {6, :green})
      |> line({{1, 2}, {10, 20}}, stroke: {6, {:color, :green}})
      |> line({{1, 2}, {10, 20}}, stroke: {6, {:color, {0, 1, 2}}})
      |> line({{1, 2}, {10, 20}}, stroke: {5, {:color, {0, 1, 2, 3}}})
      |> GraphCompiler.compile()

    assert list == [
             {:stroke_width, 2.5},
             {:stroke_color, {:color_rgba, {255, 255, 0, 255}}},
             {:draw_line, {1, 2, 10, 20, :stroke}},
             {:stroke_color, {:color_rgba, {0, 128, 0, 255}}},
             {:draw_line, {1, 2, 10, 20, :stroke}},
             {:stroke_width, 6},
             {:draw_line, {1, 2, 10, 20, :stroke}},
             {:draw_line, {1, 2, 10, 20, :stroke}},
             {:stroke_color, {:color_rgba, {0, 1, 2, 255}}},
             {:draw_line, {1, 2, 10, 20, :stroke}},
             {:stroke_width, 5},
             {:stroke_color, {:color_rgba, {0, 1, 2, 3}}},
             {:draw_line, {1, 2, 10, 20, :stroke}}
           ]
  end

  # ---------------------------------------------------------
  test "stroke_gradients graph works" do
    {:ok, list} =
      Graph.build()
      |> rect({100, 200}, stroke: {1, {:linear, {1, 2, 3, 4, :red, :green}}})
      |> rect({100, 200}, stroke: {2, {:radial, {10, 20, 1, 2, :blue, :purple}}})
      |> rect({100, 200}, stroke: {7, {:linear, {1, 2, 3, 4, :red, :green}}})
      |> rect({100, 200}, stroke: {7, {:radial, {10, 20, 1, 2, :blue, :purple}}})
      |> GraphCompiler.compile()

    assert list == [
             {:stroke_width, 1},
             {:stroke_linear,
              {1, 2, 3, 4, {:color_rgba, {255, 0, 0, 255}}, {:color_rgba, {0, 128, 0, 255}}}},
             {:draw_rect, {100, 200, :stroke}},
             {:stroke_width, 2},
             {:stroke_radial,
              {10, 20, 1, 2, {:color_rgba, {0, 0, 255, 255}}, {:color_rgba, {128, 0, 128, 255}}}},
             {:draw_rect, {100, 200, :stroke}},
             {:stroke_width, 7},
             {:stroke_linear,
              {1, 2, 3, 4, {:color_rgba, {255, 0, 0, 255}}, {:color_rgba, {0, 128, 0, 255}}}},
             {:draw_rect, {100, 200, :stroke}},
             {:stroke_radial,
              {10, 20, 1, 2, {:color_rgba, {0, 0, 255, 255}}, {:color_rgba, {128, 0, 128, 255}}}},
             {:draw_rect, {100, 200, :stroke}}
           ]
  end

  # ---------------------------------------------------------
  test "min_font_size only renders the used font/size" do
    {:ok, list} =
      Graph.build(font: :roboto_mono, font_size: 25)
      |> text("text", font: :roboto, font_size: 32)
      |> GraphCompiler.compile()

    assert list == [
             font: "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE",
             font_size: 32,
             text_align: :left,
             text_base: :alphabetic,
             fill_color: {:color_rgba, {255, 0, 255, 255}},
             draw_text: "text"
           ]
  end

  # ---------------------------------------------------------

  test "root_font_size uses the root settings" do
    {:ok, list} =
      Graph.build(font: :roboto, font_size: 25)
      |> text("text")
      |> GraphCompiler.compile()

    assert list == [
             font: "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE",
             font_size: 25,
             text_align: :left,
             text_base: :alphabetic,
             fill_color: {:color_rgba, {255, 0, 255, 255}},
             draw_text: "text"
           ]
  end

  # ---------------------------------------------------------
  test "group_font_size inherits from the group" do
    {:ok, list} =
      Graph.build()
      |> group(&text(&1, "text"), font: :roboto, font_size: 64)
      |> GraphCompiler.compile()

    assert list == [
             font: "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE",
             font_size: 64,
             text_align: :left,
             text_base: :alphabetic,
             fill_color: {:color_rgba, {255, 0, 255, 255}},
             draw_text: "text"
           ]
  end

  # ---------------------------------------------------------
  test "complex_font_size works" do
    {:ok, list} =
      Graph.build(font: :roboto)
      |> text("text", font: :roboto, font_size: 50)
      |> text("text", font: :roboto, font_size: 40)
      |> text("text")
      |> GraphCompiler.compile()

    assert list == [
             {:font, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"},
             {:font_size, 50},
             {:text_align, :left},
             {:text_base, :alphabetic},
             {:fill_color, {:color_rgba, {255, 0, 255, 255}}},
             {:draw_text, "text"},
             {:font_size, 40},
             {:fill_color, {:color_rgba, {255, 0, 255, 255}}},
             {:draw_text, "text"},
             {:font_size, 24},
             {:fill_color, {:color_rgba, {255, 0, 255, 255}}},
             {:draw_text, "text"}
           ]
  end

  test "text_from_spec works" do
    text_spec = [
      text_spec("Hello", font: :roboto, font_size: 50),
      text_spec("World", font: :roboto_mono)
    ]

    {:ok, list} =
      Graph.build(font: :roboto, font_size: 24)
      |> add_specs_to_graph([group_spec(text_spec, font_size: 40)])
      |> GraphCompiler.compile()

    assert list == [
             {:font, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"},
             {:font_size, 50},
             {:text_align, :left},
             {:text_base, :alphabetic},
             {:fill_color, {:color_rgba, {255, 0, 255, 255}}},
             {:draw_text, "Hello"},
             {:font, "seffyKC7EpKVq50qdgz9W7Kk1oj4SPnnSIr66hYTPPA"},
             {:font_size, 40},
             {:fill_color, {:color_rgba, {255, 0, 255, 255}}},
             {:draw_text, "World"}
           ]
  end
end
