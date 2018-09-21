#
#  Created by Boyd Multerer on 6/4/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.RadialGradient do
  alias Scenic.Primitive.Style.Paint.Color

  # --------------------------------------------------------
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
