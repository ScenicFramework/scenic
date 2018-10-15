#
#  Created by Boyd Multerer on 2017-10-02.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Rotate do
  @moduledoc """
  Apply a rotation matrix.

  Always rotates around the z-axis (coming out of the screen).

  The value is given in radians.

  Positive values rotate clockwise.

  The rotation is pinned to the sensible default for each primitive, or to the
  [`:pin`](Scenic.Primitive.Transform.Pin.html) that you assign explicitly.

  Example:
      graph
      |> text("Rotated!", rotate: 1.2)
      |> text("Rotated!", rotate: 1.2, pin: {10, 20})

  ## Shortcut

  Rotation is common enough that you can use `:r` as a shortcut.

  Example:
      graph
      |> text("Rotated!", r: 1.2)
  """
  use Scenic.Primitive.Transform

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a number
      #{IO.ANSI.yellow()}Received: #{inspect(data)}

      The value is the amount to rotate in radians

      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(angle) do
    normalize(angle)
    true
  rescue
    _ -> false
  end

  # --------------------------------------------------------
  @doc false
  @spec normalize(number()) :: number()
  def normalize(a) when is_number(a), do: a
end
