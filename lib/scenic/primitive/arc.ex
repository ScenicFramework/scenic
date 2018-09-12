#
#  Created by Boyd Multerer on June 6, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Arc do
  use Scenic.Primitive
  alias Scenic.Primitive.Sector
  alias Scenic.Primitive.Triangle

  # alias Scenic.Primitive
  #  alias Scenic.Primitive.Style

  @styles [:hidden, :fill, :stroke]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be: {radius, start, finish}
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(data) do
    try do
      normalize(data)
      {:ok, data}
    rescue
      _ -> :invalid_data
    end
  end

  # --------------------------------------------------------
  def normalize({radius, start, finish} = data)
      when is_number(start) and is_number(finish) and is_number(radius),
      do: data

  # ============================================================================
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
