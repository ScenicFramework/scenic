#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Quad do
  @moduledoc """
  Draw a quad on the screen.

  ## Data

  `{point_a, point_b, point_c, point_d}`

  The data for a line is a tuple containing four points.
  * `point_a` - position to start drawing from
  * `point_b` - position to draw to
  * `point_c` - position to draw to
  * `point_d` - position to draw to

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.
  * [`join`](Scenic.Primitive.Style.Join.html) - control how segments are joined.
  * [`miter_limit`](Scenic.Primitive.Style.MiterLimit.html) - control how segments are joined.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#quad/3)

  ```elixir
  graph
    |> quad(
      {{10, 0}, {20, 40}, {17, 50}, 0, 10}},
      stroke: {1, :yellow}
    )
  ```
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Triangle

  @type t :: {
          {x0 :: number, y0 :: number},
          {x1 :: number, y1 :: number},
          {x2 :: number, y2 :: number},
          {x3 :: number, y3 :: number}
        }
  @type styles_t :: [
          :hidden | :scissor | :fill | :stroke_width | :stroke_fill | :join | :miter_limit
        ]

  @styles [:hidden, :scissor, :fill, :stroke_width, :stroke_fill, :join, :miter_limit]

  @impl Primitive
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate({{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}} = data)
      when is_number(x0) and is_number(y0) and is_number(x1) and is_number(y1) and
             is_number(x2) and is_number(y2) and is_number(x3) and is_number(y3) do
    {:ok, data}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Quad specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a Rectangle is {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}
      Each x/y pair represents a corner in the quad.#{IO.ANSI.default_color()}
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
  """
  @impl Primitive
  @spec compile(primitive :: Primitive.t(), styles :: Style.t()) :: Script.t()
  def compile(
        %Primitive{module: __MODULE__, data: {{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}},
        styles
      ) do
    Script.draw_quad([], x0, y0, x1, y1, x2, y2, x3, y3, Script.draw_flag(styles))
  end

  # --------------------------------------------------------
  def default_pin(data)

  def default_pin({{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}) do
    {
      (x0 + x1 + x2 + x3) / 4,
      (y0 + y1 + y2 + y3) / 4
    }
  end

  # # ------------------------------------
  # def expand({p0, p1, p2, p3}, width) do
  #   # account for the winding of quad - assumes convex, which is checked above
  #   cross =
  #     Math.Vector2.cross(
  #       Math.Vector2.sub(p1, p0),
  #       Math.Vector2.sub(p3, p0)
  #     )

  #   width =
  #     if cross < 0 do
  #       -width
  #     else
  #       width
  #     end

  #   # find the new parallel lines
  #   l01 = Math.Line.parallel({p0, p1}, width)
  #   l12 = Math.Line.parallel({p1, p2}, width)
  #   l23 = Math.Line.parallel({p2, p3}, width)
  #   l30 = Math.Line.parallel({p3, p0}, width)

  #   # calc the new poins from the intersections of the lines
  #   p0 = Math.Line.intersection(l30, l01)
  #   p1 = Math.Line.intersection(l01, l12)
  #   p2 = Math.Line.intersection(l12, l23)
  #   p3 = Math.Line.intersection(l23, l30)

  #   # return the expanded quad
  #   {p0, p1, p2, p3}
  # end

  # --------------------------------------------------------
  def contains_point?({p0, p1, p2, p3}, px) do
    # assumes convex, which is verified above
    Triangle.contains_point?({p0, p1, p2}, px) || Triangle.contains_point?({p1, p2, p3}, px)
  end

  # --------------------------------------------------------
  @doc false
  def default_pin({{x0, y0}, {x1, y1}, {x2, y2}, {x3, y3}}, _styles) do
    {
      (x0 + x1 + x2 + x3) / 4,
      (y0 + y1 + y2 + y3) / 4
    }
  end
end
