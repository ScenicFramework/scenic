#
#  Created by Boyd Multerer on 10/26/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#
# Line utility functions

defmodule Scenic.Math.Line do
  @moduledoc """
  A collection of functions to work with lines.

  Lines are always two points in a tuple.

        {point_a, point_b}
        {{x0,y0}, {x1,y1}}
  """

  alias Scenic.Math

  #  import IEx

  @app Mix.Project.config()[:app]
  # @env Mix.env

  # load the NIF
  @compile {:autoload, false}
  @on_load :load_nifs
  @doc false
  def load_nifs do
    :ok =
      :filename.join(:code.priv_dir(@app), 'line')
      |> :erlang.load_nif(0)
  end

  # --------------------------------------------------------
  @doc """
  Truncate the points that define a line so that they are made
  up of integers.

  Parameters:
  * line - A line defined by two points. {point_a, point_b}

  Returns:
  A line
  """
  @spec trunc(line :: Math.line()) :: Math.line()
  def trunc(line)

  def trunc({p0, p1}) do
    {
      Math.Vector2.trunc(p0),
      Math.Vector2.trunc(p1)
    }
  end

  # --------------------------------------------------------
  @doc """
  Round the points that define a line so that they are made
  up of integers.

  Parameters:
  * line - A line defined by two points. {point_a, point_b}

  Returns:
  A line
  """
  @spec round(line :: Math.line()) :: Math.line()
  def round(line)

  def round({p0, p1}) do
    {
      Math.Vector2.round(p0),
      Math.Vector2.round(p1)
    }
  end

  # --------------------------------------------------------
  @doc """
  Find a new line that is parallel to the given line and seperated
  by the given distance.

  Parameters:
  * line - A line defined by two points. {point_a, point_b}
  * distance - The perpendicular distance to the new line.

  Returns:
  A line
  """
  @spec parallel(line :: Math.line(), distance :: number) :: Math.line()
  def parallel(line, distance)

  def parallel({{x0, y0}, {x1, y1}}, w) do
    nif_parallel(x0, y0, x1, y1, w)
  end

  defp nif_parallel(_, _, _, _, _) do
    :erlang.nif_error("Did not find nif_parallel")
  end

  # --------------------------------------------------------
  @doc """
  Find the point of intersection between two lines.

  Parameters:
  * line_a - A line defined by two points. {point_a, point_b}
  * line_b - A line defined by two points. {point_a, point_b}

  Returns:
  A point
  """
  @spec intersection(line_a :: Math.line(), line_b :: Math.line()) :: Math.point()
  def intersection(line_a, line_b)

  def intersection({{x0, y0}, {x1, y1}}, {{x2, y2}, {x3, y3}}) do
    nif_intersection(x0, y0, x1, y1, x2, y2, x3, y3)
  end

  defp nif_intersection(_, _, _, _, _, _, _, _) do
    :erlang.nif_error("Did not find nif_intersection")
  end
end
