#
#  Created by Boyd Multerer on 6/4/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.LinearGradient do
  alias Scenic.Primitive.Style.Paint.Color

  #--------------------------------------------------------
  def normalize( {sx, sy, ex, ey, color_start, color_end} ) when
  is_number(sx) and is_number(sy) and is_number(ex) and is_number(ey) do
    {
      sx, sy, ex, ey,
      Color.normalize( color_start ),
      Color.normalize( color_end )
    }
  end

end