#
#  Created by Boyd Multerer on 2021-02-11.
#  Copyright © 2021-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Input do
  @moduledoc """
  Flags whether or not track `cursor_button` events on this primitive.

  Example:

  ```elixir
  graph
    |> rect( {100, 200}, id: :my_rect, input: true )
  ```

  ### Data Format
  
  * `true` - Positional input is tested against this primitive
  * `false` - Input is not tested against this primitive. This is the default value.

  The `cusor_button` user input event is only sent to scenes have identified
  one or more primitives as input targets with the `:input` style.

  If you want your scene to receive all `cursor_button` events regardless of
  the `:input` style, then you need to call `capture_input/2` from your scene.
  This will, however, prevent any other scene's from receiving `cursor_button` on
  the primitives they have marked as `:input`.
  """

  use Scenic.Primitive.Style

  # ============================================================================

  @doc false
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
