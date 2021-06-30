#
#  Created by Boyd Multerer on June 5, 2018.2017-10-29.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Sector do
  @moduledoc """
  Draw an sector on the screen.

  An sector is a shape that looks like a piece of pie.

  ## Data

  `{radius, angle}`

  The data for an Sector is a tuple.
  * `radius` - the radius of the Sector
  * `angle` - the angle the Sector is swept through

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
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  # import IEx

  @type t :: {radius :: number, angle :: number}
  @type styles_t :: [:hidden | :fill | :stroke_width | :stroke_fill | :join | :miter_limit]

  @styles [:hidden, :fill, :stroke_width, :stroke_fill, :join, :miter_limit]

  @impl Primitive
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate({radius, angle}) when is_number(radius) and is_number(angle) do
    {:ok, {radius, angle}}
  end

  def validate({r, a1, a2} = old) when is_number(r) and is_number(a1) and is_number(a2) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Sector specification
      Received: #{inspect(old)}
      #{IO.ANSI.yellow()}
      The data for an Sector has changed and is now {radius, angle}

      The old format went from a start angle to an end angle. You can achieve
      the same thing with just a single angle and a rotate transform.#{IO.ANSI.default_color()}
      """
    }
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Sector specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for an Sector is {radius, angle}
      The radius must be >= 0#{IO.ANSI.default_color()}
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
  def compile(%Primitive{module: __MODULE__, data: {radius, angle}}, styles) do
    Script.draw_sector([], radius, angle, Script.draw_flag(styles))
  end

  # --------------------------------------------------------
  def contains_point?({radius, angle}, {xp, yp}) do
    # using polar coordinates...
    point_angle = :math.atan2(yp, xp)
    point_radius_sqr = xp * xp + yp * yp

    # calculate the sector radius for that angle. Not just a simple
    # radius check as h and k get muliplied in to make it a sector
    # of an ellipse. Gotta check that too
    sx = radius * :math.cos(point_angle)
    sy = radius * :math.sin(point_angle)
    sector_radius_sqr = sx * sx + sy * sy

    if 0 <= angle do
      # clockwise winding
      point_angle >= 0 && point_angle <= angle && point_radius_sqr <= sector_radius_sqr
    else
      # counter-clockwise winding
      point_angle <= 0 && point_angle >= angle && point_radius_sqr <= sector_radius_sqr
    end
  end
end
