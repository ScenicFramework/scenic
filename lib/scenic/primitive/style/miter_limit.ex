#
#  Created by Boyd Multerer on 2017-05-12.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.MiterLimit do
  @moduledoc """
  Automatically miter joints if they are too sharp.

  Example:

      graph
      |> triangle( {{0,40},{40,40},{40,0}}
        miter_limit: 2,
        stroke: {2, :green}
      )

  ## Data

  A number greater than zero.
  """

  use Scenic.Primitive.Style

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a number greater than 0
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(stroke) do
    try do
      normalize(stroke)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  @doc false
  def normalize(limit) when is_number(limit) and limit > 0, do: limit
end
