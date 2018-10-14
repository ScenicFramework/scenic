#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Cap do
  @moduledoc """
  Set how to draw the end of a line.

  Example:

      graph
      |> line({{0,0}, {100,100}}, cap: :round)

  ## Data
  * `:butt` - End of the line is flat, passing through the end point.
  * `:round` - End of the line is round, radiating from the end point.
  * `:square` - End of the line is flat, but projecting a square around the end point.
  """

  use Scenic.Primitive.Style

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be one of :butt, :round, :square
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  # named color
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
  def normalize(:butt), do: :butt
  def normalize(:round), do: :round
  def normalize(:square), do: :square
end
