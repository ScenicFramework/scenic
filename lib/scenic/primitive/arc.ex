#
#  Created by Boyd Multerer on 2018-06-06.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Arc do
  @moduledoc """
  Draw an arc on the screen.

  An arc is a segment that traces part of the outline of a circle. If you are
  looking for something shaped like a piece of pie, then you want a segment.

  Arcs are often drawn on top of a segment to get an affect where a piece of pie
  is filled in, but only the curvy edge is stroked.

  Note that you can fill an arc, but that will result in a shape that looks
  like a potato wedge.

  ## Data

  `{radius, angle}`

  The data for an arc is a tuple.
  * `radius` - the radius of the arc
  * `angle` - the angle the arc is swept through


  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.  

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#arc/3)
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Sector
  alias Scenic.Primitive.Triangle

  @type t :: {radius :: number, angle :: number}
  @type styles_t :: [:hidden | :fill | :stroke_width | :stroke_fill | :cap]

  @styles [:hidden, :fill, :stroke_width, :stroke_fill, :cap]

  @impl Primitive
  @spec validate(t()) ::
          {:ok, {radius :: number, angle :: number}} | {:error, String.t()}

  def validate({radius, angle}) when is_number(radius) and is_number(angle) do
    {:ok, {radius, angle}}
  end

  def validate({r, a1, a2} = old) when is_number(r) and is_number(a1) and is_number(a2) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Arc specification
      Received: #{inspect(old)}
      #{IO.ANSI.yellow()}
      The data for an Arc has changed and is now {radius, angle}

      The old format went from a start angle to an end angle. You can achieve
      the same thing with just a single angle and a rotate transform.#{IO.ANSI.default_color()}
      """
    }
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Arc specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for an Arc is {radius, angle}
      The radius must be >= 0#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @spec valid_styles() :: styles_t()
  @impl Primitive
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  @doc """
  Compile the data for this primitive into a mini script. This can be combined with others to
  generate a larger script and is called when a graph is compiled.
  """
  @spec compile(primitive :: Primitive.t(), styles :: Style.t()) :: Script.t()
  @impl Primitive
  def compile(%Primitive{module: __MODULE__, data: {radius, angle}}, styles) do
    Script.draw_arc([], radius, angle, Script.draw_flag(styles))
  end

  # --------------------------------------------------------
  def contains_point?({radius, angle} = data, pt) do
    # first, see if it is in the sector described by the arc data
    if Sector.contains_point?(data, pt) do
      # See if it is NOT in the triangle part of sector.
      # If it isn't in the triangle, then it must be in the arc part.
      p1 = {radius, 0}

      p2 = {
        radius * :math.cos(angle),
        radius * :math.sin(angle)
      }

      !Triangle.contains_point?({{0, 0}, p1, p2}, pt)
    else
      false
    end
  end
end
