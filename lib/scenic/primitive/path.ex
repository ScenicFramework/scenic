#
#  Created by Boyd Multerer on 2018-06-05.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Path do
  @moduledoc """
  Draw a complex path on the screen described by a list of actions.

  ## Data

  `list_of_commands`

  The data for a path is a list of commands. They are interpreted in order
  when the path is drawn. See below for the commands it will accept.

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.
  * [`cap`](Scenic.Primitive.Style.Cap.html) - says how to draw the ends of the line.
  * [`join`](Scenic.Primitive.Style.Join.html) - control how segments are joined.
  * [`miter_limit`](Scenic.Primitive.Style.MiterLimit.html) - control how segments are joined.

  ## Commands

  * `:begin` - start a new path segment
  * `:close_path` - draw a line back to the start of the current segment
  * `{:move_to, x, y}` - move the current draw position
  * `{:line_to, x, y}` - draw a line from the current position to a new location.
  * `{:bezier_to, c1x, c1y, c2x, c2y, x, y}` - draw a bezier curve from the current position to a new location.
  * `{:quadratic_to, cx, cy, x, y}` - draw a quadratic curve from the current position to a new location.
  * `{:arc_to, x1, y1, x2, y2, radius}` - draw an arc from the current position to a new location.

  ## `Path` vs. `Script`

  Both the `Path` and the `Script` primitives use the `Scenic.Script` to create scripts
  are sent to the drivers for drawing. The difference is that a Path is far more limited
  in what it can do, and is inserted inline with the compiled graph that created it.

  The script primitive, on the other hand, has full access to the API set of
  `Scenic.Script` and accesses scripts by reference.

  The inline vs. reference difference is important. A simple path will be consume
  fewer resources. BUT it will cause the entire graph to be recompile and resent
  to the drivers if you change it.

  A script primitive references a script that you create separately from the
  the graph. This means that any changes to the graph (such as an animation) will
  NOT need to recompile or resend the script.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#path/3)

  ```elixir
  graph
    |> path( [
        :begin,
        {:move_to, 0, 0},
        {:bezier_to, 0, 20, 0, 50, 40, 50},
        {:line_to, 30, 60},
        :close_path
      ],
      fill: :blue
    )
  ```
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  #  import IEx

  @type cmd ::
          :begin
          | :close_path
          | {:move_to, x :: number, y :: number}
          | {:line_to, x :: number, y :: number}
          | {:bezier_to, c1x :: number, c1y :: number, c2x :: number, c2y :: number, x :: number,
             y :: number}
          | {:quadratic_to, cx :: number, cy :: number, x :: number, y :: number}
          | {:arc_to, x1 :: number, y1 :: number, x2 :: number, y2 :: number, radius :: number}

  @type t :: [cmd]
  @type styles_t :: [:hidden | :fill | :stroke_width | :stroke_fill | :cap | :join | :miter_limit]

  @styles [:hidden, :fill, :stroke_width, :stroke_fill, :cap, :join, :miter_limit]

  @impl Primitive
  @spec validate(commands :: t()) :: {:ok, commands :: t()} | {:error, String.t()}
  def validate(commands) when is_list(commands) do
    Enum.reduce(commands, {:ok, commands}, fn
      _, {:error, error} ->
        {:error, error}

      :begin, ok ->
        ok

      :close_path, ok ->
        ok

      {:move_to, x, y}, ok when is_number(x) and is_number(y) ->
        ok

      {:line_to, x, y}, ok when is_number(x) and is_number(y) ->
        ok

      {:bezier_to, c1x, c1y, c2x, c2y, x, y}, ok
      when is_number(c1x) and is_number(c1y) and
             is_number(c2x) and is_number(c2y) and
             is_number(x) and is_number(y) ->
        ok

      {:quadratic_to, cx, cy, x, y}, ok
      when is_number(cx) and is_number(cy) and
             is_number(x) and is_number(y) ->
        ok

      {:arc_to, x1, y1, x2, y2, radius}, ok
      when is_number(x1) and is_number(y1) and
             is_number(x2) and is_number(y2) and is_number(radius) ->
        ok

      cmd, _ ->
        err_cmd(cmd, commands)
    end)
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Path specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      Path should be a list of operations from the following set:
        :begin
        :close_path
        {:move_to, x, y}
        {:line_to, x, y}
        {:bezier_to, c1x, c1y, c2x, c2y, x, y}
        {:quadratic_to, cx, cy, x, y}
        {:arc_to, x1, y1, x2, y2, radius}#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_cmd(:solid, commands) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Path specification
      Received: #{inspect(commands)}
      The :solid command is deprecated
      #{IO.ANSI.yellow()}
      Path should be a list of operations from the following set:
        :begin
        :close_path
        {:move_to, x, y}
        {:line_to, x, y}
        {:bezier_to, c1x, c1y, c2x, c2y, x, y}
        {:quadratic_to, cx, cy, x, y}
        {:arc_to, x1, y1, x2, y2, radius}#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_cmd(:hole, commands) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Path specification
      Received: #{inspect(commands)}
      The :hole command is deprecated
      #{IO.ANSI.yellow()}
      Path should be a list of operations from the following set:
        :begin
        :close_path
        {:move_to, x, y}
        {:line_to, x, y}
        {:bezier_to, c1x, c1y, c2x, c2y, x, y}
        {:quadratic_to, cx, cy, x, y}
        {:arc_to, x1, y1, x2, y2, radius}#{IO.ANSI.default_color()}
      """
    }
  end

  defp err_cmd(cmd, commands) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Path specification
      Received: #{inspect(commands)}
      The #{inspect(cmd)} operation is invalid
      #{IO.ANSI.yellow()}
      Path should be a list of operations from the following set:
        :begin
        :close_path
        {:move_to, x, y}
        {:line_to, x, y}
        {:bezier_to, c1x, c1y, c2x, c2y, x, y}
        {:quadratic_to, cx, cy, x, y}
        {:arc_to, x1, y1, x2, y2, radius}#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @impl Primitive
  @spec valid_styles() :: styles_t()
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  @doc """
  Compile the data for this primitive into a mini script. This can be combined with others to
  generate a larger script and is called when a graph is compiled.

  Note: Path is a "Meta" primitive. It isn't really a primitive that is represented in a
  draw script. Instead, it generates it's own mini-script, which is included inline to the
  graph it is contained in.

  Note: The compiled script is backwards. This is an inline script, which means
  it is inserted into a larger script as part of the graph compile process and
  Script.finish() will be called on that later.
  """
  @impl Primitive
  @spec compile(primitive :: Primitive.t(), styles :: Style.t()) :: Script.t()
  def compile(%Primitive{module: __MODULE__, data: commands}, styles) do
    ops =
      Enum.reduce(commands, [], fn
        :begin, acc ->
          Script.begin_path(acc)

        :close_path, acc ->
          Script.close_path(acc)

        {:move_to, x, y}, acc ->
          Script.move_to(acc, x, y)

        {:line_to, x, y}, acc ->
          Script.line_to(acc, x, y)

        {:bezier_to, c1x, c1y, c2x, c2y, x, y}, acc ->
          Script.bezier_to(acc, c1x, c1y, c2x, c2y, x, y)

        {:quadratic_to, cx, cy, x, y}, acc ->
          Script.quadratic_to(acc, cx, cy, x, y)

        {:arc_to, x1, y1, x2, y2, radius}, acc ->
          Script.arc_to(acc, x1, y1, x2, y2, radius)

        _, acc ->
          acc
      end)

    # finish by appending a fill/stroke command
    case Script.draw_flag(styles) do
      nil ->
        ops

      :fill ->
        Script.fill_path(ops)

      :stroke ->
        Script.stroke_path(ops)

      :fill_stroke ->
        ops
        |> Script.fill_path()
        |> Script.stroke_path()
    end
  end
end
