#
#  Created by Boyd Multerer on 2018-06-05.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
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
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#circle/3)
  """

  use Scenic.Primitive

  @styles [:hidden, :fill, :stroke]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be: radius
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
  @spec normalize(number()) :: number()
  def normalize(radius) when is_number(radius) do
    radius
  end

  # ============================================================================
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @spec valid_styles() :: [:hidden | :fill | :stroke]
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  def contains_point?(radius, {xp, yp}) do
    # calc the distance squared fromthe pont to the center
    d_sqr = xp * xp + yp * yp
    # test if less or equal to radius squared
    d_sqr <= radius * radius
  end
end
