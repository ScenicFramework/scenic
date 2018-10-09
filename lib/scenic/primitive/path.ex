#
#  Created by Boyd Multerer on 2018-06-05.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Path do
  @moduledoc false

  use Scenic.Primitive

  #  import IEx

  @styles [:hidden, :fill, :stroke]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a list of actions. See docs.
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(actions) when is_list(actions) do
    actions
    |> Enum.all?(&verify_action(&1))
    |> case do
      true -> {:ok, actions}
      _ -> :invalid_data
    end
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  defp verify_action(action)

  defp verify_action(:begin), do: true
  defp verify_action(:close_path), do: true
  defp verify_action(:solid), do: true
  defp verify_action(:hole), do: true

  defp verify_action({:move_to, x, y})
       when is_number(x) and is_number(y),
       do: true

  defp verify_action({:line_to, x, y})
       when is_number(x) and is_number(y),
       do: true

  defp verify_action({:bezier_to, c1x, c1y, c2x, c2y, x, y})
       when is_number(c1x) and is_number(c1y) and is_number(c2x) and is_number(c2y) and
              is_number(x) and is_number(y),
       do: true

  defp verify_action({:quadratic_to, cx, cy, x, y})
       when is_number(cx) and is_number(cy) and is_number(x) and is_number(y),
       do: true

  defp verify_action({:arc_to, x1, y1, x2, y2, radius})
       when is_number(x1) and is_number(y1) and is_number(x2) and is_number(y2) and
              is_number(radius),
       do: true

  defp verify_action(_), do: false

  # ============================================================================
  @spec valid_styles() :: [:fill | :hidden | :stroke, ...]
  def valid_styles(), do: @styles

  # ============================================================================
end
