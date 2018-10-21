#
#  Created by Boyd Multerer on 2018-06-06.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
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

  `{radius, start, finish}`

  The data for an arc is a three-tuple.
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
  [`Scenic.Primitives`](Scenic.Primitives.html#arc/3)
  """

  use Scenic.Primitive
  alias Scenic.Primitive.Sector
  alias Scenic.Primitive.Triangle

  @styles [:hidden, :fill, :stroke]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be: {radius, start, finish}
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
  @spec valid_styles() :: [:fill | :hidden | :stroke]
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  def contains_point?({radius, start, finish} = data, pt) do
    # first, see if it is in the sector described by the arc data
    if Sector.contains_point?(data, pt) do
      # See if it is NOT in the triangle part of sector.
      # If it isn't in the triangle, then it must be in the arc part.
      p1 = {
        radius * :math.cos(start),
        radius * :math.sin(start)
      }

      p2 = {
        radius * :math.cos(finish),
        radius * :math.sin(finish)
      }

      !Triangle.contains_point?({{0, 0}, p1, p2}, pt)
    else
      false
    end
  end
end
