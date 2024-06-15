#
#  Created by Boyd Multerer on 2021-02-03.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Script do
  @moduledoc """

  ## Overview

  Scenic.Script is the fundamental "rendering" data structure for Scenic.

  Prior to v0.11, drivers received Graphs from the ViewPort and were responsible
  for transforming them into a list of drawing commands that would ultimately draw
  the actual picture that is displayed as the Scenic UI.

  After some experience, it became apparent that this was a common task for almost
  all drivers and has been moved into the ViewPort and formalized in Scenic.Script.

  Simply put, Scenic.Script produces a list of static drawing commands that are
  sent, unmodified, to the drivers through the ViewPort. These scripts are
  generated for you when you use `Scenic.Scene.push_graph/3`, or you can create
  them yourself by using this api.

  If you use Scenic.Script directly, you can create more complicated and/or
  reusable graphics than you could by using Graphs alone.

  ## Update Isolation

  Another way to use scripts is to separate large static bits of a graph from
  that which changes frequently. When a graph is pushed to the ViewPort, the
  entire thing is compiled into a script, which is sent as a whole to the Drivers.

  However if that graph references a script, only the reference to the script is
  sent, not the contents of the script. This means you can modify the graph
  frequently without sending the contents of the scripts.

  The opposite is also true. You can generate and push the scripts frequently
  without causing the graphs that reference them to be recompiled or resent.

  An example of this might be a graph that implements a chart of some sort. The
  contents of the chart could be a script that is updated as new data comes in
  without needing all the chrome around it to be recompiled or sent for every
  update.

  ## API Patterns

  This is a large module with many functions. Most of them are very small, however and simply
  add individual commands to the script.

  The general pattern is that you start by calling Scenic.Script.start(). This simply returns
  an empty list. Each drawing api adds an element to the head of the list. Then you end with
  Scenic.Script.finsh(), which reverses the list and performs some optimizations on it.

  ```elixir
  alias Scenic.Script

  my_script =
    Script.start()
    |> Script.text( "A very simple script" )
    |> Script.finish()
  ```

  After the script is generated, you publish it to the ViewPort through either your
  scene's helper api `Scenic.Scene.push_script/4` or directly throught the ViewPort api
  `Scenic.ViewPort.put_script/4`

  Finally, to get the script to draw, you need to reference it from a graph.

  ```elixir
  my_graph =
    Graph.build()
      |> script( "my_script_name" )
  ```

  It doesn't matter if you push the script before or after you push the graph that references it.

  ```elixir
  scene =
    scene
    |> push_script( my_script, "my_script_name" )
    |> push_graph( my_graph )
  ```

  ## Example: the Checkbox check mark

  The canonical example is the checkmark symbol used in the `Checkbox` component.
  This is two lines, with rounded endpoints and rounded joint between them.
  It could be described using a Path primitive, but there is no need to
  send its instructions every time it is shown or hidden since its shape
  doesn't actually change.

  The Checkbox component creates and publishes this script using something very
  similar to the following example.

  ```elixir
  alias Scenic.Script

  # build the checkmark script
  chx_script =
    Script.start()
    |> Script.push_state()
    |> Script.join(:round)
    |> Script.stroke_width(@border_width + 1)
    |> Script.stroke_color(theme.thumb)
    |> Script.begin_path()
    |> Script.move_to(0, 8)
    |> Script.line_to(5, 13)
    |> Script.line_to(12, 1)
    |> Script.stroke_path()
    |> Script.pop_state()
    |> Script.finish()

  chx_id = scene.id <> "_chk"
  scene = push_script(scene, chx_script, chx_id)
  ```

  Building and using a custom script happens in three parts. First, the script itself
  is created using the `Scenic.Script` api.

  Then the script is published to the ViewPort using `Scenic.Scene.push_script/4` with a
  unique name.

  Later, the graph for the checkbox references this script, which is what triggers it to be drawn.

  ```elixir
  graph =
    Graph.build()
      |> script(chx_id, id: :chx, hidden: !checked?)
  ```

  ## Script State

  The underlying rendering engine that consumes these scripts and draws the actual
  pictures maintains a set of current drawing state, which can be pushed and popped
  from a stack via the `push_state/1`, `pop_state/1`, and `pop_push_state/1` apis.

  These functions are analogous to the state
  [save/restore APIs in Canvas](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/save).

  ## Transforms

  Transforms are applied to the running script by multiplying matrices together. This is very
  similar to how games position elements of UI. It takes a little getting used to, but is
  very powerful.

  If you want to unroll the most recent applied transform, you should push then pop the state
  to get back to the previous transform stack.

  ## Binary Format

  The `serialize/3` and `deserialize/1` go back and forth from the list format to a binary
  representation of the script. The `serialize/3` function produces an IO list, and `deserialize`
  goes back into a list of instructions.

  There is a standard format to the binary, but that needs to be independently documented. You
  can dig into the code behind `serialize/3` to see it in action.

  Drivers, which normally do the serialization call, can intercept/override any command if they
  need something specific.
  """

  # mostly used by the @specs
  alias Scenic.Color
  alias Scenic.Assets.Static
  alias Scenic.Assets.Stream
  alias Scenic.Primitive.Sprites

  # import IEx

  # ============================================================================
  # constants

  @finished 0x00

  @op_draw_line 0x01
  @op_draw_triangle 0x02
  @op_draw_quad 0x03
  @op_draw_rect 0x04
  @op_draw_rrect 0x05
  @op_draw_arc 0x06
  @op_draw_sector 0x07
  @op_draw_circle 0x08
  @op_draw_ellipse 0x09
  @op_draw_text 0x0A
  @op_draw_sprites 0x0B
  @op_draw_rrectv 0x0C
  @op_draw_script 0x0F

  @op_begin_path 0x20
  @op_close_path 0x21
  @op_fill_path 0x22
  @op_stroke_path 0x23
  @op_move_to 0x26
  @op_line_to 0x27
  @op_arc_to 0x28
  @op_bezier_to 0x29
  @op_quadratic_to 0x2A
  @op_triangle 0x2B
  @op_quad 0x2C
  @op_rect 0x2D
  @op_rrect 0x2E
  @op_sector 0x2F
  @op_circle 0x30
  @op_ellipse 0x31
  @op_arc 0x32

  @op_push_state 0x40
  @op_pop_state 0x41
  @op_pop_push_state 0x42
  @op_scissor 0x44

  @op_transform 0x50
  @op_scale 0x51
  @op_rotate 0x52
  @op_translate 0x53

  @op_fill_color 0x60
  @op_fill_linear 0x61
  @op_fill_radial 0x62
  @op_fill_image 0x63
  @op_fill_stream 0x64

  @op_stroke_width 0x70
  @op_stroke_color 0x71
  @op_stroke_linear 0x72
  @op_stroke_radial 0x73
  @op_stroke_image 0x74
  @op_stroke_stream 0x75

  @op_cap 0x80
  @op_join 0x81
  @op_miter_limit 0x82

  @op_font 0x90
  @op_font_size 0x91
  @op_text_align 0x92
  @op_text_base 0x93

  # parameters
  @line_butt 0x00
  @line_round 0x01
  @line_square 0x02

  @join_bevel 0x00
  @join_round 0x01
  @join_miter 0x02

  @align_left 0x00
  @align_center 0x01
  @align_right 0x02

  @baseline_top 0x00
  @baseline_middle 0x01
  @baseline_alphabetic 0x02
  @baseline_bottom 0x03

  @flag_fill 0x01
  @flag_stroke 0x02
  @flag_fill_stroke 0x03

  @type fill_stroke :: :fill | :stroke | :fill_stroke

  @type id :: atom | String.t() | reference | pid

  @type script_op ::
          :push_state
          | :pop_state
          | :pop_push_state
          | {:clear, color :: Color.t()}
          | {:draw_line, {x0 :: number, y0 :: number, x1 :: number, y1 :: number, :stroke}}
          | {:draw_quad,
             {x0 :: number, y0 :: number, x1 :: number, y1 :: number, x2 :: number, y2 :: number,
              x3 :: number, y3 :: number, fill_stroke()}}
          | {:draw_rect, {width :: number, height :: number, fill_stroke()}}
          | {:draw_rrect, {width :: number, height :: number, radius :: number, fill_stroke()}}
          | {:draw_rrectv,
             {width :: number, height :: number, upperLeftRadius :: number,
              upperRightRadius :: number, lowerRightRadius :: number, lowerLeftRadius :: number,
              fill_stroke()}}
          | {:draw_sector, {radius :: number, radians :: number, fill_stroke()}}
          | {:draw_arc, {radius :: number, radians :: number, fill_stroke()}}
          | {:draw_circle, {radius :: number, fill_stroke()}}
          | {:draw_ellipse, {radius0 :: number, radius1 :: number, fill_stroke()}}
          | {:draw_sprites, {src_id :: Static.id(), cmds :: Sprites.draw_cmds()}}
          | {:draw_text, utf8_string :: String.t()}
          | {:draw_triangle,
             {x0 :: number, y0 :: number, x1 :: number, y1 :: number, x2 :: number, y2 :: number,
              fill_stroke()}}
          | {:script, id :: pos_integer}
          | :begin_path
          | :close_path
          | :fill_path
          | :stroke_path
          | {:move_to, {x :: number, y :: number}}
          | {:line_to, {x :: number, y :: number}}
          | {:arc_to, {x1 :: number, y1 :: number, x2 :: number, y2 :: number, radius :: number}}
          | {:bezier_to,
             {cp1x :: number, cp1y :: number, cp2x :: number, cp2y :: number, x :: number,
              y :: number}}
          | {:quadratic_to, {cpx :: number, cpy :: number, x :: number, y :: number}}
          | {:quad,
             {x0 :: number, y0 :: number, x1 :: number, y1 :: number, x2 :: number, y2 :: number,
              x3 :: number, y3 :: number}}
          | {:rect, {width :: number, height :: number}}
          | {:rrect, {width :: number, height :: number, radius :: number}}
          | {:sector, {radius :: number, radians :: number}}
          | {:circle, {radius :: number}}
          | {:ellipse, {radius0 :: number, radius1 :: number}}
          | {:triangle,
             {x0 :: number, y0 :: number, x1 :: number, y1 :: number, x2 :: number, y2 :: number}}
          | {:scale, {x :: number, y :: number}}
          | {:rotate, radians :: number}
          | {:translate, {x :: number, y :: number}}
          | {:transform,
             {a :: number, b :: number, c :: number, d :: number, e :: number, f :: number}}
          | {:fill_color, color :: Color.t()}
          | {:fill_linear,
             {start_x :: number, start_y :: number, end_x :: number, end_y :: number,
              color_start :: Color.t(), color_end :: Color.t()}}
          | {:fill_radial,
             {center_x :: number, center_y :: number, inner_radius :: number,
              outer_radius :: number, color_start :: Color.t(), color_end :: Color.t()}}
          | {:fill_image, image :: Static.id()}
          | {:fill_stream, id :: Stream.id()}
          | {:stroke_color, color :: Color.t()}
          | {:stroke_linear,
             {start_x :: number, start_y :: number, end_x :: number, end_y :: number,
              color_start :: Color.t(), color_end :: Color.t()}}
          | {:stroke_radial,
             {center_x :: number, center_y :: number, inner_radius :: number,
              outer_radius :: number, color_start :: Color.t(), color_end :: Color.t()}}
          | {:stroke_image, image :: Static.id()}
          | {:stroke_stream, id :: Stream.id()}
          | {:stroke_width, width :: number}
          | {:cap, :butt}
          | {:cap, :round}
          | {:cap, :square}
          | {:join, :bevel}
          | {:join, :round}
          | {:join, :miter}
          | {:miter_limit, limit :: number}
          | {:scissor, {width :: number, height :: number}}
          | {:font, id :: Static.id()}
          | {:font_size, size :: number}
          | {:text_align, :left}
          | {:text_align, :center}
          | {:text_align, :right}
          | {:text_base, :top}
          | {:text_base, :middle}
          | {:text_base, :alphabetic}
          | {:text_base, :bottom}

  # @type operation :: {op :: atom, data :: any}
  @type t :: [script_op]

  @doc """
  draw_flag is a helper function to choose the appropriate fill and/or stroke flag
  given a map of styles.
  """
  @spec draw_flag(styles :: map) :: :fill_stroke | :fill | :stroke | nil
  def draw_flag(%{fill: _, stroke_fill: _}), do: :fill_stroke
  def draw_flag(%{fill: _}), do: :fill
  def draw_flag(%{stroke_fill: _}), do: :stroke
  def draw_flag(_), do: nil

  # ============================================================================
  # The virtual api

  @doc """
  Create a new Script.
  """
  @spec start() :: ops :: t()
  def start(), do: []

  @doc """
  Finish a script, preparing it to be sent to the ViewPort.

  This function cleans up the script, which should have been created by first
  calling `start/0` then and series of calls to Scenic.Script functions that add
  commands to the script.

  `finish/1` cleans up the script, reverses it, and runs an optimization pass.

  The resulting script is ready to be stored in the ViewPort.
  """
  @spec finish(ops :: t()) :: final_script :: t()
  def finish(ops) when is_list(ops) do
    ops
    |> List.flatten()
    |> optimize()
  end

  # control commands
  @doc """
  Saves the current style/transform state of the script as it is running.

  This function saves the current style and transform states in a stack of
  states. The idea is that you can make changes, then "pop" back to where
  the state was before.

  `push_state/1` must be paired with an eventual `pop_state/1` or `pop_push_state/1`
  """
  @spec push_state(ops :: t()) :: ops :: t()
  def push_state(ops), do: [:push_state | ops]

  @doc """
  Reverts the style/transform state of the script to the most recently pushed state.

  This function restores the style and transform states from a stack of
  states. The idea is that you can make changes, then "pop" back to where
  the state was before.

  `push_state/1` must be preceded with either `push_state/1` or `pop_push_state/1`
  """
  @spec pop_state(ops :: t()) :: ops :: t()
  def pop_state(ops), do: [:pop_state | ops]

  @doc """
  Reverts the style/transform state of the script then immediately pushes it again.

  `pop_push_state/1` is for when you have made changes that you want to revert, but then
  know you are going to make more changes that you revert again. This is functionally
  equivalent to calling `pop_state/1` followed immediately by `push_state/1`, except that
  it is done as a single operation in the script instead of two. This saves drawtime
  compute and makes the script smaller. Any adjacent pop/push pairs in the script will
  be converted to pop_push in the optimization phase of the `finish/1` function.

  `pop_push_state/1` must be preceded with either `push_state/1` and followed by either
  `pop_state/1` or another `pop_push_state/1`
  """
  @spec pop_push_state(ops :: t()) :: ops :: t()
  def pop_push_state(ops), do: [:pop_push_state | ops]

  @doc """
  Erase the entire drawing field output.

  The `clear/1` function is equivalent to setting a color, creating a new rect path
  that covers the entire draw field, then filling it. `clear/1` does all this in a
  single, compact script command.
  """
  @spec clear(ops :: t(), color :: Color.t()) :: ops :: t()
  def clear(ops, color) do
    [{:clear, Color.to_rgba(color)} | ops]
  end

  # internal helpers
  defp to_flag(:fill_stroke), do: @flag_fill_stroke
  defp to_flag(:fill), do: @flag_fill
  defp to_flag(:stroke), do: @flag_stroke
  defp to_flag(nil), do: 0
  defp to_flag(f) when is_integer(f) and f <= @flag_fill_stroke, do: f

  defp from_flag(@flag_fill_stroke), do: :fill_stroke
  defp from_flag(@flag_fill), do: :fill
  defp from_flag(@flag_stroke), do: :stroke
  defp from_flag(0), do: nil

  # primitive objects
  @doc """
  Draw a line from a start point to a finish point. Can only be stroked.

  Creates a new path and draws it.
  """
  @spec draw_line(ops :: t(), x0 :: number, y0 :: number, x1 :: number, y1 :: number, :stroke) ::
          ops :: t()
  def draw_line(ops, x0, y0, x1, y1, :stroke) do
    [{:draw_line, {x0, y0, x1, y1, :stroke}} | ops]
  end

  @doc """
  Draw a triangle defined by three points. Can be filled or stroked.

  Creates a new path and draws it.
  """
  @spec draw_triangle(
          ops :: t(),
          x0 :: number,
          y0 :: number,
          x1 :: number,
          y1 :: number,
          x2 :: number,
          y2 :: number,
          fill_stroke_flags :: fill_stroke()
        ) :: ops :: t()
  def draw_triangle(ops, x0, y0, x1, y1, x2, y2, flag) do
    [{:draw_triangle, {x0, y0, x1, y1, x2, y2, flag}} | ops]
  end

  @doc """
  Draw a quad defined by four points. Can be filled or stroked.

  Creates a new path and draws it.
  """
  @spec draw_quad(
          ops :: t(),
          x0 :: number,
          y0 :: number,
          x1 :: number,
          y1 :: number,
          x2 :: number,
          y2 :: number,
          x3 :: number,
          y3 :: number,
          fill_stroke_flags :: fill_stroke()
        ) :: ops :: t()
  def draw_quad(ops, x0, y0, x1, y1, x2, y2, x3, y3, flag) do
    [{:draw_quad, {x0, y0, x1, y1, x2, y2, x3, y3, flag}} | ops]
  end

  @doc """
  Draw a rectangle defined by height and width. Can be filled or stroked.

  Creates a new path and draws it.
  """
  @spec draw_rectangle(
          ops :: t(),
          width :: number,
          height :: number,
          fill_stroke_flags :: fill_stroke()
        ) :: ops :: t()
  def draw_rectangle(ops, width, height, flag) do
    [{:draw_rect, {width, height, flag}} | ops]
  end

  @doc """
  Draw a rounded rectangle defined by height, width, and radius. Can be filled or stroked.

  Creates a new path and draws it.
  """
  @spec draw_rounded_rectangle(
          ops :: t(),
          width :: number,
          height :: number,
          radius :: number,
          fill_stroke_flags :: fill_stroke()
        ) :: ops :: t()
  def draw_rounded_rectangle(ops, width, height, radius, flag) do
    radius = smallest([radius, width / 2, height / 2])
    [{:draw_rrect, {width, height, radius, flag}} | ops]
  end

  @doc """
  Draw a rounded rectangle defined by height, width, radius1, radius2, radius3 and radius4. Can be filled or stroked.

  Radii values will be set as follow:

  - Upper left corner: radius1
  - Upper right corner: radius2
  - Lower right corner: radius3
  - Lower left corner: radius4

  Creates a new path and draws it.
  """
  @spec draw_variable_rounded_rectangle(
          ops :: t(),
          width :: number,
          height :: number,
          r1 :: number,
          r2 :: number,
          r3 :: number,
          r4 :: number,
          fill_stroke_flags :: fill_stroke()
        ) :: ops :: t()
  def draw_variable_rounded_rectangle(ops, width, height, r1, r2, r3, r4, flag) do
    upper_left_radius = smallest([r1, width / 2, height / 2])
    upper_right_radius = smallest([r2, width / 2, height / 2])
    lower_right_radius = smallest([r3, width / 2, height / 2])
    lower_left_radius = smallest([r4, width / 2, height / 2])

    [
      {:draw_rrectv,
       {width, height, upper_left_radius, upper_right_radius, lower_right_radius, lower_left_radius, flag}}
      | ops
    ]
  end

  @doc """
  Draw a sector defined by radius and an angle. Can be filled or stroked.

  Creates a new path and draws it.
  """
  @spec draw_sector(
          ops :: t(),
          radius :: number,
          radians :: number,
          fill_stroke_flags :: fill_stroke()
        ) :: ops :: t()
  def draw_sector(ops, radius, radians, flag) do
    [{:draw_sector, {radius, radians, flag}} | ops]
  end

  @doc """
  Draw an arc defined by radius and an angle. Can be filled or stroked.

  Creates a new path and draws it.
  """
  @spec draw_arc(
          ops :: t(),
          radius :: number,
          radians :: number,
          fill_stroke_flags :: fill_stroke()
        ) :: ops :: t()
  def draw_arc(ops, radius, radians, flag) do
    [{:draw_arc, {radius, radians, flag}} | ops]
  end

  @doc """
  Draw a circle defined by a radius. Can be filled or stroked.

  Creates a new path and draws it.
  """
  @spec draw_circle(
          ops :: t(),
          radius :: number,
          fill_stroke_flags :: fill_stroke()
        ) :: ops :: t()
  def draw_circle(ops, radius, flag) do
    [{:draw_circle, {radius, flag}} | ops]
  end

  @doc """
  Draw an ellipse defined by two radii. Can be filled or stroked.

  Creates a new path and draws it.
  """
  @spec draw_ellipse(
          ops :: t(),
          radius0 :: number,
          radius1 :: number,
          fill_stroke_flags :: fill_stroke()
        ) :: ops :: t()
  def draw_ellipse(ops, radius0, radius1, flag) do
    [{:draw_ellipse, {radius0, radius1, flag}} | ops]
  end

  @doc """
  Draw a collection of sprites.

  Draws one or more subsection from a single source image.
  """
  @spec draw_sprites(
          ops :: t(),
          image_source :: Static.id(),
          draw_commands :: Sprites.draw_cmds()
        ) :: ops :: t()
  def draw_sprites(ops, src_id, cmds) do
    id =
      with {:ok, hash} <- Static.to_hash(src_id),
           {:ok, {Static.Image, _}} <- Static.meta(hash) do
        hash
      else
        err ->
          raise "Invalid image -> #{inspect(src_id)}, err: #{inspect(err)}"
      end

    [{:draw_sprites, {id, cmds}} | ops]
  end

  @doc """
  Draw a a block of text. Can be filled.

  Creates a new path and draws it.
  """
  @spec draw_text(ops :: t(), text :: String.t()) :: ops :: t()
  def draw_text(ops, utf8_string) do
    [{:draw_text, utf8_string} | ops]
  end

  @doc """
  Draw a a block of text with automatic new lines. Can be filled.

  Creates a new path and draws it.
  """
  @spec draw_text(ops :: t(), text :: String.t(), line_height :: number) :: ops :: t()
  def draw_text(ops, utf8_text, line_height) do
    do_draw_text(
      ops,
      String.split(utf8_text, "\n"),
      line_height
    )
  end

  defp do_draw_text(ops, [], _), do: ops
  defp do_draw_text(ops, [str], _), do: draw_text(ops, str)

  defp do_draw_text(ops, [str | tail], line_height) do
    ops
    |> draw_text(str)
    |> translate(0, line_height)
    |> do_draw_text(tail, line_height)
  end

  @doc """
  Recursively draw a script by reference.

  This adds a command that pauses the current script being rendered and
  recursively draws another script that is referenced by id.

  The new script being drawn starts with the currently set draw state and the
  current state is automatically restored with the script is completed. Then
  the current script continues drawing.
  """
  @spec render_script(ops :: t(), id :: String.t()) :: ops :: t()
  def render_script(ops, id) when is_bitstring(id) do
    [{:script, id} | ops]
  end

  # path commands
  @doc """
  Begin a new path.
  """
  @spec begin_path(ops :: t()) :: ops :: t()
  def begin_path(ops), do: [:begin_path | ops]

  @doc """
  Close the current path.

  This effectively adds a line segment from the current draw position back to
  where the path was started.
  """
  @spec close_path(ops :: t()) :: ops :: t()
  def close_path(ops), do: [:close_path | ops]

  @doc """
  Fill the current path with the currently selected fill paint.
  """
  @spec fill_path(ops :: t()) :: ops :: t()
  def fill_path(ops), do: [:fill_path | ops]

  @doc """
  Stroke the current path with the currently selected stroke width/paint.
  """
  @spec stroke_path(ops :: t()) :: ops :: t()
  def stroke_path(ops), do: [:stroke_path | ops]

  @doc """
  Move the current draw position without adding a line segment.
  """
  @spec move_to(ops :: t(), x :: number, y :: number) :: ops :: t()
  def move_to(ops, x, y) do
    [{:move_to, {x, y}} | ops]
  end

  @doc """
  Add a new line segment from the current position to a specified location.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec line_to(ops :: t(), x :: number, y :: number) :: ops :: t()
  def line_to(ops, x, y) do
    [{:line_to, {x, y}} | ops]
  end

  @doc """
  Add an arc segment to the path using the control points and radius.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec arc_to(
          ops :: t(),
          x1 :: number,
          y1 :: number,
          x2 :: number,
          y2 :: number,
          radius :: number
        ) :: ops :: t()
  def arc_to(ops, x1, y1, x2, y2, radius) do
    [{:arc_to, {x1, y1, x2, y2, radius}} | ops]
  end

  @doc """
  Add a bezier curve segment to the path using the control points.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec bezier_to(
          ops :: t(),
          cp1x :: number,
          cp1y :: number,
          cp2x :: number,
          cp2y :: number,
          x :: number,
          y :: number
        ) :: ops :: t()
  def bezier_to(ops, cp1x, cp1y, cp2x, cp2y, x, y) do
    [{:bezier_to, {cp1x, cp1y, cp2x, cp2y, x, y}} | ops]
  end

  @doc """
  Add a quadratic curve segment to the path using the control points.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec quadratic_to(ops :: t(), cpx :: number, cpy :: number, x :: number, y :: number) ::
          ops :: t()
  def quadratic_to(ops, cpx, cpy, x, y) do
    [{:quadratic_to, {cpx, cpy, x, y}} | ops]
  end

  @doc """
  Add a quad to the current path.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec quad(
          ops :: t(),
          x0 :: number,
          y0 :: number,
          x1 :: number,
          y1 :: number,
          x2 :: number,
          y2 :: number,
          x3 :: number,
          y3 :: number
        ) :: ops :: t()
  def quad(ops, x0, y0, x1, y1, x2, y2, x3, y3) do
    [{:quad, {x0, y0, x1, y1, x2, y2, x3, y3}} | ops]
  end

  @doc """
  Add a rectangle to the current path.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec rectangle(ops :: t(), width :: number, height :: number) :: ops :: t()
  def rectangle(ops, width, height) do
    [{:rect, {width, height}} | ops]
  end

  @doc """
  Add a rounded rectangle to the current path.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec rounded_rectangle(ops :: t(), width :: number, height :: number, radius :: number) ::
          ops :: t()
  def rounded_rectangle(ops, width, height, radius) do
    radius = smallest([radius, width / 2, height / 2])
    [{:rrect, {width, height, radius}} | ops]
  end

  @doc """
  Add a sector to the current path.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec sector(ops :: t(), radius :: number, radians :: number) :: ops :: t()
  def sector(ops, radius, radians) do
    [{:sector, {radius, radians}} | ops]
  end

  @doc """
  Add a circle to the current path.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec circle(ops :: t(), radius :: number) :: ops :: t()
  def circle(ops, radius) do
    [{:circle, radius} | ops]
  end

  @doc """
  Add an ellipse to the current path.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec ellipse(ops :: t(), radius0 :: number, radius1 :: number) :: ops :: t()
  def ellipse(ops, radius0, radius1) do
    [{:ellipse, {radius0, radius1}} | ops]
  end

  @doc """
  Adds a new **circle arc** shaped segment to the path.

  This adds to the current path. It does not fill or stroke anything.

  ## Parameters

    - cx, cy: The coordinates of the arc's center.
    - r: the radius of the arc.
    - a0, a1: the angles which the arc is drawn from angle a0 to a1, in radians.
    - dir: s the direction of the arc sweep:
      - `1` for counter clockwise sweep;
      - `2` for clockwise sweep.
  """
  @spec arc(
          ops :: t(),
          cx :: number,
          cy :: number,
          r :: number,
          a0 :: number,
          a1 :: number,
          dir :: integer
        ) :: ops :: t()
  def arc(ops, cx, cy, r, a0, a1, dir) do
    [{:arc, {cx, cy, r, a0, a1, dir}} | ops]
  end

  @doc """
  Add a triangle to the current path.

  This adds to the current path. It does not fill or stroke anything.
  """
  @spec triangle(
          ops :: t(),
          x0 :: number,
          y0 :: number,
          x1 :: number,
          y1 :: number,
          x2 :: number,
          y2 :: number
        ) :: ops :: t()
  def triangle(ops, x0, y0, x1, y1, x2, y2) do
    [{:triangle, {x0, y0, x1, y1, x2, y2}} | ops]
  end

  # transform commands
  @doc """
  Apply a scale transform to the current transform stack.
  """
  @spec scale(ops :: t(), x :: number, y :: number) :: ops :: t()
  def scale(ops, x, y) do
    [{:scale, {x, y}} | ops]
  end

  @doc """
  Apply a rotation transform to the current transform stack.
  """
  @spec rotate(ops :: t(), radians :: number) :: ops :: t()
  def rotate(ops, radians) do
    [{:rotate, radians} | ops]
  end

  @doc """
  Apply a translation transform to the current transform stack.
  """
  @spec translate(ops :: t(), x :: number, y :: number) :: ops :: t()
  def translate(ops, x, y) do
    [{:translate, {x, y}} | ops]
  end

  @doc """
  Apply an arbitrary transform to the current transform stack.
  """
  @spec transform(
          ops :: t(),
          a :: number,
          b :: number,
          c :: number,
          d :: number,
          e :: number,
          f :: number
        ) :: ops :: t()
  def transform(ops, a, b, c, d, e, f) do
    [{:transform, {a, b, c, d, e, f}} | ops]
  end

  # style commands

  @doc """
  Set the current fill to an single color.

  This only sets the fill paint type. You still need to call `fill_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec fill_color(ops :: t(), color :: Color.t()) :: ops :: t()
  def fill_color(ops, color) do
    [{:fill_color, Color.to_rgba(color)} | ops]
  end

  @doc """
  Set the current fill to linear gradient that goes between two colors.

  This only sets the fill paint type. You still need to call `fill_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec fill_linear(
          ops :: t(),
          start_x :: number,
          start_y :: number,
          end_x :: number,
          end_y :: number,
          color_start :: Color.t(),
          color_end :: Color.t()
        ) :: ops :: t()
  def fill_linear(ops, start_x, start_y, end_x, end_y, color_start, color_end) do
    [
      {:fill_linear,
       {
         start_x,
         start_y,
         end_x,
         end_y,
         Color.to_rgba(color_start),
         Color.to_rgba(color_end)
       }}
      | ops
    ]
  end

  @doc """
  Set the current fill to radial gradient that goes between two colors.

  This only sets the fill paint type. You still need to call `fill_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec fill_radial(
          ops :: t(),
          center_x :: number,
          center_y :: number,
          inner_radius :: number,
          outer_radius :: number,
          color_start :: Color.t(),
          color_end :: Color.t()
        ) :: ops :: t()
  def fill_radial(ops, center_x, center_y, inner_radius, outer_radius, color_start, color_end) do
    [
      {
        :fill_radial,
        {
          center_x,
          center_y,
          inner_radius,
          outer_radius,
          Color.to_rgba(color_start),
          Color.to_rgba(color_end)
        }
      }
      | ops
    ]
  end

  @doc """
  Set the current fill to an image from the Static asset library.

  This image will be automatically repeated both horizontally and vertically.

  This only sets the fill paint type. You still need to call `fill_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec fill_image(ops :: t(), image :: Static.id()) :: ops :: t()
  def fill_image(ops, id) do
    id =
      with {:ok, hash} <- Static.to_hash(id),
           {:ok, {Static.Image, _}} <- Static.meta(id) do
        hash
      else
        err ->
          raise "Invalid image -> #{inspect(id)}, err: #{inspect(err)}"
      end

    [{:fill_image, id} | ops]
  end

  @doc """
  Set the current fill to an image from an asset stream.

  This image will be automatically repeated both horizontally and vertically.

  This only sets the fill paint type. You still need to call `fill_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec fill_stream(ops :: t(), id :: Stream.id()) :: ops :: t()
  def fill_stream(ops, id) when is_bitstring(id), do: [{:fill_stream, id} | ops]

  @doc """
  Set the current stroke to an single color.

  This only sets the stroke paint type. You still need to call `stroke_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec stroke_color(ops :: t(), color :: Color.t()) :: ops :: t()
  def stroke_color(ops, color) do
    [{:stroke_color, Color.to_rgba(color)} | ops]
  end

  @doc """
  Set the current stroke to linear gradient that goes between two colors.

  This only sets the stroke paint type. You still need to call `stroke_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec stroke_linear(
          ops :: t(),
          start_x :: number,
          start_y :: number,
          end_x :: number,
          end_y :: number,
          color_start :: Color.t(),
          color_end :: Color.t()
        ) :: ops :: t()
  def stroke_linear(ops, start_x, start_y, end_x, end_y, color_start, color_end) do
    [
      {
        :stroke_linear,
        {
          start_x,
          start_y,
          end_x,
          end_y,
          Color.to_rgba(color_start),
          Color.to_rgba(color_end)
        }
      }
      | ops
    ]
  end

  @doc """
  Set the current stroke to radial gradient that goes between two colors.

  This only sets the stroke paint type. You still need to call `stroke_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec stroke_radial(
          ops :: t(),
          center_x :: number,
          center_y :: number,
          inner_radius :: number,
          outer_radius :: number,
          color_start :: Color.t(),
          color_end :: Color.t()
        ) :: ops :: t()
  def stroke_radial(ops, center_x, center_y, inner_radius, outer_radius, color_start, color_end) do
    [
      {
        :stroke_radial,
        {
          center_x,
          center_y,
          inner_radius,
          outer_radius,
          Color.to_rgba(color_start),
          Color.to_rgba(color_end)
        }
      }
      | ops
    ]
  end

  @doc """
  Set the current stroke to an image from the Static asset library.

  This image will be automatically repeated both horizontally and vertically.

  This only sets the stroke paint type. You still need to call `stroke_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec stroke_image(ops :: t(), image :: Static.id()) :: ops :: t()
  def stroke_image(ops, id) do
    id =
      with {:ok, hash} <- Static.to_hash(id),
           {:ok, {Static.Image, _}} <- Static.meta(hash) do
        hash
      else
        err ->
          raise "Invalid image -> #{inspect(id)}, err: #{inspect(err)}"
      end

    [{:stroke_image, id} | ops]
  end

  @doc """
  Set the current stroke to an image from an asset stream.

  This image will be automatically repeated both horizontally and vertically.

  This only sets the stroke paint type. You still need to call `stroke_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec stroke_stream(ops :: t(), id :: Stream.id()) :: ops :: t()
  def stroke_stream(ops, id) when is_bitstring(id), do: [{:stroke_stream, id} | ops]

  @doc """
  Set the current stroke width.

  This only sets the stroke sidth. You still need to call `stroke_path/1` or one of the
  draw_* apis to actually draw something.
  """
  @spec stroke_width(ops :: t(), width :: number) :: ops :: t()
  def stroke_width(ops, width), do: [{:stroke_width, width} | ops]

  @doc """
  Set the current end cap style.

  Can be any one of `:butt`, `:round`, or `:square`
  """
  @spec cap(ops :: t(), type :: :butt | :round | :square) :: ops :: t()
  def cap(ops, :butt), do: [{:cap, :butt} | ops]
  def cap(ops, :round), do: [{:cap, :round} | ops]
  def cap(ops, :square), do: [{:cap, :square} | ops]

  @doc """
  Set the current line joint style.

  Can be any one of `:bevel`, `:round`, or `:miter`
  """
  @spec join(ops :: t(), type :: :bevel | :round | :miter) :: ops :: t()
  def join(ops, :bevel), do: [{:join, :bevel} | ops]
  def join(ops, :round), do: [{:join, :round} | ops]
  def join(ops, :miter), do: [{:join, :miter} | ops]

  @doc """
  Set the current miter limit for joints.
  """
  @spec miter_limit(ops :: t(), limit :: number) :: ops :: t()
  def miter_limit(ops, limit), do: [{:miter_limit, limit} | ops]

  @doc """
  Set the current scissor rect.

  To remove the scissor rect, push the state before you use the scissor, then
  pop it afterwards.
  """
  @spec scissor(ops :: t(), width :: number, height :: number) :: ops :: t()
  def scissor(ops, w, h), do: [{:scissor, {w, h}} | ops]

  @doc """
  Set the current font. Must be a valid reference into your static assets library.
  """
  @spec font(ops :: t(), id :: Static.id()) :: ops :: t()
  def font(ops, id) do
    id =
      with {:ok, hash} <- Static.to_hash(id),
           {:ok, {Static.Font, _}} <- Static.meta(hash) do
        hash
      else
        err ->
          raise "Invalid font -> #{inspect(id)}, err: #{inspect(err)}"
      end

    [{:font, id} | ops]
  end

  @doc """
  Set the current font size.
  """
  @spec font_size(ops :: t(), size :: number) :: ops :: t()
  def font_size(ops, px), do: [{:font_size, px} | ops]

  @doc """
  Set the current horizontal text alignment.

  Can be any one of `:left`, `:right`, or `:center`
  """
  @spec text_align(ops :: t(), type :: :left | :center | :right) :: ops :: t()
  def text_align(ops, :left), do: [{:text_align, :left} | ops]
  def text_align(ops, :center), do: [{:text_align, :center} | ops]
  def text_align(ops, :right), do: [{:text_align, :right} | ops]

  @doc """
  Set the current vertical text alignment.

  Can be any one of `:top`, `:middle`, `:alphabetic`, or `:bottom`
  """
  @spec text_base(ops :: t(), type :: :top | :middle | :alphabetic | :bottom) :: ops :: t()
  def text_base(ops, :top), do: [{:text_base, :top} | ops]
  def text_base(ops, :middle), do: [{:text_base, :middle} | ops]
  def text_base(ops, :alphabetic), do: [{:text_base, :alphabetic} | ops]
  def text_base(ops, :bottom), do: [{:text_base, :bottom} | ops]

  # ============================================================================

  @doc """
  Transform a script list into a binary IO list.

  Usually called from a driver.

  Returns an IO list.

  ```elixir
  with {:ok, script} <- ViewPort.get_script_by_id(vp, "my_script_id") do
    Scenic.Script.serialize(script)
    |> my_render_function()
  end
  ```

  There are times when a driver will want to customize the serialization. For example,
  GLFW driver wants fixed width names for the streams. So it hooks the serialization
  of certain commands.

  ```elixir
    io_list = Script.serialize(script, fn
      {:font, id} -> my_serialize_font(id)
      {:fill_stream, id} -> my_serialize_fill_stream(id)
      {:stroke_stream, id} -> my_serialize_stroke_stream(id)
      other -> other
  end
  ```
  """
  @spec serialize(script :: t()) :: iolist
  def serialize(script)

  def serialize(script) when is_list(script) do
    Enum.map(script, &serialize_op(&1))
  end

  @doc """
  Transform a script list into a binary IO list with a map like interceptor function.

  Usually called from a driver.

  Returns an IO list.

  ```elixir
  with {:ok, script} <- ViewPort.get_script(vp, id) do
    io_list = Script.serialize(script, fn
      {:font, id} -> my_serialize_font(id)
      {:fill_stream, id} -> my_serialize_fill_stream(id)
      {:stroke_stream, id} -> my_serialize_stroke_stream(id)
      other -> other
    end)
  end
  ```
  """
  @spec serialize(
          script :: t(),
          op_fn :: (op_fn :: script_op -> nil | binary | iolist | script_op)
        ) :: iolist
  def serialize(script, intercept_fn)

  def serialize(script, op_fn) when is_list(script) and is_function(op_fn, 1) do
    Enum.map(script, fn op ->
      case op_fn.(op) do
        nil -> []
        bin when is_binary(bin) -> bin
        io_list when is_list(io_list) -> io_list
        op -> serialize_op(op)
      end
    end)
  end

  @doc """
  Transform a script list into a binary IO list with a map_reduce like interceptor function.

  Usually called from a driver.

  Returns an IO list.

  ```elixir
    {io_list, count} = Script.serialize(script, 0, fn
      {:font, id}, c -> {my_serialize_font(id), c+1}
      {:fill_stream, id}, c -> {my_serialize_fill_stream(id), c+1}
      {:stroke_stream, id}, c -> {my_serialize_stroke_stream(id), c+1}
      other, c -> {other, c+1}
    end)
  ```
  """
  @spec serialize(
          script :: t(),
          accumulator :: Enum.acc(),
          (op_fn :: script_op, state :: any ->
             {nil, any} | {binary, any} | {iolist, any} | {script_op, any})
        ) :: {iolist, Enum.acc()}
  def serialize(script, acc, intercept_fn)

  def serialize(script, acc, op_fn) when is_list(script) and is_function(op_fn, 2) do
    Enum.map_reduce(script, acc, fn op, acc ->
      case op_fn.(op, acc) do
        {nil, acc} -> {[], acc}
        {bin, acc} when is_binary(bin) -> {bin, acc}
        {io_list, acc} when is_list(io_list) -> {io_list, acc}
        {op, acc} -> {serialize_op(op), acc}
      end
    end)
  end

  @doc """
  Transform a binary or io list into a readable script list.

  This is intended to help with debugging.

  Deserialization will only work for scripts serialized using the standard, un-hooked format.
  """

  @spec deserialize(bin :: binary) :: script :: t()
  def deserialize(bin) when is_binary(bin) do
    do_deserialize(bin)
  end

  def deserialize(iodata) when is_list(iodata) do
    iodata
    |> IO.iodata_to_binary()
    |> do_deserialize()
  end

  defp do_deserialize(bin, ops \\ [])
  defp do_deserialize(<<>>, ops), do: Enum.reverse(ops)
  defp do_deserialize(<<@finished::32>>, ops), do: Enum.reverse(ops)

  defp do_deserialize(bin, ops) do
    {op, bin} = deserialize_op(bin)
    do_deserialize(bin, [op | ops])
  end

  # ============================================================================
  # serialization helpers

  defp serialize_op(:finished), do: <<@finished::32>>

  defp serialize_op(:push_state), do: <<@op_push_state::16-big, 0::16>>
  # defp serialize_op( :restore_state ),  do: << @op_restore_state::16-big, 0::16 >>
  defp serialize_op(:pop_state), do: <<@op_pop_state::16-big, 0::16>>
  defp serialize_op(:pop_push_state), do: <<@op_pop_push_state::16-big, 0::16>>

  defp serialize_op({:draw_line, {x0, y0, x1, y1, flag}}) do
    <<
      @op_draw_line::16-big,
      to_flag(flag)::16-big,
      x0::float-32-big,
      y0::float-32-big,
      x1::float-32-big,
      y1::float-32-big
    >>
  end

  defp serialize_op({:draw_triangle, {x0, y0, x1, y1, x2, y2, flag}}) do
    <<
      @op_draw_triangle::16-big,
      to_flag(flag)::16-big,
      x0::float-32-big,
      y0::float-32-big,
      x1::float-32-big,
      y1::float-32-big,
      x2::float-32-big,
      y2::float-32-big
    >>
  end

  defp serialize_op({:draw_quad, {x0, y0, x1, y1, x2, y2, x3, y3, flag}}) do
    <<
      @op_draw_quad::16-big,
      to_flag(flag)::16-big,
      x0::float-32-big,
      y0::float-32-big,
      x1::float-32-big,
      y1::float-32-big,
      x2::float-32-big,
      y2::float-32-big,
      x3::float-32-big,
      y3::float-32-big
    >>
  end

  defp serialize_op({:draw_rect, {w, h, flag}}) do
    <<
      @op_draw_rect::16-big,
      to_flag(flag)::16-big,
      w::float-32-big,
      h::float-32-big
    >>
  end

  defp serialize_op({:draw_rrect, {w, h, r, flag}}) do
    <<
      @op_draw_rrect::16-big,
      to_flag(flag)::16-big,
      w::float-32-big,
      h::float-32-big,
      r::float-32-big
    >>
  end

  defp serialize_op({:draw_arc, {radius, radians, flag}}) do
    <<
      @op_draw_arc::16-big,
      to_flag(flag)::16-big,
      radius::float-32-big,
      radians::float-32-big
    >>
  end

  defp serialize_op({:draw_sector, {radius, radians, flag}}) do
    <<
      @op_draw_sector::16-big,
      to_flag(flag)::16-big,
      radius::float-32-big,
      radians::float-32-big
    >>
  end

  defp serialize_op({:draw_circle, {radius, flag}}) do
    <<
      @op_draw_circle::16-big,
      to_flag(flag)::16-big,
      radius::float-32-big
    >>
  end

  defp serialize_op({:draw_ellipse, {radius0, radius1, flag}}) do
    <<
      @op_draw_ellipse::16-big,
      to_flag(flag)::16-big,
      radius0::float-32-big,
      radius1::float-32-big
    >>
  end

  defp serialize_op({:draw_text, text}) do
    [
      <<
        @op_draw_text::16-big,
        byte_size(text)::16-big
      >>,
      padded_string(text)
    ]
  end

  defp serialize_op({:draw_sprites, {id, cmds}}) do
    hash =
      with {:ok, {Static.Image, _}} <- Static.meta(id),
           {:ok, str_hash} <- Static.to_hash(id) do
        # {:ok, bin_hash} <- Base.url_decode64(str_hash, padding: false) do
        str_hash
      else
        err -> raise "Invalid image -> #{inspect(id)}, err: #{inspect(err)}"
      end

    {cmds, count} =
      Enum.reduce(cmds, {[], 0}, fn
        {{sx, sy}, {sw, sh}, {dx, dy}, {dw, dh}, alpha}, {cmds, count} ->
          {
            [
              <<
                sx::float-32-big,
                sy::float-32-big,
                sw::float-32-big,
                sh::float-32-big,
                dx::float-32-big,
                dy::float-32-big,
                dw::float-32-big,
                dh::float-32-big,
                alpha::float-32-big
              >>
              | cmds
            ],
            count + 1
          }
      end)

    cmds = Enum.reverse(cmds)

    [
      <<@op_draw_sprites::16-big>>,
      <<byte_size(hash)::16-big>>,
      <<count::32-big>>,
      padded_string(hash),
      cmds
    ]
  end

  defp serialize_op({:draw_rrectv, {w, h, ulR, urR, lrR, llR, flag}}) do
    <<
      @op_draw_rrectv::16-big,
      to_flag(flag)::16-big,
      w::float-32-big,
      h::float-32-big,
      ulR::float-32-big,
      urR::float-32-big,
      lrR::float-32-big,
      llR::float-32-big
    >>
  end

  defp serialize_op({:script, id}) do
    [
      <<
        @op_draw_script::16-big,
        byte_size(id)::16
      >>,
      padded_string(id)
    ]
  end

  defp serialize_op(:begin_path), do: <<@op_begin_path::16-big, 0::16>>
  defp serialize_op(:close_path), do: <<@op_close_path::16-big, 0::16>>
  defp serialize_op(:fill_path), do: <<@op_fill_path::16-big, 0::16>>
  defp serialize_op(:stroke_path), do: <<@op_stroke_path::16-big, 0::16>>

  defp serialize_op({:move_to, {x, y}}) do
    [
      <<
        @op_move_to::16-big,
        0::16
      >>,
      <<
        x::float-32-big,
        y::float-32-big
      >>
    ]
  end

  defp serialize_op({:line_to, {x, y}}) do
    [
      <<
        @op_line_to::16-big,
        0::16
      >>,
      <<
        x::float-32-big,
        y::float-32-big
      >>
    ]
  end

  defp serialize_op({:arc_to, {x1, y1, x2, y2, radius}}) do
    [
      <<
        @op_arc_to::16-big,
        0::16
      >>,
      <<
        x1::float-32-big,
        y1::float-32-big,
        x2::float-32-big,
        y2::float-32-big,
        radius::float-32-big
      >>
    ]
  end

  defp serialize_op({:arc, {cx, cy, r, a0, a1, dir}}) do
    [
      <<
        @op_arc::16-big,
        0::16
      >>,
      <<
        cx::float-32-big,
        cy::float-32-big,
        r::float-32-big,
        a0::float-32-big,
        a1::float-32-big,
        dir::32-big
      >>
    ]
  end

  defp serialize_op({:bezier_to, {cp1x, cp1y, cp2x, cp2y, x, y}}) do
    [
      <<
        @op_bezier_to::16-big,
        0::16
      >>,
      <<
        cp1x::float-32-big,
        cp1y::float-32-big,
        cp2x::float-32-big,
        cp2y::float-32-big,
        x::float-32-big,
        y::float-32-big
      >>
    ]
  end

  defp serialize_op({:quadratic_to, {cpx, cpy, x, y}}) do
    [
      <<
        @op_quadratic_to::16-big,
        0::16
      >>,
      <<
        cpx::float-32-big,
        cpy::float-32-big,
        x::float-32-big,
        y::float-32-big
      >>
    ]
  end

  defp serialize_op({:triangle, {x0, y0, x1, y1, x2, y2}}) do
    <<
      @op_triangle::16-big,
      0::16-big,
      x0::float-32-big,
      y0::float-32-big,
      x1::float-32-big,
      y1::float-32-big,
      x2::float-32-big,
      y2::float-32-big
    >>
  end

  defp serialize_op({:quad, {x0, y0, x1, y1, x2, y2, x3, y3}}) do
    <<
      @op_quad::16-big,
      0::16-big,
      x0::float-32-big,
      y0::float-32-big,
      x1::float-32-big,
      y1::float-32-big,
      x2::float-32-big,
      y2::float-32-big,
      x3::float-32-big,
      y3::float-32-big
    >>
  end

  defp serialize_op({:rect, {w, h}}) do
    <<
      @op_rect::16-big,
      0::16-big,
      w::float-32-big,
      h::float-32-big
    >>
  end

  defp serialize_op({:rrect, {w, h, r}}) do
    <<
      @op_rrect::16-big,
      0::16-big,
      w::float-32-big,
      h::float-32-big,
      r::float-32-big
    >>
  end

  defp serialize_op({:sector, {radius, radians}}) do
    <<
      @op_sector::16-big,
      0::16-big,
      radius::float-32-big,
      radians::float-32-big
    >>
  end

  defp serialize_op({:circle, radius}) do
    <<
      @op_circle::16-big,
      0::16-big,
      radius::float-32-big
    >>
  end

  defp serialize_op({:ellipse, {radius0, radius1}}) do
    <<
      @op_ellipse::16-big,
      0::16-big,
      radius0::float-32-big,
      radius1::float-32-big
    >>
  end

  # transform commands
  defp serialize_op({:scale, {x, y}}) do
    [
      <<
        @op_scale::16-big,
        0::16
      >>,
      <<
        x::float-32-big,
        y::float-32-big
      >>
    ]
  end

  defp serialize_op({:rotate, radians}) do
    <<
      @op_rotate::16-big,
      0::16,
      radians::float-32-big
    >>
  end

  defp serialize_op({:translate, {x, y}}) do
    [
      <<
        @op_translate::16-big,
        0::16
      >>,
      <<
        x::float-32-big,
        y::float-32-big
      >>
    ]
  end

  defp serialize_op({:transform, {a, b, c, d, e, f}}) do
    [
      <<
        @op_transform::16-big,
        0::16
      >>,
      <<
        a::float-32-big,
        b::float-32-big,
        c::float-32-big,
        d::float-32-big,
        e::float-32-big,
        f::float-32-big
      >>
    ]
  end

  # style commands

  defp serialize_op({:fill_color, color}) do
    {:color_rgba, {r, g, b, a}} = Color.to_rgba(color)

    <<
      @op_fill_color::16-big,
      0::16,
      r::8,
      g::8,
      b::8,
      a::8
    >>
  end

  defp serialize_op(
         {:fill_linear,
          {
            start_x,
            start_y,
            end_x,
            end_y,
            start_color,
            end_color
          }}
       ) do
    {:color_rgba, {sr, sg, sb, sa}} = Color.to_rgba(start_color)
    {:color_rgba, {er, eg, eb, ea}} = Color.to_rgba(end_color)

    [
      <<
        @op_fill_linear::16-big,
        0::16
      >>,
      <<
        start_x::float-32-big,
        start_y::float-32-big,
        end_x::float-32-big,
        end_y::float-32-big,
        sr::8,
        sg::8,
        sb::8,
        sa::8,
        er::8,
        eg::8,
        eb::8,
        ea::8
      >>
    ]
  end

  defp serialize_op(
         {:fill_radial,
          {
            center_x,
            center_y,
            inner_radius,
            outer_radius,
            start_color,
            end_color
          }}
       ) do
    {:color_rgba, {sr, sg, sb, sa}} = Color.to_rgba(start_color)
    {:color_rgba, {er, eg, eb, ea}} = Color.to_rgba(end_color)

    [
      <<
        @op_fill_radial::16-big,
        0::16
      >>,
      <<
        center_x::float-32-big,
        center_y::float-32-big,
        inner_radius::float-32-big,
        outer_radius::float-32-big,
        sr::8,
        sg::8,
        sb::8,
        sa::8,
        er::8,
        eg::8,
        eb::8,
        ea::8
      >>
    ]
  end

  defp serialize_op({:fill_image, id}) do
    hash =
      with {:ok, {Static.Image, _}} <- Static.meta(id),
           {:ok, str_hash} <- Static.to_hash(id) do
        # {:ok, bin_hash} <- Base.url_decode64(str_hash, padding: false) do
        str_hash
      else
        err ->
          raise "Invalid image -> #{inspect(id)}, err: #{inspect(err)}"
      end

    [
      <<
        @op_fill_image::16-big,
        byte_size(hash)::16
      >>,
      padded_string(hash)
    ]
  end

  defp serialize_op({:fill_stream, id})
       when is_bitstring(id) do
    [
      <<
        @op_fill_stream::16-big,
        byte_size(id)::16
      >>,
      padded_string(id)
    ]
  end

  defp serialize_op({:stroke_color, color}) do
    {:color_rgba, {r, g, b, a}} = Color.to_rgba(color)

    <<
      @op_stroke_color::16-big,
      0::16,
      r::8,
      g::8,
      b::8,
      a::8
    >>
  end

  defp serialize_op(
         {:stroke_linear,
          {
            start_x,
            start_y,
            end_x,
            end_y,
            start_color,
            end_color
          }}
       ) do
    {:color_rgba, {sr, sg, sb, sa}} = Color.to_rgba(start_color)
    {:color_rgba, {er, eg, eb, ea}} = Color.to_rgba(end_color)

    [
      <<
        @op_stroke_linear::16-big,
        0::16
      >>,
      <<
        start_x::float-32-big,
        start_y::float-32-big,
        end_x::float-32-big,
        end_y::float-32-big,
        sr::8,
        sg::8,
        sb::8,
        sa::8,
        er::8,
        eg::8,
        eb::8,
        ea::8
      >>
    ]
  end

  defp serialize_op(
         {:stroke_radial,
          {
            center_x,
            center_y,
            inner_radius,
            outer_radius,
            start_color,
            end_color
          }}
       ) do
    {:color_rgba, {sr, sg, sb, sa}} = Color.to_rgba(start_color)
    {:color_rgba, {er, eg, eb, ea}} = Color.to_rgba(end_color)

    [
      <<
        @op_stroke_radial::16-big,
        0::16
      >>,
      <<
        center_x::float-32-big,
        center_y::float-32-big,
        inner_radius::float-32-big,
        outer_radius::float-32-big,
        sr::8,
        sg::8,
        sb::8,
        sa::8,
        er::8,
        eg::8,
        eb::8,
        ea::8
      >>
    ]
  end

  defp serialize_op({:stroke_image, id}) do
    hash =
      with {:ok, {Static.Image, _}} <- Static.meta(id),
           {:ok, str_hash} <- Static.to_hash(id) do
        # {:ok, bin_hash} <- Base.url_decode64(str_hash, padding: false) do
        str_hash
      else
        err ->
          raise "Invalid image -> #{inspect(id)}, err: #{inspect(err)}"
      end

    [
      <<
        @op_stroke_image::16-big,
        byte_size(hash)::16
      >>,
      padded_string(hash)
    ]
  end

  defp serialize_op({:stroke_stream, id})
       when is_bitstring(id) do
    [
      <<
        @op_stroke_stream::16-big,
        byte_size(id)::16
      >>,
      padded_string(id)
    ]
  end

  defp serialize_op({:stroke_width, width}) do
    width = trunc(width * 4)

    <<
      @op_stroke_width::16-big,
      width::16-big
    >>
  end

  defp serialize_op({:cap, :butt}) do
    <<
      @op_cap::16-big,
      @line_butt::16-big
    >>
  end

  defp serialize_op({:cap, :round}) do
    <<
      @op_cap::16-big,
      @line_round::16-big
    >>
  end

  defp serialize_op({:cap, :square}) do
    <<
      @op_cap::16-big,
      @line_square::16-big
    >>
  end

  defp serialize_op({:join, :bevel}) do
    <<
      @op_join::16-big,
      @join_bevel::16-big
    >>
  end

  defp serialize_op({:join, :round}) do
    <<
      @op_join::16-big,
      @join_round::16-big
    >>
  end

  defp serialize_op({:join, :miter}) do
    <<
      @op_join::16-big,
      @join_miter::16-big
    >>
  end

  defp serialize_op({:miter_limit, limit}) do
    <<
      @op_miter_limit::16-big,
      limit::16-big
    >>
  end

  defp serialize_op({:scissor, {w, h}}) do
    [
      <<
        @op_scissor::16-big,
        0::16
      >>,
      <<
        w::float-32-big,
        h::float-32-big
      >>
    ]
  end

  defp serialize_op({:font, id}) do
    hash =
      with {:ok, {Static.Font, _}} <- Static.meta(id),
           {:ok, str_hash} <- Static.to_hash(id) do
        str_hash
      else
        err -> raise "Invalid font -> #{inspect(id)}, err: #{inspect(err)}"
      end

    [
      <<
        @op_font::16-big,
        byte_size(hash)::16-big
      >>,
      padded_string(hash)
    ]
  end

  defp serialize_op({:font_size, px}) do
    px = trunc(px * 4)

    <<
      @op_font_size::16-big,
      px::16-big
    >>
  end

  defp serialize_op({:text_align, :left}), do: <<@op_text_align::16-big, @align_left::16-big>>
  defp serialize_op({:text_align, :center}), do: <<@op_text_align::16-big, @align_center::16-big>>
  defp serialize_op({:text_align, :right}), do: <<@op_text_align::16-big, @align_right::16-big>>

  defp serialize_op({:text_base, :top}), do: <<@op_text_base::16-big, @baseline_top::16-big>>

  defp serialize_op({:text_base, :middle}),
    do: <<@op_text_base::16-big, @baseline_middle::16-big>>

  defp serialize_op({:text_base, :alphabetic}),
    do: <<@op_text_base::16-big, @baseline_alphabetic::16-big>>

  defp serialize_op({:text_base, :bottom}),
    do: <<@op_text_base::16-big, @baseline_bottom::16-big>>

  defp smallest([h | t]), do: do_smallest(t, h)
  defp do_smallest([], current), do: current
  defp do_smallest([h | t], current) when h < current, do: do_smallest(t, h)
  defp do_smallest([_ | t], current), do: do_smallest(t, current)

  @doc false
  def padded_string(string) do
    [
      string,
      string
      |> byte_size()
      |> rem(4)
      |> case do
        0 -> <<>>
        1 -> <<0::24>>
        2 -> <<0::16>>
        3 -> <<0::8>>
      end
    ]
  end

  # ============================================================================
  # deserialization helpers

  defp deserialize_op(<<@finished::32, bin::binary>>), do: {:finished, bin}

  defp deserialize_op(<<@op_push_state::16-big, 0::16, bin::binary>>), do: {:push_state, bin}
  defp deserialize_op(<<@op_pop_state::16-big, 0::16, bin::binary>>), do: {:pop_state, bin}

  defp deserialize_op(<<@op_pop_push_state::16-big, 0::16, bin::binary>>),
    do: {:pop_push_state, bin}

  defp deserialize_op(<<
         @op_draw_line::16-big,
         flag::16-big,
         x0::float-32-big,
         y0::float-32-big,
         x1::float-32-big,
         y1::float-32-big,
         bin::binary
       >>) do
    {{:draw_line, {x0, y0, x1, y1, from_flag(flag)}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_triangle::16-big,
         flag::16-big,
         x0::float-32-big,
         y0::float-32-big,
         x1::float-32-big,
         y1::float-32-big,
         x2::float-32-big,
         y2::float-32-big,
         bin::binary
       >>) do
    {{:draw_triangle, {x0, y0, x1, y1, x2, y2, from_flag(flag)}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_quad::16-big,
         flag::16-big,
         x0::float-32-big,
         y0::float-32-big,
         x1::float-32-big,
         y1::float-32-big,
         x2::float-32-big,
         y2::float-32-big,
         x3::float-32-big,
         y3::float-32-big,
         bin::binary
       >>) do
    {{:draw_quad, {x0, y0, x1, y1, x2, y2, x3, y3, from_flag(flag)}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_rect::16-big,
         flag::16-big,
         w::float-32-big,
         h::float-32-big,
         bin::binary
       >>) do
    {{:draw_rect, {w, h, from_flag(flag)}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_rrect::16-big,
         flag::16-big,
         w::float-32-big,
         h::float-32-big,
         r::float-32-big,
         bin::binary
       >>) do
    {{:draw_rrect, {w, h, r, from_flag(flag)}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_arc::16-big,
         flag::16-big,
         radius::float-32-big,
         radians::float-32-big,
         bin::binary
       >>) do
    {{:draw_arc, {radius, radians, from_flag(flag)}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_sector::16-big,
         flag::16-big,
         radius::float-32-big,
         radians::float-32-big,
         bin::binary
       >>) do
    {{:draw_sector, {radius, radians, from_flag(flag)}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_circle::16-big,
         flag::16-big,
         radius::float-32-big,
         bin::binary
       >>) do
    {{:draw_circle, {radius, from_flag(flag)}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_ellipse::16-big,
         flag::16-big,
         radius0::float-32-big,
         radius1::float-32-big,
         bin::binary
       >>) do
    {{:draw_ellipse, {radius0, radius1, from_flag(flag)}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_text::16-big,
         bytes::16-big,
         bin::binary
       >>) do
    {text, bin} = extract_string(bin, bytes)
    {{:draw_text, text}, bin}
  end

  defp deserialize_op(<<
         @op_draw_sprites::16-big,
         id_size::16-big,
         count::32-big,
         bin::binary
       >>) do
    {id, bin} = extract_string(bin, id_size)

    {cmds, bin} =
      Enum.reduce(1..count, {[], bin}, fn _, {cmds, bin} ->
        <<
          sx::float-32-big,
          sy::float-32-big,
          sw::float-32-big,
          sh::float-32-big,
          dx::float-32-big,
          dy::float-32-big,
          dw::float-32-big,
          dh::float-32-big,
          alpha::float-32-big,
          bin::binary
        >> = bin

        {[{{sx, sy}, {sw, sh}, {dx, dy}, {dw, dh}, alpha} | cmds], bin}
      end)

    cmds = Enum.reverse(cmds)
    {{:draw_sprites, {id, cmds}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_rrectv::16-big,
         flag::16-big,
         w::float-32-big,
         h::float-32-big,
         ulR::float-32-big,
         urR::float-32-big,
         lrR::float-32-big,
         llR::float-32-big,
         bin::binary
       >>) do
    {{:draw_rrectv, {w, h, ulR, urR, lrR, llR, from_flag(flag)}}, bin}
  end

  defp deserialize_op(<<
         @op_draw_script::16-big,
         id_size::16,
         bin::binary
       >>) do
    {id, bin} = extract_string(bin, id_size)
    {{:script, id}, bin}
  end

  defp deserialize_op(<<@op_begin_path::16-big, 0::16, bin::binary>>), do: {:begin_path, bin}
  defp deserialize_op(<<@op_close_path::16-big, 0::16, bin::binary>>), do: {:close_path, bin}
  defp deserialize_op(<<@op_fill_path::16-big, 0::16, bin::binary>>), do: {:fill_path, bin}
  defp deserialize_op(<<@op_stroke_path::16-big, 0::16, bin::binary>>), do: {:stroke_path, bin}

  defp deserialize_op(<<
         @op_move_to::16-big,
         0::16,
         x::float-32-big,
         y::float-32-big,
         bin::binary
       >>) do
    {{:move_to, {x, y}}, bin}
  end

  defp deserialize_op(<<
         @op_line_to::16-big,
         0::16,
         x::float-32-big,
         y::float-32-big,
         bin::binary
       >>) do
    {{:line_to, {x, y}}, bin}
  end

  defp deserialize_op(<<
         @op_arc_to::16-big,
         0::16,
         x1::float-32-big,
         y1::float-32-big,
         x2::float-32-big,
         y2::float-32-big,
         radius::float-32-big,
         bin::binary
       >>) do
    {{:arc_to, {x1, y1, x2, y2, radius}}, bin}
  end

  defp deserialize_op(<<
         @op_arc::16-big,
         0::16,
         cx::float-32-big,
         cy::float-32-big,
         r::float-32-big,
         a0::float-32-big,
         a1::float-32-big,
         dir::32-big,
         bin::binary
       >>) do
    {{:arc, {cx, cy, r, a0, a1, dir}}, bin}
  end

  defp deserialize_op(<<
         @op_bezier_to::16-big,
         0::16,
         cp1x::float-32-big,
         cp1y::float-32-big,
         cp2x::float-32-big,
         cp2y::float-32-big,
         x::float-32-big,
         y::float-32-big,
         bin::binary
       >>) do
    {{:bezier_to, {cp1x, cp1y, cp2x, cp2y, x, y}}, bin}
  end

  defp deserialize_op(<<
         @op_quadratic_to::16-big,
         0::16,
         cpx::float-32-big,
         cpy::float-32-big,
         x::float-32-big,
         y::float-32-big,
         bin::binary
       >>) do
    {{:quadratic_to, {cpx, cpy, x, y}}, bin}
  end

  defp deserialize_op(<<
         @op_triangle::16-big,
         0::16-big,
         x0::float-32-big,
         y0::float-32-big,
         x1::float-32-big,
         y1::float-32-big,
         x2::float-32-big,
         y2::float-32-big,
         bin::binary
       >>) do
    {{:triangle, {x0, y0, x1, y1, x2, y2}}, bin}
  end

  defp deserialize_op(<<
         @op_quad::16-big,
         0::16-big,
         x0::float-32-big,
         y0::float-32-big,
         x1::float-32-big,
         y1::float-32-big,
         x2::float-32-big,
         y2::float-32-big,
         x3::float-32-big,
         y3::float-32-big,
         bin::binary
       >>) do
    {{:quad, {x0, y0, x1, y1, x2, y2, x3, y3}}, bin}
  end

  defp deserialize_op(<<
         @op_rect::16-big,
         0::16-big,
         w::float-32-big,
         h::float-32-big,
         bin::binary
       >>) do
    {{:rect, {w, h}}, bin}
  end

  defp deserialize_op(<<
         @op_rrect::16-big,
         0::16-big,
         w::float-32-big,
         h::float-32-big,
         r::float-32-big,
         bin::binary
       >>) do
    {{:rrect, {w, h, r}}, bin}
  end

  defp deserialize_op(<<
         @op_sector::16-big,
         0::16-big,
         radius::float-32-big,
         radians::float-32-big,
         bin::binary
       >>) do
    {{:sector, {radius, radians}}, bin}
  end

  defp deserialize_op(<<
         @op_circle::16-big,
         0::16-big,
         radius::float-32-big,
         bin::binary
       >>) do
    {{:circle, radius}, bin}
  end

  defp deserialize_op(<<
         @op_ellipse::16-big,
         0::16-big,
         radius0::float-32-big,
         radius1::float-32-big,
         bin::binary
       >>) do
    {{:ellipse, {radius0, radius1}}, bin}
  end

  # transform commands
  defp deserialize_op(<<
         @op_scale::16-big,
         0::16,
         x::float-32-big,
         y::float-32-big,
         bin::binary
       >>) do
    {{:scale, {x, y}}, bin}
  end

  defp deserialize_op(<<
         @op_rotate::16-big,
         0::16,
         radians::float-32-big,
         bin::binary
       >>) do
    {{:rotate, radians}, bin}
  end

  defp deserialize_op(<<
         @op_translate::16-big,
         0::16,
         x::float-32-big,
         y::float-32-big,
         bin::binary
       >>) do
    {{:translate, {x, y}}, bin}
  end

  defp deserialize_op(<<
         @op_transform::16-big,
         0::16,
         a::float-32-big,
         b::float-32-big,
         c::float-32-big,
         d::float-32-big,
         e::float-32-big,
         f::float-32-big,
         bin::binary
       >>) do
    {{:transform, {a, b, c, d, e, f}}, bin}
  end

  # style commands

  defp deserialize_op(<<
         @op_fill_color::16-big,
         0::16,
         r::8,
         g::8,
         b::8,
         a::8,
         bin::binary
       >>) do
    {{:fill_color, {:color_rgba, {r, g, b, a}}}, bin}
  end

  defp deserialize_op(<<
         @op_fill_linear::16-big,
         0::16,
         start_x::float-32-big,
         start_y::float-32-big,
         end_x::float-32-big,
         end_y::float-32-big,
         sr::8,
         sg::8,
         sb::8,
         sa::8,
         er::8,
         eg::8,
         eb::8,
         ea::8,
         bin::binary
       >>) do
    {
      {
        :fill_linear,
        {
          start_x,
          start_y,
          end_x,
          end_y,
          {:color_rgba, {sr, sg, sb, sa}},
          {:color_rgba, {er, eg, eb, ea}}
        }
      },
      bin
    }
  end

  defp deserialize_op(<<
         @op_fill_radial::16-big,
         0::16,
         center_x::float-32-big,
         center_y::float-32-big,
         inner_radius::float-32-big,
         outer_radius::float-32-big,
         sr::8,
         sg::8,
         sb::8,
         sa::8,
         er::8,
         eg::8,
         eb::8,
         ea::8,
         bin::binary
       >>) do
    {
      {
        :fill_radial,
        {
          center_x,
          center_y,
          inner_radius,
          outer_radius,
          {:color_rgba, {sr, sg, sb, sa}},
          {:color_rgba, {er, eg, eb, ea}}
        }
      },
      bin
    }
  end

  defp deserialize_op(<<
         @op_fill_image::16-big,
         id_size::16,
         bin::binary
       >>) do
    {id, bin} = extract_string(bin, id_size)
    {{:fill_image, id}, bin}
  end

  defp deserialize_op(<<
         @op_fill_stream::16-big,
         key_size::16,
         bin::binary
       >>) do
    {key, bin} = extract_string(bin, key_size)
    {{:fill_stream, key}, bin}
  end

  defp deserialize_op(<<
         @op_stroke_color::16-big,
         0::16,
         r::8,
         g::8,
         b::8,
         a::8,
         bin::binary
       >>) do
    {{:stroke_color, {:color_rgba, {r, g, b, a}}}, bin}
  end

  defp deserialize_op(<<
         @op_stroke_linear::16-big,
         0::16,
         start_x::float-32-big,
         start_y::float-32-big,
         end_x::float-32-big,
         end_y::float-32-big,
         sr::8,
         sg::8,
         sb::8,
         sa::8,
         er::8,
         eg::8,
         eb::8,
         ea::8,
         bin::binary
       >>) do
    {
      {
        :stroke_linear,
        {
          start_x,
          start_y,
          end_x,
          end_y,
          {:color_rgba, {sr, sg, sb, sa}},
          {:color_rgba, {er, eg, eb, ea}}
        }
      },
      bin
    }
  end

  defp deserialize_op(<<
         @op_stroke_radial::16-big,
         0::16,
         center_x::float-32-big,
         center_y::float-32-big,
         inner_radius::float-32-big,
         outer_radius::float-32-big,
         sr::8,
         sg::8,
         sb::8,
         sa::8,
         er::8,
         eg::8,
         eb::8,
         ea::8,
         bin::binary
       >>) do
    {
      {
        :stroke_radial,
        {
          center_x,
          center_y,
          inner_radius,
          outer_radius,
          {:color_rgba, {sr, sg, sb, sa}},
          {:color_rgba, {er, eg, eb, ea}}
        }
      },
      bin
    }
  end

  defp deserialize_op(<<
         @op_stroke_image::16-big,
         id_size::16,
         bin::binary
       >>) do
    {id, bin} = extract_string(bin, id_size)
    {{:stroke_image, id}, bin}
  end

  defp deserialize_op(<<
         @op_stroke_stream::16-big,
         key_size::16,
         bin::binary
       >>) do
    {key, bin} = extract_string(bin, key_size)
    {{:stroke_stream, key}, bin}
  end

  defp deserialize_op(<<
         @op_stroke_width::16-big,
         width::16-big,
         bin::binary
       >>) do
    {{:stroke_width, width / 4}, bin}
  end

  defp deserialize_op(<<
         @op_cap::16-big,
         @line_butt::16-big,
         bin::binary
       >>) do
    {{:cap, :butt}, bin}
  end

  defp deserialize_op(<<
         @op_cap::16-big,
         @line_round::16-big,
         bin::binary
       >>) do
    {{:cap, :round}, bin}
  end

  defp deserialize_op(<<
         @op_cap::16-big,
         @line_square::16-big,
         bin::binary
       >>) do
    {{:cap, :square}, bin}
  end

  defp deserialize_op(<<
         @op_join::16-big,
         @join_bevel::16-big,
         bin::binary
       >>) do
    {{:join, :bevel}, bin}
  end

  defp deserialize_op(<<
         @op_join::16-big,
         @join_round::16-big,
         bin::binary
       >>) do
    {{:join, :round}, bin}
  end

  defp deserialize_op(<<
         @op_join::16-big,
         @join_miter::16-big,
         bin::binary
       >>) do
    {{:join, :miter}, bin}
  end

  defp deserialize_op(<<
         @op_miter_limit::16-big,
         limit::16-big,
         bin::binary
       >>) do
    {{:miter_limit, limit}, bin}
  end

  defp deserialize_op(<<
         @op_scissor::16-big,
         0::16,
         w::float-32-big,
         h::float-32-big,
         bin::binary
       >>) do
    {{:scissor, {w, h}}, bin}
  end

  defp deserialize_op(<<
         @op_font::16-big,
         id_size::16-big,
         bin::binary
       >>) do
    {id, bin} = extract_string(bin, id_size)
    {{:font, id}, bin}
  end

  defp deserialize_op(<<
         @op_font_size::16-big,
         px::16-big,
         bin::binary
       >>) do
    {{:font_size, px / 4}, bin}
  end

  defp deserialize_op(<<@op_text_align::16-big, @align_left::16, bin::binary>>),
    do: {{:text_align, :left}, bin}

  defp deserialize_op(<<@op_text_align::16-big, @align_center::16, bin::binary>>),
    do: {{:text_align, :center}, bin}

  defp deserialize_op(<<@op_text_align::16-big, @align_right::16, bin::binary>>),
    do: {{:text_align, :right}, bin}

  defp deserialize_op(<<@op_text_base::16-big, @baseline_top::16, bin::binary>>),
    do: {{:text_base, :top}, bin}

  defp deserialize_op(<<@op_text_base::16-big, @baseline_middle::16, bin::binary>>),
    do: {{:text_base, :middle}, bin}

  defp deserialize_op(<<@op_text_base::16-big, @baseline_alphabetic::16, bin::binary>>),
    do: {{:text_base, :alphabetic}, bin}

  defp deserialize_op(<<@op_text_base::16-big, @baseline_bottom::16, bin::binary>>),
    do: {{:text_base, :bottom}, bin}

  defp extract_string(bin, bytes) do
    buff_size =
      case rem(bytes, 4) do
        0 -> 0
        1 -> 3
        2 -> 2
        3 -> 1
      end

    <<
      str::binary-size(bytes),
      _buff::binary-size(buff_size),
      bin::binary
    >> = bin

    {str, bin}
  end

  defp optimize(ops) when is_list(ops) do
    do_optimize(ops, [])
  end

  defp do_optimize([], acc), do: acc

  defp do_optimize([:push_state | [:pop_state | tail]], acc) do
    do_optimize(tail, [:pop_push_state | acc])
  end

  defp do_optimize([head | tail], acc) do
    do_optimize(tail, [head | acc])
  end

  @doc """
  Extract a map of all the media (both static assets and streams) used in a script.
  """
  def media(script) do
    raw_media(script)
    |> Enum.into(%{})
  end

  defp raw_media(script) do
    Enum.reduce(script, [], fn
      {:font, id}, m -> Keyword.put(m, :fonts, [id | Keyword.get(m, :fonts, [])])
      {:fill_image, id}, m -> Keyword.put(m, :images, [id | Keyword.get(m, :images, [])])
      {:fill_stream, id}, m -> Keyword.put(m, :streams, [id | Keyword.get(m, :streams, [])])
      {:stroke_image, id}, m -> Keyword.put(m, :images, [id | Keyword.get(m, :images, [])])
      {:stroke_stream, id}, m -> Keyword.put(m, :streams, [id | Keyword.get(m, :streams, [])])
      {:draw_sprites, {id, _}}, m -> Keyword.put(m, :images, [id | Keyword.get(m, :images, [])])
      _, media -> media
    end)
    |> Enum.map(fn {k, v} -> {k, Enum.uniq(v)} end)
  end
end
