#
#  Created by Boyd Multerer on June 5, 2018.2017-10-29.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Sector do
  @moduledoc """
  Draw an sector on the screen.

  An sector is a shape that looks like a piece of pie.

  ## Data

  `{radius, start, finish}`

  The data for a sector is a three-tuple.
  * `radius` - the radius of the arc
  * `start` - the starting angle in radians
  * `finish` - end ending angle in radians

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#sector/3)
  """

  use Scenic.Primitive

  # import IEx

  @styles [:hidden, :fill, :stroke]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be: {radius, start_angle, end_angle}
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
  @spec normalize({number(), number(), number()}) :: {number(), number(), number()}
  def normalize({radius, start, finish} = data)
      when is_number(start) and is_number(finish) and is_number(radius),
      do: data

  # ============================================================================
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @spec valid_styles() :: [:fill | :hidden | :stroke, ...]
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  def contains_point?({radius, start, finish}, {xp, yp}) do
    # using polar coordinates...
    point_angle = :math.atan2(yp, xp)
    point_radius_sqr = xp * xp + yp * yp

    # calculate the sector radius for that angle. Not just a simple
    # radius check as h and k get muliplied in to make it a sector
    # of an ellipse. Gotta check that too
    sx = radius * :math.cos(point_angle)
    sy = radius * :math.sin(point_angle)
    sector_radius_sqr = sx * sx + sy * sy

    if start <= finish do
      # clockwise winding
      point_angle >= start && point_angle <= finish && point_radius_sqr <= sector_radius_sqr
    else
      # counter-clockwise winding
      point_angle <= start && point_angle >= finish && point_radius_sqr <= sector_radius_sqr
    end
  end
end
