#
#  Created by Boyd Multerer on 2017-05-08.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Rectangle do
  @moduledoc """
  Draw a rectangle on the screen.

  ## Data

  `{width, height}`

  The data for a line is a tuple containing two numbers.
  * `width` - width of the rectangle
  * `height` - height of the rectangle

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.
  * [`join`](Scenic.Primitive.Style.Join.html) - control how segments are joined.
  * [`miter_limit`](Scenic.Primitive.Style.MiterLimit.html) - control how segments are joined.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#rectangle/3)
  """

  use Scenic.Primitive

  @styles [:hidden, :fill, :stroke, :join, :miter_limit]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be: {width, height}
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify({width, height} = data) when is_number(width) and is_number(height) do
    {:ok, data}
  end

  def verify(_), do: :invalid_data

  # ============================================================================
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @spec valid_styles() :: [:fill | :hidden | :stroke, ...]
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  def default_pin(data), do: centroid(data)

  # --------------------------------------------------------
  @doc """
  Returns the centroid of the rectangle. This is used as the default pin when applying
  rotate or scale transforms.
  """
  def centroid(data)

  def centroid({width, height}) do
    {width / 2, height / 2}
  end

  # --------------------------------------------------------
  def contains_point?({w, h}, {xp, yp}) do
    # width and xp must be the same sign
    # height and yp must be the same sign
    # xp must be less than the width
    # yp must be less than the height
    xp * w >= 0 && yp * h >= 0 && abs(xp) <= abs(w) && abs(yp) <= abs(h)
  end
end
