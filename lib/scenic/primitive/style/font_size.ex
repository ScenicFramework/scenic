#
#  Re-Created by Boyd Multerer on November 30, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontSize do
  use Scenic.Primitive.Style

  # import IEx

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a positive number >= 6
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(font) do
    try do
      normalize(font)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  def normalize(point_size) when is_number(point_size) and point_size >= 6 do
    point_size
  end
end
