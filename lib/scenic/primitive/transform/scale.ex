#
#  Created by Boyd Multerer on 2017-10-02.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Scale do
  @moduledoc """
  Apply a scale matrix.

  Increase or shrink by the provided multiplier. This can take two forms:

  * `multiplier` - scale both x and y directions by the same multiplier
  * `{mul_x, mul_y}` - scale x and y directions independently

  Scaling is pinned to the sensible default for each primitive, or to the
  [`:pin`](Scenic.Primitive.Transform.Pin.html) that you assign explicitly.

  Example:

  ```elixir
  graph
    |> text("Scaled!", scale: 1.2)
    |> text("Scaled!", scale: {1.0, 1.2}, pin: {10, 20})
  ```

  ### Shortcut

  Scaling is common enough that you can use `:s` as a shortcut.

  Example:
  ```elixir
  graph
    |> text("Scaled!", s: 1.2)
  ```
  """
  use Scenic.Primitive.Transform

  # ============================================================================
  # data verification and serialization

  def validate(s) when is_number(s), do: validate({s, s})

  def validate({x, y}) when is_number(x) and is_number(y) and x >= 0 and y >= 0 do
    {:ok, {x, y}}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Scale
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :scale / :s option must be a percentage or {x, y} percentages.
      These must be postitive nubmers#{IO.ANSI.default_color()}
      """
    }
  end
end
