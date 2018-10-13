#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Text do
  @moduledoc """
  Draw text on the screen.

  ## Data

  `text`

  The data for a Text primitive is a bitstring
  * `text` - the text to draw

  ## Styles

  This primitive recognizes the following styles
  * `hidden` - show or hide the primitive
  * `fill` - fill in the area of the primitive - only accepts solid colors...
  * `font` - name (or key) of font to use
  * `font_size` - point size of the font
  * `font_blur` - option to blur the characters
  * `text_align` - alignment of lines of text
  * `text_height` - spacing between lines of text
  """

  use Scenic.Primitive

  @styles [:hidden, :fill, :font, :font_size, :font_blur, :text_align, :text_height]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a bitstring
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  @spec verify(any()) :: :invalid_data | {:ok, bitstring()}
  def verify(text) when is_bitstring(text), do: {:ok, text}
  def verify(_), do: :invalid_data

  # ============================================================================
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @spec valid_styles() :: [
          :fill | :font | :font_blur | :font_size | :hidden | :text_align | :text_height,
          ...
        ]
  def valid_styles(), do: @styles
end
