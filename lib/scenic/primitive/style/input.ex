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
    |> rect( {100, 200}, id: :my_rect, input: :cursor_button )
  ```

  ### Data Format

  The data for the input style is the type of input you want to receive when the cursor
  is positioned over the primitive. This can be any single member or combination (in a list)
  of the following input types

  * `:cursor_button` - Went when a button on the cursor (mouse) was used.
  * `:cursor_pos` - Sent when the cursor moves over the primitive.
  * `:cursor_scroll` - Sent when the cursor's scroll wheel moves.


  ```elixir
  graph
    |> rect( {100, 200}, id: :my_rect, input: [:cursor_button, :cursor_pos] )
  ```
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
