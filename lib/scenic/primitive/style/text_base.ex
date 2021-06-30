#
#  Created by Boyd Multerer on 2021-02-05.
#  Copyright © 2021-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextBase do
  @moduledoc """
  Set the vertical alignment of text.

  :alphabetic is the default

  Example:

      graph
      |> text( "Some Text", text_base: :alphabetic )

  ## Data

  `alignment`

  The alignment type can be any one of the following

  * `:top` - The text baseline is the top of the em square.
  * `:hanging` - The text baseline is the hanging baseline.
  * `:middle` - The text baseline is the middle of the em square.
  * `:alphabetic` - The text baseline is the normal alphabetic baseline.
  * `:ideographic` - The text baseline is the ideographic baseline.
  * `:bottom` - The text baseline is the bottom of the bounding box.
  """

  use Scenic.Primitive.Style
  #  alias Scenic.Primitive.Style

  #  @dflag            Style.dflag()
  #  @type_code        0x0020

  # ============================================================================
  # data verification and serialization

  def validate(:top), do: {:ok, :top}
  def validate(:middle), do: {:ok, :middle}
  def validate(:alphabetic), do: {:ok, :alphabetic}
  def validate(:bottom), do: {:ok, :bottom}

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid TextBase specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :text_base style must be one of :top, :middle, :alphabetic, or :bottom

      The default is :alphabetic, which is common in typography.#{IO.ANSI.default_color()}
      """
    }
  end
end
