#
#  Re-Created by Boyd Multerer on 2017-11-30.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontBlur do
  @moduledoc """
  Apply a blur effect to text.

  Example:

      graph
      |> text("Blurry", font_blur: 2.0)

  ## Data

  Any number greater than or equal to zero.

  The higher the number, the more it blurs.
  """

  use Scenic.Primitive.Style

  # import IEx

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a positive number
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(blur) do
    try do
      normalize(blur)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  @doc false
  def normalize(blur) when is_number(blur) and blur >= 0 do
    blur
  end
end
