#
#  Created by Boyd Multerer on 2018-06-06.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Ellipse do
  @moduledoc """
  Draw an ellipse on the screen.

  ## Data

  `{radius_1, radius_2}`

  The data for an arc is a single number.
  * `radius_1` - the radius of the ellipse in one direction
  * `radius_2` - the radius of the ellipse in the other direction

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.

  Note: you can achieve the same effect with a Circle primitive
  by applying a `:scale` transform to it with unequal values on the axes

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#ellipse/3)

  ```elixir
  graph
    |> ellipse( {75, 100}, stroke: {1, :yellow} )
  ```
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  @type t :: {radius_1 :: number, radius_2 :: number}
  @type styles_t :: [:hidden | :scissor | :fill | :stroke_width | :stroke_fill]

  @styles [:hidden, :scissor, :fill, :stroke_width, :stroke_fill]

  @impl Primitive
  @spec validate({radius_1 :: number, radius_2 :: number}) ::
          {:ok, {radius_1 :: number, radius_2 :: number}} | {:error, String.t()}
  def validate({r1, r2})
      when is_number(r1) and is_number(r2) and
             r1 >= 0 and r2 >= 0 do
    {:ok, {r1, r2}}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Ellipse specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for an Arc is {radius_1, radius_2}
      The radii must be >= 0#{IO.ANSI.default_color()}
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
  def compile(%Primitive{module: __MODULE__, data: {radius_1, radius_2}}, styles) do
    Script.draw_ellipse([], radius_1, radius_2, Script.draw_flag(styles))
  end

  # --------------------------------------------------------
  def contains_point?({r1, r2}, {xp, yp}) do
    dx = xp * xp / (r1 * r1)
    dy = yp * yp / (r2 * r2)
    # test if less or equal to 1
    dx + dy <= 1
  end
end
