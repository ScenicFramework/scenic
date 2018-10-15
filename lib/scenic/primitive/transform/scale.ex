#
#  Created by Boyd Multerer on 2017-10-02.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Scale do
  @moduledoc """
  Apply a scale matrix.

  Increase or shrink by the provided multiplier. This can take two forms:

  * `multiplier` - scale both x and y directions by the same multiplier
  * `{mul_x, mul_y}` - scale x and y directions independently

  Scaling is pinned to the sensible default for each primitive, or to the
  [`:pin`](Scenic.Primitive.Transform.Pin.html) that you assign explicitly.

  Example:
      graph
      |> text("Scaled!", scale: 1.2)
      |> text("Scaled!", scale: {1.0, 1.2}, pin: {10, 20})

  ## Shortcut

  Scaling is common enough that you can use `:s` as a shortcut.

  Example:
      graph
      |> text("Scaled!", s: 1.2)
  """
  use Scenic.Primitive.Transform

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be either a single number or a vector
      #{IO.ANSI.yellow()}Received: #{inspect(data)}

      If you supply a single number, then scale is that percentage on both the X and Y axes.

      If you supply a vector {px, py}, the scale is different on the two axes.

      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(percent) do
    normalize(percent)
    true
  rescue
    _ -> false
  end

  # --------------------------------------------------------
  @doc false
  @spec normalize(number() | {number(), number()}) :: {number(), number()}
  def normalize(pct) when is_number(pct), do: {pct, pct}
  def normalize({px, py}) when is_number(px) and is_number(py), do: {px, py}
end
