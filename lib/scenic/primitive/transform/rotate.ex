#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Rotate do
  use Scenic.Primitive.Transform

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a number
      #{IO.ANSI.yellow()}Received: #{inspect(data)}

      The value is the amount to rotate in radians

      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(angle) do
    try do
      normalize(angle)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  # normalize named stipples
  def normalize(a) when is_number(a), do: a
end
