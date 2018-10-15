#
#  Re-Created by Boyd Multerer on 2017-11-30.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontSize do
  @moduledoc """
  The point-size to draw text in.

  Example:

      graph
      |> text("Small", font_size: 6)
      |> text("Large", font_size: 64)

  ## Data

  Any number greater than or equal to 6.
  """

  use Scenic.Primitive.Style

  # import IEx

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a positive number >= 6
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(font) do
    try do
      normalize(font)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  @doc false
  def normalize(point_size) when is_number(point_size) and point_size >= 6 do
    point_size
  end
end
