#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Text do
  @moduledoc false

  use Scenic.Primitive

  @styles [:hidden, :fill, :font, :font_size, :font_blur, :text_align, :text_height]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a bitstring
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @spec verify(any()) :: :invalid_data | {:ok, bitstring()}
  def verify(text) when is_bitstring(text), do: {:ok, text}
  def verify(_), do: :invalid_data

  # ============================================================================
  @spec valid_styles() :: [
          :fill | :font | :font_blur | :font_size | :hidden | :text_align | :text_height,
          ...
        ]
  def valid_styles(), do: @styles
end
