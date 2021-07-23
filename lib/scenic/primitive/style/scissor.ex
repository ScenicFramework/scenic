#
#  Created by Boyd Multerer on 2018-06-06.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Scissor do
  @moduledoc """
  Define a "Scissor Rectangle" that drawing will be clipped to.

  Example:

  ```elixir
  graph
    |> triangle( {{0,40},{40,40},{40,0}}
      miter_limit: 2,
      fill: :green,
      scissor: {20, 40}
    )
  ```

  ### Data Format

  `{width, height}`

  * `width` - Width of the scissor rectangle.
  * `height` - Height of the scissor rectangle.
  """

  use Scenic.Primitive.Style

  # ============================================================================
  # data verification and serialization

  @doc false
  def validate({w, h}) when is_number(w) and is_number(h) do
    {:ok, {w, h}}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Scissor specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :scissor style must be {width, height}#{IO.ANSI.default_color()}
      """
    }
  end
end
