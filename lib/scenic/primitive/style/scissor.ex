#
#  Created by Boyd Multerer on 2018-06-06.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Scissor do
  @moduledoc """
  Define a "Scissor Rectangle" that drawing will be clipped to.

  Example:

      graph
      |> triangle( {{0,40},{40,40},{40,0}}
        miter_limit: 2,
        fill: :green,
        scissor: {20, 40}
      )

  ## Data

  `{width, height}`

  * `width` - Width of the scissor rectangle.
  * `height` - Height of the scissor rectangle.
  """

  use Scenic.Primitive.Style

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be {width, height}
      #{IO.ANSI.yellow()}Received: #{inspect(data)}

      "The scissor region will be positioned by the transform stack"

      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(data) do
    try do
      normalize(data)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  @doc false
  def normalize({w, h}) when is_number(w) and is_number(h) do
    {w, h}
  end
end
