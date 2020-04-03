#
#  Created by Boyd Multerer on 2018-06-06.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
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
  by applying a :size transform to it with unequal values on the axes

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#ellipse/3)
  """

  use Scenic.Primitive

  @styles [:hidden, :fill, :stroke]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be: {radius_1, radius_2}
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(data) do
    normalize(data)
    {:ok, data}
  rescue
    _ -> :invalid_data
  end

  # --------------------------------------------------------
  @doc false
  @spec normalize({number(), number()}) :: {number(), number()}
  def normalize({r1, r2} = data) when is_number(r1) and is_number(r2) do
    data
  end

  # ============================================================================
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @spec valid_styles() :: [:fill | :hidden | :stroke, ...]
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  def contains_point?({r1, r2}, {xp, yp}) do
    dx = xp * xp / (r1 * r1)
    dy = yp * yp / (r2 * r2)
    # test if less or equal to 1
    dx + dy <= 1
  end
end
