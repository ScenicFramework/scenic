#
#  Created by Boyd Multerer on 2017-10-03.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
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

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a 2d vector: {x,y}
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(percent) do
    normalize(percent)
    true
  rescue
    _ -> false
  end

  # --------------------------------------------------------
  @doc false
  @spec normalize({number(), number()}) :: {number(), number()}
  def normalize({x, y}) when is_number(x) and is_number(y), do: {x, y}
end
