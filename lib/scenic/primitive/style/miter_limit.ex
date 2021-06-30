#
#  Created by Boyd Multerer on 2017-05-12.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.MiterLimit do
  @moduledoc """
  Automatically miter joints if they are too sharp.

  Example:

      graph
      |> triangle( {{0,40},{40,40},{40,0}}
        miter_limit: 2,
        stroke: {2, :green}
      )

  ## Data

  A number greater than zero.
  """

  use Scenic.Primitive.Style

  # ============================================================================
  # data verification and serialization

  def validate(size) when is_number(size) and size > 0, do: {:ok, size}

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid MiterLimit specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :miter_limit style must be a positive number#{IO.ANSI.default_color()}
      """
    }
  end
end
