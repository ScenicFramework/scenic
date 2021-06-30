#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.RadialGradient do
  @moduledoc """
  Fill a primitive with a radial gradient

  ## Full Format

  `{:radial, {center_x, center_y, inner_radius, outer_radius, color_start, color_end}}`
  """

  alias Scenic.Primitive.Style.Paint.Color

  # --------------------------------------------------------
  @doc false
  def validate({:radial, {cx, cy, i_r, o_r, color_start, color_end}})
  when is_number(cx) and is_number(cy) and is_number(i_r) and is_number(o_r) do
    with {:ok, color_start} <- Color.validate(color_start),
    {:ok, color_end} <- Color.validate(color_end) do
      {:ok, {:radial, {cx, cy, i_r, o_r, color_start, color_end}}}
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
      RadialGradient is specified in the form of
      {:radial, {center_x, center_y, inner_radius, outer_radius, color_start, color_end}}

      center_x and center_y are numbers representing the center of the gradient
      inner_radius and outer_radius are numbers representing the radii of the colors.
      color_start and color_end must be valid color specifications.#{IO.ANSI.default_color()}
      """
    }
  end



end
