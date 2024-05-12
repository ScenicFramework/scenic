#
#  Created by Boyd Multerer on 2021-02-04.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.ScriptTest do
  use ExUnit.Case, async: true
  doctest Scenic.Script

  alias Scenic.Script
  alias Scenic.Color

  # --------------------------------------------------------

  test "start returns an empty binary" do
    assert Script.start() == []
  end

  test "finish reverses the list" do
    assert Script.finish([2, 1]) == [1, 2]
  end

  test "finish optimizes the list" do
    assert Script.finish([2, :push_state, :pop_state, 1]) == [1, :pop_push_state, 2]
  end

  # --------------------------------------------------------
  # control commands
  test "push_state works" do
    expected = [:push_state]
    assert Script.push_state([]) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "pop_state works" do
    expected = [:pop_state]
    assert Script.pop_state([]) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "pop_push_state works" do
    expected = [:pop_push_state]
    assert Script.pop_push_state([]) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  # --------------------------------------------------------
  # draw primitives
  test "draw_line works" do
    expected = [draw_line: {0.0, 1.0, 2.0, 3.0, :stroke}]
    assert Script.draw_line([], 0, 1, 2, 3, :stroke) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "draw_line with :fill or :fill_stroke fails" do
    assert_raise FunctionClauseError, fn ->
      Script.draw_line([], 0, 1, 2, 3, :fill)
    end

    assert_raise FunctionClauseError, fn ->
      Script.draw_line([], 0, 1, 2, 3, :fill_stroke)
    end
  end

  test "draw_triangle works" do
    expected = [draw_triangle: {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, :fill}]
    assert Script.draw_triangle([], 0, 1, 2, 3, 4, 5, :fill) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.draw_triangle([], 0, 1, 2, 3, 4, 5, :stroke) ==
             [{:draw_triangle, {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, :stroke}}]

    assert Script.draw_triangle([], 0, 1, 2, 3, 4, 5, :fill_stroke) ==
             [{:draw_triangle, {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, :fill_stroke}}]
  end

  test "draw_quad works" do
    expected = [{:draw_quad, {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, :fill}}]
    assert Script.draw_quad([], 0, 1, 2, 3, 4, 5, 6, 7, :fill) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.draw_quad([], 0, 1, 2, 3, 4, 5, 6, 7, :stroke) ==
             [{:draw_quad, {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, :stroke}}]

    assert Script.draw_quad([], 0, 1, 2, 3, 4, 5, 6, 7, :fill_stroke) ==
             [{:draw_quad, {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, :fill_stroke}}]
  end

  test "draw_rectangle works" do
    expected = [{:draw_rect, {10.0, 11.0, :fill}}]
    assert Script.draw_rectangle([], 10, 11, :fill) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.draw_rectangle([], 10, 11, :stroke) ==
             [{:draw_rect, {10.0, 11.0, :stroke}}]

    assert Script.draw_rectangle([], 10, 11, :fill_stroke) ==
             [{:draw_rect, {10.0, 11.0, :fill_stroke}}]
  end

  test "draw_rounded_rectangle works" do
    expected = [{:draw_rrect, {10.0, 11.0, 3.0, :fill}}]
    assert Script.draw_rounded_rectangle([], 10, 11, 3, :fill) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.draw_rounded_rectangle([], 10, 11, 3, :stroke) ==
             [{:draw_rrect, {10.0, 11.0, 3.0, :stroke}}]

    assert Script.draw_rounded_rectangle([], 10, 11, 3, :fill_stroke) ==
             [{:draw_rrect, {10.0, 11.0, 3.0, :fill_stroke}}]
  end

  test "draw_rounded_rectangle shrinks radius if too big" do
    assert Script.draw_rounded_rectangle([], 10, 12, 30, :fill) ==
             [{:draw_rrect, {10.0, 12.0, 5.0, :fill}}]

    assert Script.draw_rounded_rectangle([], 13, 12, 30, :stroke) ==
             [{:draw_rrect, {13.0, 12.0, 6.0, :stroke}}]
  end

  test "draw_sector works" do
    expected = [{:draw_sector, {10.0, 3.0, :fill}}]
    assert Script.draw_sector([], 10, 3, :fill) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.draw_sector([], 10, 3, :stroke) ==
             [{:draw_sector, {10.0, 3.0, :stroke}}]

    assert Script.draw_sector([], 10, 3, :fill_stroke) ==
             [{:draw_sector, {10.0, 3.0, :fill_stroke}}]
  end

  test "draw_arc works" do
    expected = [{:draw_arc, {10.0, 3.0, :fill}}]
    assert Script.draw_arc([], 10, 3, :fill) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.draw_arc([], 10, 3, :stroke) ==
             [{:draw_arc, {10.0, 3.0, :stroke}}]

    assert Script.draw_arc([], 10, 3, :fill_stroke) ==
             [{:draw_arc, {10.0, 3.0, :fill_stroke}}]
  end

  test "draw_circle works" do
    expected = [{:draw_circle, {10.0, :fill}}]
    assert Script.draw_circle([], 10, :fill) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.draw_circle([], 10, :stroke) ==
             [{:draw_circle, {10.0, :stroke}}]

    assert Script.draw_circle([], 10, :fill_stroke) ==
             [{:draw_circle, {10.0, :fill_stroke}}]
  end

  test "draw_ellipse works" do
    expected = [{:draw_ellipse, {10.0, 20.0, :fill}}]
    assert Script.draw_ellipse([], 10, 20, :fill) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.draw_ellipse([], 10, 20, :stroke) ==
             [{:draw_ellipse, {10.0, 20.0, :stroke}}]

    assert Script.draw_ellipse([], 10, 20, :fill_stroke) ==
             [{:draw_ellipse, {10.0, 20.0, :fill_stroke}}]
  end

  test "draw_text works and pads correctly" do
    expected = [{:draw_text, "test"}]
    assert Script.draw_text([], "test") == expected
    io_data = Script.serialize(expected)
    bin = IO.iodata_to_binary(io_data)
    assert byte_size(bin) == 8
    assert Script.deserialize(bin) == expected

    bin =
      Script.draw_text([], "")
      |> Script.serialize()
      |> IO.iodata_to_binary()

    assert byte_size(bin) == 4
    assert Script.deserialize(bin) == [{:draw_text, ""}]

    bin =
      Script.draw_text([], "t")
      |> Script.serialize()
      |> IO.iodata_to_binary()

    assert byte_size(bin) == 8
    assert Script.deserialize(bin) == [{:draw_text, "t"}]

    bin =
      Script.draw_text([], "te")
      |> Script.serialize()
      |> IO.iodata_to_binary()

    assert byte_size(bin) == 8
    assert Script.deserialize(bin) == [{:draw_text, "te"}]

    bin =
      Script.draw_text([], "tes")
      |> Script.serialize()
      |> IO.iodata_to_binary()

    assert byte_size(bin) == 8
    assert Script.deserialize(bin) == [{:draw_text, "tes"}]

    bin =
      Script.draw_text([], "testt")
      |> Script.serialize()
      |> IO.iodata_to_binary()

    assert byte_size(bin) == 12
    assert Script.deserialize(bin) == [{:draw_text, "testt"}]

    bin =
      Script.draw_text([], "testtt")
      |> Script.serialize()
      |> IO.iodata_to_binary()

    assert byte_size(bin) == 12
    assert Script.deserialize(bin) == [{:draw_text, "testtt"}]

    bin =
      Script.draw_text([], "testttt")
      |> Script.serialize()
      |> IO.iodata_to_binary()

    assert byte_size(bin) == 12
    assert Script.deserialize(bin) == [{:draw_text, "testttt"}]
  end

  test "render_script works" do
    expected = [{:script, "script_id"}]
    assert Script.render_script([], "script_id") == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "draw_sprites works" do
    cmds = [{{10, 11}, {30, 40}, {2, 3}, {60, 70}, 1}]
    expected = [{:draw_sprites, {"VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns", cmds}}]
    assert Script.draw_sprites([], :parrot, cmds) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  # --------------------------------------------------------
  # path commands

  test "begin_path works" do
    expected = [:begin_path]
    assert Script.begin_path([]) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "close_path works" do
    expected = [:close_path]
    assert Script.close_path([]) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "fill_path works" do
    expected = [:fill_path]
    assert Script.fill_path([]) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "stroke_path works" do
    expected = [:stroke_path]
    assert Script.stroke_path([]) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "move_to works" do
    expected = [{:move_to, {10.0, 20.0}}]
    assert Script.move_to([], 10, 20) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "line_to works" do
    expected = [{:line_to, {10.0, 20.0}}]
    assert Script.line_to([], 10, 20) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "arc_to works" do
    expected = [{:arc_to, {1.0, 2.0, 3.0, 4.0, 5.0}}]
    assert Script.arc_to([], 1, 2, 3, 4, 5) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "bezier_to works" do
    expected = [{:bezier_to, {1.0, 2.0, 3.0, 4.0, 5.0, 6.0}}]
    assert Script.bezier_to([], 1, 2, 3, 4, 5, 6) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "quadratic_to works" do
    expected = [{:quadratic_to, {1.0, 2.0, 3.0, 4.0}}]
    assert Script.quadratic_to([], 1, 2, 3, 4) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "triangle works" do
    expected = [triangle: {0.0, 1.0, 2.0, 3.0, 4.0, 5.0}]
    assert Script.triangle([], 0, 1, 2, 3, 4, 5) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "quad works" do
    expected = [{:quad, {0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0}}]
    assert Script.quad([], 0, 1, 2, 3, 4, 5, 6, 7) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "rectangle works" do
    expected = [{:rect, {10.0, 11.0}}]
    assert Script.rectangle([], 10, 11) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "rounded_rectangle works" do
    expected = [{:rrect, {10.0, 11.0, 3.0}}]
    assert Script.rounded_rectangle([], 10, 11, 3) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "rounded_rectangle shrinks radius if too big" do
    assert Script.rounded_rectangle([], 10, 12, 30) ==
             [{:rrect, {10.0, 12.0, 5.0}}]

    assert Script.rounded_rectangle([], 13, 12, 30) ==
             [{:rrect, {13.0, 12.0, 6.0}}]
  end

  test "sector works" do
    expected = [{:sector, {10.0, 3.0}}]
    assert Script.sector([], 10, 3) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "circle works" do
    expected = [{:circle, 10.0}]
    assert Script.circle([], 10) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "ellipse works" do
    expected = [{:ellipse, {10.0, 20.0}}]
    assert Script.ellipse([], 10, 20) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "arc works" do
    expected = [{:arc, {0.0, 0.0, 5.0, 0.0, 6.0, 1}}]
    assert Script.arc([], 0, 0, 5, 0, 6, 1) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  # --------------------------------------------------------
  # transform commands

  test "scale works" do
    expected = [{:scale, {10.0, 20.0}}]
    assert Script.scale([], 10, 20) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "rotate works" do
    expected = [{:rotate, 10.0}]
    assert Script.rotate([], 10) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "translate works" do
    expected = [{:translate, {10.0, 20.0}}]
    assert Script.translate([], 10, 20) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "transform works" do
    expected = [{:transform, {1.0, 2.0, 3.0, 4.0, 5.0, 6.0}}]
    assert Script.transform([], 1, 2, 3, 4, 5, 6) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  # --------------------------------------------------------
  # fill styles

  test "fill_color works" do
    expected = [{:fill_color, Color.to_rgba(:red)}]
    assert Script.fill_color([], :red) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    expected = [{:fill_color, Color.to_rgba({0, 1, 2})}]
    assert Script.fill_color([], {0, 1, 2}) == expected

    expected = [{:fill_color, Color.to_rgba({0, 1, 2, 3})}]
    assert Script.fill_color([], {0, 1, 2, 3}) == expected
  end

  test "fill_linear works" do
    expected = [{:fill_linear, {1.0, 2.0, 3.0, 4.0, Color.to_rgba(:red), Color.to_rgba(:green)}}]
    assert Script.fill_linear([], 1, 2, 3, 4, :red, :green) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "fill_radial works" do
    expected = [{:fill_radial, {1.0, 2.0, 3.0, 4.0, Color.to_rgba(:red), Color.to_rgba(:green)}}]
    assert Script.fill_radial([], 1, 2, 3, 4, :red, :green) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "fill_image works with string image paths" do
    expected = [{:fill_image, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"}]
    assert Script.fill_image([], :parrot) == expected
    assert Script.serialize(expected) |> Script.deserialize() == expected
  end

  test "fill_image converts atom aliases into paths" do
    expected = [{:fill_image, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"}]
    assert Script.fill_image([], :parrot) == expected

    assert Script.serialize(expected) |> Script.deserialize() == expected
  end

  test "fill_stream works" do
    expected = [{:fill_stream, "test_tex"}]
    assert Script.fill_stream([], "test_tex") == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  # --------------------------------------------------------
  # stroke styles

  test "stroke_color works" do
    expected = [{:stroke_color, Color.to_rgba(:red)}]
    assert Script.stroke_color([], :red) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    expected = [{:stroke_color, Color.to_rgba({0, 1, 2})}]
    assert Script.stroke_color([], {0, 1, 2}) == expected

    expected = [{:stroke_color, Color.to_rgba({0, 1, 2, 3})}]
    assert Script.stroke_color([], {0, 1, 2, 3}) == expected
  end

  test "stroke_linear works" do
    expected = [
      {:stroke_linear, {1.0, 2.0, 3.0, 4.0, Color.to_rgba(:red), Color.to_rgba(:green)}}
    ]

    assert Script.stroke_linear([], 1, 2, 3, 4, :red, :green) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "stroke_radial works" do
    expected = [
      {:stroke_radial, {1.0, 2.0, 3.0, 4.0, Color.to_rgba(:red), Color.to_rgba(:green)}}
    ]

    assert Script.stroke_radial([], 1, 2, 3, 4, :red, :green) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "stroke_image works with string image keys" do
    expected = [{:stroke_image, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"}]
    assert Script.stroke_image([], :parrot) == expected

    assert Script.serialize(expected) |> Script.deserialize() == expected
  end

  test "stroke_image converts atom aliases into paths" do
    expected = [{:stroke_image, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"}]
    assert Script.stroke_image([], :parrot) == expected

    assert Script.serialize(expected) |> Script.deserialize() == expected
  end

  test "stroke_image works with paths" do
    expected = [{:stroke_image, "VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"}]
    assert Script.stroke_image([], :parrot) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "stroke_stream works" do
    expected = [{:stroke_stream, "test_tex"}]
    assert Script.stroke_stream([], "test_tex") == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "stroke_width works" do
    expected = [{:stroke_width, 4.5}]
    assert Script.stroke_width([], 4.5) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  # --------------------------------------------------------
  # line styles

  test "cap works - with all three params" do
    expected = [{:cap, :butt}]
    assert Script.cap([], :butt) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.cap([], :round) ==
             [{:cap, :round}]

    assert Script.cap([], :square) ==
             [{:cap, :square}]
  end

  test "join works - with all three params" do
    expected = [{:join, :bevel}]
    assert Script.join([], :bevel) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.join([], :round) ==
             [{:join, :round}]

    assert Script.join([], :miter) ==
             [{:join, :miter}]
  end

  test "miter_limit works" do
    expected = [{:miter_limit, 4}]
    assert Script.miter_limit([], 4) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "scissor works" do
    expected = [{:scissor, {4.0, 5.0}}]
    assert Script.scissor([], 4, 5) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  # --------------------------------------------------------
  # font/text styles

  test "font converts alias atoms to strings" do
    expected = [{:font, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"}]
    assert Script.font([], :roboto) == expected

    assert Script.serialize(expected) |> Script.deserialize() == expected
  end

  test "font works by path" do
    expected = [{:font, "85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"}]
    assert Script.font([], "fonts/roboto.ttf") == expected
    assert Script.serialize(expected) |> Script.deserialize() == expected
  end

  test "font_size works" do
    expected = [{:font_size, 12.5}]
    assert Script.font_size([], 12.5) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()
  end

  test "text_align works" do
    expected = [{:text_align, :left}]
    assert Script.text_align([], :left) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.text_align([], :center) ==
             [{:text_align, :center}]

    assert Script.text_align([], :right) ==
             [{:text_align, :right}]
  end

  test "text_base works" do
    expected = [{:text_base, :top}]
    assert Script.text_base([], :top) == expected
    assert expected == Script.serialize(expected) |> Script.deserialize()

    assert Script.text_base([], :middle) ==
             [{:text_base, :middle}]

    assert Script.text_base([], :alphabetic) ==
             [{:text_base, :alphabetic}]

    assert Script.text_base([], :bottom) ==
             [{:text_base, :bottom}]
  end

  # --------------------------------------------------------
  # media extraction into IDs

  test "media extractor finds fonts" do
    script =
      Script.start()
      |> Script.font("fonts/roboto.ttf")
      |> Script.font("fonts/roboto.ttf")
      |> Script.finish()

    assert Script.media(script) == %{
             fonts: ["85FMX5UxpxdyY8Vf7yilQ_3KKnUQxifa7Ejbll7DuyE"]
           }
  end

  test "media extractor finds images in fill_image" do
    script =
      Script.start()
      |> Script.fill_image(:parrot)
      |> Script.fill_image(:parrot)
      |> Script.finish()

    assert Script.media(script) == %{
             images: ["VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"]
           }
  end

  test "media extractor finds images in stroke_image" do
    script =
      Script.start()
      |> Script.stroke_image(:parrot)
      |> Script.stroke_image(:parrot)
      |> Script.finish()

    assert Script.media(script) == %{
             images: ["VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"]
           }
  end

  test "media extractor finds images in draw_sprites" do
    script =
      Script.start()
      |> Script.draw_sprites(:parrot, [])
      |> Script.draw_sprites(:parrot, [])
      |> Script.finish()

    assert Script.media(script) == %{
             images: ["VvWQFjblIwTGsvGx866t8MIG2czWyIc8by6Xc88AOns"]
           }
  end

  test "media extractor finds streams fill_stream" do
    script =
      Script.start()
      |> Script.fill_stream("test_stream")
      |> Script.fill_stream("test_stream")
      |> Script.finish()

    assert Script.media(script) == %{
             streams: ["test_stream"]
           }
  end

  test "media extractor finds streams stroke_stream" do
    script =
      Script.start()
      |> Script.stroke_stream("test_stream")
      |> Script.stroke_stream("test_stream")
      |> Script.finish()

    assert Script.media(script) == %{
             streams: ["test_stream"]
           }
  end

  # --------------------------------------------------------
  # serialization forms

  test "serialize works with a map like function - responds with binary" do
    script =
      Script.start()
      |> Script.rectangle(10, 20)
      |> Script.fill_stream("test_stream")
      |> Script.finish()

    # get the default io_list as a baseline
    normal = Script.serialize(script) |> List.flatten()
    [rect, _, "test_stream", <<0>>] = normal

    # to it again mapping the stream name to something else
    mapped =
      Script.serialize(script, fn
        {:fill_stream, _} -> <<1, 2, 3, 4>>
        other -> other
      end)

    [^rect, <<1, 2, 3, 4>>] = mapped
  end

  test "serialize works with a map like function - removes items with nil response" do
    script =
      Script.start()
      |> Script.rectangle(10, 20)
      |> Script.fill_stream("test_stream")
      |> Script.finish()

    # get the default io_list as a baseline
    normal = Script.serialize(script) |> List.flatten()
    [rect, _, "test_stream", <<0>>] = normal

    # to it again mapping the stream name to something else
    mapped =
      Script.serialize(script, fn
        {:fill_stream, _} -> nil
        other -> other
      end)

    [^rect, []] = mapped
  end

  test "serialize works with a map like function - default serializes mapped op" do
    script =
      Script.start()
      |> Script.rectangle(10, 20)
      |> Script.fill_stream("test_stream")
      |> Script.finish()

    # get the default io_list as a baseline
    normal = Script.serialize(script) |> List.flatten()
    [rect, _, "test_stream", <<0>>] = normal

    # to it again mapping the stream name to something else
    mapped =
      Script.serialize(script, fn
        {:fill_stream, _} -> {:rect, {10, 20}}
        other -> other
      end)

    [^rect, ^rect] = mapped
  end

  test "serialize works with a map like function - responds with io_list" do
    script =
      Script.start()
      |> Script.rectangle(10, 20)
      |> Script.fill_stream("test_stream")
      |> Script.finish()

    # get the default io_list as a baseline
    normal = Script.serialize(script) |> List.flatten()
    [rect, _, "test_stream", <<0>>] = normal

    # to it again mapping the stream name to something else
    mapped =
      Script.serialize(script, fn
        {:fill_stream, _} -> [<<1, 2>>, <<3, 4>>]
        other -> other
      end)

    [^rect, [<<1, 2>>, <<3, 4>>]] = mapped
  end

  test "serialize works with a map_reduce like function - responds with binary" do
    script =
      Script.start()
      |> Script.rectangle(10, 20)
      |> Script.fill_stream("test_stream")
      |> Script.finish()

    # get the default io_list as a baseline
    normal = Script.serialize(script) |> List.flatten()
    [rect, _, "test_stream", <<0>>] = normal

    # to it again mapping the stream name to something else
    {mapped, count} =
      Script.serialize(script, 0, fn
        {:fill_stream, _}, c -> {<<1, 2, 3, 4>>, c + 1}
        other, c -> {other, c + 1}
      end)

    [^rect, <<1, 2, 3, 4>>] = mapped
    assert count == 2
  end

  test "serialize works with a map_reduce like function - removes items with nil response" do
    script =
      Script.start()
      |> Script.rectangle(10, 20)
      |> Script.fill_stream("test_stream")
      |> Script.finish()

    # get the default io_list as a baseline
    normal = Script.serialize(script) |> List.flatten()
    [rect, _, "test_stream", <<0>>] = normal

    # to it again mapping the stream name to something else
    {mapped, count} =
      Script.serialize(script, 0, fn
        {:fill_stream, _}, c -> {nil, c}
        other, c -> {other, c + 1}
      end)

    [^rect, []] = mapped
    assert count == 1
  end

  test "serialize works with a map_reduce like function - default serializes mapped op" do
    script =
      Script.start()
      |> Script.rectangle(10, 20)
      |> Script.fill_stream("test_stream")
      |> Script.finish()

    # get the default io_list as a baseline
    normal = Script.serialize(script) |> List.flatten()
    [rect, _, "test_stream", <<0>>] = normal

    # to it again mapping the stream name to something else
    {mapped, count} =
      Script.serialize(script, 0, fn
        {:fill_stream, _}, c -> {{:rect, {10, 20}}, c + 1}
        other, c -> {other, c + 1}
      end)

    [^rect, ^rect] = mapped
    assert count == 2
  end

  test "serialize works with a map_reduce like function - responds with io_list" do
    script =
      Script.start()
      |> Script.rectangle(10, 20)
      |> Script.fill_stream("test_stream")
      |> Script.finish()

    # get the default io_list as a baseline
    normal = Script.serialize(script) |> List.flatten()
    [rect, _, "test_stream", <<0>>] = normal

    # to it again mapping the stream name to something else
    {mapped, count} =
      Script.serialize(script, 0, fn
        {:fill_stream, _}, c -> {[<<1, 2>>, <<3, 4>>], c + 1}
        other, c -> {other, c + 1}
      end)

    [^rect, [<<1, 2>>, <<3, 4>>]] = mapped
    assert count == 2
  end

  # --------------------------------------------------------
  # media extraction into hashes

  test "media extractor extracts into string hashes" do
    script =
      Script.start()
      |> Script.font("fonts/roboto.ttf")
      |> Script.fill_image(:parrot)
      |> Script.stroke_image(:parrot)
      |> Script.draw_sprites(:parrot, [])
      |> Script.fill_stream("test_stream")
      |> Script.stroke_stream("test_stream")
      |> Script.finish()

    {:ok, roboto_hash} = Scenic.Assets.Static.to_hash("fonts/roboto.ttf")
    {:ok, parrot_hash} = Scenic.Assets.Static.to_hash(:parrot)

    assert Script.media(script) == %{
             fonts: [roboto_hash],
             images: [parrot_hash],
             streams: ["test_stream"]
           }
  end
end
