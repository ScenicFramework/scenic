#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.BoxGradient do
  @moduledoc """
  Fill a primitive with a box gradient

  ## Full Format

  `{:box_gradient, {x, y, width, height, feather, color_start, color_end}}`
  """

  alias Scenic.Primitive.Style.Paint.Color

  # --------------------------------------------------------
  @doc false
  def normalize({x, y, w, h, radius, feather, color_start, color_end})
      when is_number(x) and is_number(y) and is_number(w) and is_number(h) and is_number(radius) and
             is_number(feather) do
    {
      x,
      y,
      w,
      h,
      radius,
      feather,
      Color.normalize(color_start),
      Color.normalize(color_end)
    }
  end
end
