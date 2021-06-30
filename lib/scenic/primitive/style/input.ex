#
#  Created by Boyd Multerer on 2021-02-11.
#  Copyright © 2021-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Input do
  @moduledoc """
  Flags whether or not track positional input on this primitive.

  Example:

      graph
      |> rectangle({100, 200}, input: true)

  ## Data
  * `true` - Positional input is tested against this primitive
  * `false` - Input is not tested against this primitive. This is the default value.
  """

  use Scenic.Primitive.Style

  # ============================================================================

  def validate(true), do: {:ok, true}
  def validate(false), do: {:ok, false}

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Input specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :input style must be either true or false#{IO.ANSI.default_color()}
      """
    }
  end
end
