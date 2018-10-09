#
#  Created by Boyd Multerer on 2017-11-02.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Math.Quad do
  @moduledoc false

  alias Scenic.Math

  @type classification ::
          :concave
          | :convex
          | :complex

  # --------------------------------------------------------
  @doc """
  Find the classification of a given quad.

  Parameters:
  * quad - the quad to be classified

  Returns:
  On of :concave, :convex, or :complex
  """
  @spec classification(quad :: Math.quad()) :: classification
  def classification(quad)

  def classification({p0, p1, p2, p3}) do
    v0 = Math.Vector2.sub(p0, p1)
    v1 = Math.Vector2.sub(p1, p2)
    v2 = Math.Vector2.sub(p2, p3)
    v3 = Math.Vector2.sub(p3, p0)
    c0 = Math.Vector2.cross(v0, v1)
    c1 = Math.Vector2.cross(v1, v2)
    c2 = Math.Vector2.cross(v2, v3)
    c3 = Math.Vector2.cross(v3, v0)

    case num_positive([c0, c1, c2, c3]) do
      1 -> :concave
      2 -> :complex
      3 -> :concave
      4 -> :convex
    end
  end

  # --------------------------------------------------------
  defp num_positive(nums, pos \\ 0)
  defp num_positive([], pos), do: pos

  defp num_positive([num | tail], pos) do
    case num > 0 do
      true -> num_positive(tail, pos + 1)
      false -> num_positive(tail, pos)
    end
  end
end
