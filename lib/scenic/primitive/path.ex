#
#  Created by Boyd Multerer on 2018-06-05.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Path do
  @moduledoc """
  Draw a complex path on the screen described by a list of actions.

  ## Data

  `list_of_commands`

  The data for a path is a list of commands. They are interpreted in order
  when the path is drawn. See below for the commands it will accept.

  ## Styles

  This primitive recognizes the following styles
  * [`hidden`](Scenic.Primitive.Style.Hidden.html) - show or hide the primitive
  * [`fill`](Scenic.Primitive.Style.Fill.html) - fill in the area of the primitive
  * [`stroke`](Scenic.Primitive.Style.Stroke.html) - stroke the outline of the primitive. In this case, only the curvy part.
  * [`cap`](Scenic.Primitive.Style.Cap.html) - says how to draw the ends of the line.
  * [`join`](Scenic.Primitive.Style.Join.html) - control how segments are joined.
  * [`miter_limit`](Scenic.Primitive.Style.MiterLimit.html) - control how segments are joined.

  ## Commands

  * `:begin` - start a new path segment
  * `:close_path` - draw a line back to the start of the current segment
  * `:solid` - mark the current segment as something that will be filled
  * `:hole` - mark the current segment as something that cut out of other segments
  * `{:move_to, x, y}` - move the current draw position
  * `{:line_to, x, y}` - draw a line from the current position to a new location.
  * `{:bezier_to, c1x, c1y, c2x, c2y, x, y}` - draw a bezier curve from the current position to a new location.
  * `{:quadratic_to, cx, cy, x, y}` - draw a quadratic curve from the current position to a new location.
  * `{:arc_to, x1, y1, x2, y2, radius}` - draw an arc from the current position to a new location.

  ## Usage

  You should add/modify primitives via the helper functions in
  [`Scenic.Primitives`](Scenic.Primitives.html#line/3)
  """

  use Scenic.Primitive

  #  import IEx

  @styles [:hidden, :fill, :stroke, :cap, :join, :miter_limit]

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a list of actions. See docs.
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
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
  @doc """
  Returns a list of styles recognized by this primitive.
  """
  @spec valid_styles() :: [:fill | :hidden | :stroke, ...]
  def valid_styles(), do: @styles

  # ============================================================================
end
