#
#  Re-Created by Boyd Multerer on 2017-11-30.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontSize do
  @moduledoc """
  The point-size to draw text in.

  Example:

  ```elixir
  graph
    |> text( "Small", font_size: 12.5 )
    |> text( "Large", font_size: 64 )
  ```

  ### Data Format

  Any number greater than or equal to 6.
  """

  use Scenic.Primitive.Style

  # import IEx

  # ============================================================================
  # data verification and serialization

  @doc false
  def validate(size) when is_number(size) and size > 0, do: {:ok, size}

  def validate(size) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid FontSize specification
      Received: #{inspect(size)}#{IO.ANSI.default_color()}
      #{IO.ANSI.yellow()}
      The :font_size style must be a positive number
      """
    }
  end
end
