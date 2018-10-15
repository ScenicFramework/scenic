#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.RadialGradient do
  @moduledoc """
  Fill a primitive with a radial gradient

  ## Full Format

  `{:radial_gradient, {center_x, center_y, inner_radius, outer_radius, color_start, color_end}}`
  """

  alias Scenic.Primitive.Style.Paint.Color

  # --------------------------------------------------------
  @doc false
  def normalize({cx, cy, inner_radius, outer_radius, color_start, color_end})
      when is_number(cx) and is_number(cy) and is_number(inner_radius) and is_number(outer_radius) do
    {
      cx,
      cy,
      inner_radius,
      outer_radius,
      Color.normalize(color_start),
      Color.normalize(color_end)
    }
  end
end
