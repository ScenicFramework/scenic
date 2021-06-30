#
#  Created by Boyd Multerer on June 5, 2018.2017-05-06.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Triangle do
  @moduledoc """
  Draw a triangle on the screen.

  ## Data

  `{point_a, point_b, point_c}`

  The data for a line is a tuple containing three points.
  * `point_a` - position to start drawing from
  * `point_b` - position to draw to
  * `point_c` - position to draw to

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.
  * [`join`](Scenic.Primitive.Style.Join.html) - control how segments are joined.
  * [`miter_limit`](Scenic.Primitive.Style.MiterLimit.html) - control how segments are joined.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#text/3)
  """

  use Scenic.Primitive
  alias Scenic.Math
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  @type t ::
          {{x0 :: number, y0 :: number}, {x1 :: number, y1 :: number},
           {x2 :: number, y2 :: number}}
  @type styles_t :: [:hidden | :fill | :stroke_width | :stroke_fill | :join | :miter_limit]

  @styles [:hidden, :fill, :stroke_width, :stroke_fill, :join, :miter_limit]

  @impl Primitive
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate({{x0, y0}, {x1, y1}, {x2, y2}} = data)
      when is_number(x0) and is_number(y0) and
             is_number(x1) and is_number(y1) and
             is_number(x2) and is_number(y2) do
    {:ok, data}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Triangle specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a Triangle is {{x0, y0}, {x1, y1}, {x2, y2}}
      Each x/y pair represents a corner in the Triangle.#{IO.ANSI.default_color()}
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
  @spec compile(primitive :: Primitive.t(), styles :: Style.m()) :: Script.t()
  @impl Primitive
  def compile(%Primitive{module: __MODULE__, data: {{x0, y0}, {x1, y1}, {x2, y2}}}, styles) do
    Script.draw_triangle([], x0, y0, x1, y1, x2, y2, Script.draw_flag(styles))
  end

  # --------------------------------------------------------
  def default_pin(data), do: centroid(data)

  # --------------------------------------------------------
  @doc """
  Returns the centroid of the triangle. This is used as the default pin when applying
  rotate or scale transforms.
  """
  def centroid(data)

  def centroid({{x0, y0}, {x1, y1}, {x2, y2}}) do
    {
      (x0 + x1 + x2) / 3,
      (y0 + y1 + y2) / 3
    }
  end

  # http://blackpawn.com/texts/pointinpoly/
  # --------------------------------------------------------
  @degenerate 0.0001
  def contains_point?({{x0, y0} = p0, {x1, y1} = p1, {x2, y2} = p2}, px) do
    # make sure the points are not collinear, if so the abs(area) will be very small
    area = abs(x0 * (y1 - y2) + x1 * (y2 - y0) + x2 * (y0 - y1))

    if area < @degenerate do
      false
    else
      # compute vectors
      v0 = Math.Vector2.sub(p2, p0)
      v1 = Math.Vector2.sub(p1, p0)
      v2 = Math.Vector2.sub(px, p0)

      # compute dot products
      dot00 = Math.Vector2.dot(v0, v0)
      dot01 = Math.Vector2.dot(v0, v1)
      dot02 = Math.Vector2.dot(v0, v2)
      dot11 = Math.Vector2.dot(v1, v1)
      dot12 = Math.Vector2.dot(v1, v2)

      # Compute barycentric coordinates
      inv_denom = 1.0 / (dot00 * dot11 - dot01 * dot01)
      u = (dot11 * dot02 - dot01 * dot12) * inv_denom
      v = (dot00 * dot12 - dot01 * dot02) * inv_denom

      # Check if point is in triangle
      u >= 0 && v >= 0 && u + v < 1
    end
  end
end
