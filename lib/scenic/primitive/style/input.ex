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
  alias Scenic.ViewPort

  # ============================================================================

  @doc false
  def validate(input_type) when is_atom(input_type), do: validate([input_type])

  def validate(input_types) when is_list(input_types) do
    valid_types = ViewPort.Input.positional_inputs()
    inputs = Enum.uniq(input_types)

    Enum.all?(inputs, &Enum.member?(valid_types, &1))
    |> case do
      true -> {:ok, inputs}
      false -> invalid_types(input_types)
    end
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Input specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :input style must be any of #{inspect(ViewPort.Input.positional_inputs())}
      or a list containing any combination of those input types.#{IO.ANSI.default_color()}
      """
    }
  end

  defp invalid_types(input_types) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Input specification
      Received: #{inspect(input_types)}
      #{IO.ANSI.yellow()}
      The :input style must be any of #{inspect(ViewPort.Input.positional_inputs())}
      or a list containing any combination of those input types.#{IO.ANSI.default_color()}
      """
    }
  end
end
