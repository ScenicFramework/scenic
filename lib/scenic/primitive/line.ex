#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Line do
  @moduledoc """
  Draw a line on the screen.

  ## Data

  `{point_a, point_b}`

  The data for a line is a tuple containing two points.
  * `point_a` - position to start drawing from
  * `point_b` - position to draw to

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`scissor`](Scenic.Primitive.Style.Scissor.html) - "scissor rectangle" that drawing will be clipped to.
  * [`cap`](Scenic.Primitive.Style.Cap.html) - says how to draw the ends of the line.
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#line/3)

  ```elixir
  graph
    |> line( {{0, 0}, {20, 40}}, stroke: {1, :yellow} )
  ```
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  #  import IEx

  @type t :: {{x0 :: number, y0 :: number}, {x1 :: number, y1 :: number}}
  @type styles_t :: [:hidden | :scissor | :stroke_width | :stroke_fill | :cap]

  @styles [:hidden, :scissor, :stroke_width, :stroke_fill, :cap]

  @impl Primitive
  @spec validate(t()) ::
          {:ok, {{x0 :: number, y0 :: number}, {x1 :: number, y1 :: number}}}
          | {:error, String.t()}

  def validate({{x0, y0}, {x1, y1}} = data)
      when is_number(x0) and is_number(y0) and is_number(x1) and is_number(y1) do
    {:ok, data}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Line specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a Rectangle is {{x1,y1}, {x2,y2}}#{IO.ANSI.default_color()}
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
  def compile(%Primitive{module: __MODULE__, data: {{x0, y0}, {x1, y1}}}, %{stroke_fill: _}) do
    Script.draw_line([], x0, y0, x1, y1, :stroke)
  end

  def compile(%Primitive{module: __MODULE__}, _styles), do: []

  # ============================================================================

  # --------------------------------------------------------
  def default_pin(data), do: centroid(data)
  def default_pin(data, _styles), do: centroid(data)

  # --------------------------------------------------------
  @doc """
  Returns the midpoint of the line. This is used as the default pin when applying
  rotate or scale transforms.
  """
  def centroid(data)

  def centroid({{x0, y0}, {x1, y1}}) do
    {
      (x0 + x1) / 2,
      (y0 + y1) / 2
    }
  end

  # -----------------------------------------
  def bounds(data, mx, styles)

  def bounds({p0, p1}, <<_::binary-size(64)>> = mx, _styles) do
    [p0, p1]
    |> Scenic.Math.Vector2.project(mx)
    |> Scenic.Math.Vector2.bounds()
  end
end
