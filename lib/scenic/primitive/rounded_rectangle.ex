#
#  Created by Boyd Multerer on 2017-05-08.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.RoundedRectangle do
  @moduledoc """
  Draw a rectangle with rounded corners on the screen.

  ## Data

  `{width, height, radius}`

  The data for a line is a tuple containing three numbers.
  * `width` - width of the rectangle
  * `height` - height of the rectangle
  * `radius` - radius of the corners

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#rounded_rectangle/3)
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
      #{IO.ANSI.red()}#{__MODULE__} data must be: {width, height, radius}
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      "Radius will be clamped to half of the smaller of width or height."
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
  def normalize({width, height, radius})
      when is_number(width) and is_number(height) and is_number(radius) and radius >= 0 do
    w = abs(width)
    h = abs(height)

    # clamp the radius
    radius =
      case w <= h do
        # width is smaller
        true -> min(radius, w / 2)
        # height is smaller
        false -> min(radius, h / 2)
      end

    {width, height, radius}
  end

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
  Returns a the centroid of the rectangle. This is used as the default pin when applying
  rotate or scale transforms.
  """
  def centroid(data)

  def centroid({width, height, _}) do
    {width / 2, height / 2}
  end

  # --------------------------------------------------------
  def contains_point?({w, h, r}, {xp, yp}) do
    # point in a rounded rectangle is the same problem as "is point within radius of the interior rectangle"
    # note also that point is in local space for primitive (presumably centered on the centroid)

    # so, somebody on SO solved a variant of the problem, so we'll adapt their work:
    # https://gamedev.stackexchange.com/a/44496

    # judging from the tests, it seems like the rectangle is meant to be tested in quadrant 1
    # and not centered about the origin as I'd originally thought

    if w * xp >= 0 and h * yp >= 0 do
      # since the sign of both x and y are the same, we do our math in abs land
      # spotted this trick from the rectangle code
      aw = abs(w)
      ah = abs(h)
      ax = abs(xp)
      ay = abs(yp)

      # get the dimensions and center of the "inner rectangle"
      # e.g., the one without the radii at the corners
      rw = aw - 2 * r
      rh = ah - 2 * r
      rx = r + rw / 2
      ry = r + rh / 2

      # calculate the distance of the point to the rectangle
      dx = max(abs(ax - rx) - rw / 2, 0)
      dy = max(abs(ay - ry) - rh / 2, 0)
      dx * dx + dy * dy <= r * r
    else
      false
    end
  end
end
