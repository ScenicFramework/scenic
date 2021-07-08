#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
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

  ```elixir
  graph
    |> text( "Some example text", fill: :green, font: :roboto_mono, font_size: 64 )
  ```
  """

  use Scenic.Primitive
  alias Scenic.Script
  alias Scenic.Primitive
  alias Scenic.Primitive.Style

  @type t :: String.t()
  @type styles_t :: [
          :hidden | :font | :font_size | :line_height | :text_align | :text_base | :line_height
        ]

  @styles [:hidden, :font, :font_size, :line_height, :text_align, :text_base, :line_height]

  @impl Primitive
  @spec validate(text :: t()) :: {:ok, t()} | {:error, String.t()}
  def validate(text) when is_bitstring(text) do
    {:ok, text}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Text specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for Text must be a String#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @impl Primitive
  @spec valid_styles() :: styles_t()
  def valid_styles(), do: @styles

  # --------------------------------------------------------
  # compiling Text is a special case and is handled in Scenic.ViewPort.GraphCompiler
  @doc false
  @impl Primitive
  @spec compile(primitive :: Primitive.t(), styles :: Style.t()) :: Script.t()
  def compile(%Primitive{module: __MODULE__}, _styles) do
    raise "compiling Text is a special case and is handled in Scenic.ViewPort.GraphCompiler"
  end
end
