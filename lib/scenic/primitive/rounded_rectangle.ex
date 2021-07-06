#
#  Created by Boyd Multerer on 2017-05-08.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
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
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  # import IEx

  @type t :: {width :: number, height :: number, radius :: number}
  @type styles_t :: [:hidden | :fill | :stroke_width | :stroke_fill]

  @styles [:hidden, :fill, :stroke_width, :stroke_fill]

  @impl Primitive
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}

  def validate({width, height, radius})
      when is_number(width) and is_number(height) and is_number(radius) do
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

    {:ok, {width, height, radius}}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Rounded Rectangle specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a Rounded Rectangle is {height, width, radius}
      If you choose a radius that is larger than either the height or width,
      then it will be clamped to half of the smaller one.#{IO.ANSI.default_color()}
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
  def compile(%Primitive{module: __MODULE__, data: {width, height, radius}}, styles) do
    Script.draw_rounded_rectangle([], width, height, radius, Script.draw_flag(styles))
  end

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
