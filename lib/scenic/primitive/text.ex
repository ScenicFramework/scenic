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
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the text. Only solid colors!
  * [`font`](Scenic.Primitive.Style.Font.html) - name (or key) of font to use
  * [`font_size`](Scenic.Primitive.Style.FontSize.html) - point size of the font
  * [`font_blur`](Scenic.Primitive.Style.FontBlur.html) - option to blur the characters
  * [`text_align`](Scenic.Primitive.Style.TextAlign.html) - alignment of lines of text
  * [`text_height`](Scenic.Primitive.Style.TextHeight.html) - spacing between lines of text

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#text/3)
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
