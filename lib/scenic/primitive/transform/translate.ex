#
#  Created by Boyd Multerer on 2017-10-03.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Translate do
  @moduledoc """
  Apply a translation matrix.

  This is used to position primitives on the screen

  `{x, y}` - move the primitive by the given amounts

  Example:
      graph
      |> text("Scaled!", translate: {10, 20})

  ## Shortcut

  Translating is common enough that you can use `:t` as a shortcut.

  Example:
      graph
      |> text("Scaled!", t: {10, 20})
  """

  use Scenic.Primitive.Transform

  # ============================================================================
  # data verification and serialization

  def validate({x, y}) when is_number(x) and is_number(y), do: {:ok, {x, y}}

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Translation
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :translate / :t option must be {x, y} #{IO.ANSI.default_color()}
      """
    }
  end
end
