#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.MiterLimit do
  use Scenic.Primitive.Style

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a number greater than 0
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  # named color

  def verify(stroke) do
    try do
      normalize(stroke)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  def normalize(limit) when is_number(limit) and limit > 0, do: limit
end
