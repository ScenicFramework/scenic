#
#  Created by Boyd Multerer on 2021-02-05.
#  Copyright © 2021-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextBase do
  @moduledoc """
  Set the vertical alignment of text.

  Example:

  ```elixir
  graph
    |> text( "Some Text", text_base: :alphabetic )
  ```

  ### Data Format

  TextBase can be any one of the following values

  * `:top` - The top of the em square.
  * `:middle` - The middle of the em square.
  * `:alphabetic` - The normal alphabetic baseline.
  * `:bottom` - The bottom of the bounding box.

  The default if `:text_base` is undefined is `:alphabetic`.

  The alphabetic baseline is at the bottom of characters such as "a", but above the
  bottom of characters with descending tails, such as "g" or "y". This the standard
  baseline from the world of typography. It may be unintuitive if you expected it
  to be at the top of the characters, like most of the primitives in Scenic.
  If that is what you want, then set `:text_base` to `:top`
  """

  use Scenic.Primitive.Style

  # ============================================================================
  # data verification and serialization

  @doc false
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
