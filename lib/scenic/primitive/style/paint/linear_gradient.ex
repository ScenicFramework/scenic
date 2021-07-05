#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.LinearGradient do
  @moduledoc """
  Fill a primitive with a linear gradient between two colors

  ## Format

  `{:linear, {start_x, start_y, end_x, end_y, color_start, color_end}}`

  This example fills with a smooth linear gradient that goes from blue in the upper left
  corner of the rect to yellow in the lower right corner.

  ```elixir
  Graph.build()
    |> rect({100, 50}, fill: {:linear, {0, 0, 100, 50, :blue, :yellow}})
  ```
  """

  alias Scenic.Primitive.Style.Paint.Color

  def validate({:linear, {sx, sy, ex, ey, color_start, color_end}})
      when is_number(sx) and is_number(sy) and is_number(ex) and is_number(ey) do
    with {:ok, color_start} <- Color.validate(color_start),
         {:ok, color_end} <- Color.validate(color_end) do
      {:ok, {:linear, {sx, sy, ex, ey, color_start, color_end}}}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def validate(_), do: err_invalid()

  defp err_invalid() do
    {
      :error,
      """
      #{IO.ANSI.yellow()}
      LinearGradient is specified in the form of
      {:linear, {start_x, start_y, end_x, end_y, color_start, color_end}}

      start_x, start_y, end_x, and end_y are all numbers representing positions.
      color_start and color_end must be valid color specifications.#{IO.ANSI.default_color()}
      """
    }
  end
end
