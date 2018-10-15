#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.LinearGradient do
  @moduledoc """
  Fill a primitive with a linear gradient

  ## Full Format

  `{:linear_gradient, {start_x, start_y, end_x, end_y, color_start, color_end}}`
  """

  alias Scenic.Primitive.Style.Paint.Color

  # --------------------------------------------------------
  @doc false
  def normalize({sx, sy, ex, ey, color_start, color_end})
      when is_number(sx) and is_number(sy) and is_number(ex) and is_number(ey) do
    {
      sx,
      sy,
      ex,
      ey,
      Color.normalize(color_start),
      Color.normalize(color_end)
    }
  end
end
