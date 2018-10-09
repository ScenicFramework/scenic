#
#  Created by Boyd Multerer on 2017-10-02.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Scale do
  @moduledoc false

  use Scenic.Primitive.Transform

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(), do: "Transform :scale must conform to the documentation\n"

  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be either a single number or a vector
      #{IO.ANSI.yellow()}Received: #{inspect(data)}

      If you supply a single number, then scale is that percentage on both the X and Y axes.

      If you supply a vector {px, py}, the scale is different on the two axes.

      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(percent) do
    normalize(percent)
    true
  rescue
    _ -> false
  end

  # --------------------------------------------------------
  @spec normalize(number() | {number(), number()}) :: {number(), number()}
  def normalize(pct) when is_number(pct), do: {pct, pct}
  def normalize({px, py}) when is_number(px) and is_number(py), do: {px, py}
end
