#
#  Created by Boyd Multerer on 2017-10-03.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Translate do
  @moduledoc false

  use Scenic.Primitive.Transform

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a 2d vector: {x,y}
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
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
  @spec normalize({number(), number()}) :: {number(), number()}
  def normalize({x, y}) when is_number(x) and is_number(y), do: {x, y}
end
