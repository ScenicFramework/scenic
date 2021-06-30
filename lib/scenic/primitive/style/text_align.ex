#
#  Created by Boyd Multerer on 2017-05-12.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextAlign do
  @moduledoc """
  Set the horizontal alignment of the text with regard to the start point.

  Example:

      graph
      |> text( "Some Text", text_align: :center_middle )

  ## Data

  `alignment`

  The alignment type can be any one of the following

  * `:left` - Left side horizontally. Base of the text vertically.
  * `:right` - Right side horizontally. Base of the text vertically.
  * `:center` - Centered horizontally. Base of the text vertically.
  """
  use Scenic.Primitive.Style
  #  alias Scenic.Primitive.Style

  #  @dflag            Style.dflag()
  #  @type_code        0x0020

  # ============================================================================
  # data verification and serialization

  def validate(:left), do: {:ok, :left}
  def validate(:center), do: {:ok, :center}
  def validate(:right), do: {:ok, :right}

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid TextAlign specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :text_align style must be one of :left, :center, or :right#{IO.ANSI.default_color()}
      """
    }
  end
end
