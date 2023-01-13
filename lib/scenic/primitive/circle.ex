#
#  Created by Boyd Multerer on 2018-06-05.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Circle do
  @moduledoc """
  Draw a circle on the screen.

  ## Data

  `radius`

  The data for an arc is a single number.
  * `radius` - the radius of the arc

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`scissor`](Scenic.Primitive.Style.Scissor.html) - "scissor rectangle" that drawing will be clipped to.
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#circle/3)

  ```elixir
  graph
    |> circle( 100, stroke: {1, :yellow} )
  ```
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  @type t :: radius :: number
  @type styles_t :: [:hidden | :scissor | :fill | :stroke_width | :stroke_fill | :cap]

  @styles [:hidden, :scissor, :fill, :stroke_width, :stroke_fill]

  @impl Primitive
  @spec validate(t()) :: {:ok, radius :: number} | {:error, String.t()}
  def validate(radius)
      when is_number(radius) do
    {:ok, radius}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Circle specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for an Circle is radius.{IO.ANSI.default_color()}
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
  @spec compile(primitive :: Primitive.t(), styles :: Style.t()) :: Script.t()
  @impl Primitive
  def compile(%Primitive{module: __MODULE__, data: radius}, styles) do
    Script.draw_circle([], radius, Script.draw_flag(styles))
  end

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def contains_point?(radius, {xp, yp}) do
    # calc the distance squared fromthe pont to the center
    d_sqr = xp * xp + yp * yp
    # test if less or equal to radius squared
    d_sqr <= radius * radius
  end
end
