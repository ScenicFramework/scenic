#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.Dynamic do
  @moduledoc """
  Fill a primitive with an image from Scenic.Cache.Dynamic.Texture

  ## Full Format

  Dynamic paint accepts several variations. In each case, the `key` is a key referencing
  an image that has been loaded into Scenic.Cache.Dynamic.Texture.

  * `{:dynamic, key}` - Show the full image
  * `{:dynamic, {key, alpha}}` - Show the full image with transparency
  * `{:dynamic, {key, start_x, start_y, end_x, end_y, angle, alpha}}`
  """

  # --------------------------------------------------------
  @doc false
  def normalize(image) when is_bitstring(image) do
    normalize({image, 0, 0, 0, 0, 0, 0xFF})
  end

  def normalize({image, alpha}) do
    normalize({image, 0, 0, 0, 0, 0, alpha})
  end

  def normalize({image, ox, oy, ex, ey, angle, alpha})
      when is_number(ox) and is_number(oy) and is_number(ex) and is_number(ey) and
             is_bitstring(image) and is_number(angle) and is_number(alpha) and alpha >= 0 and
             alpha <= 0xFF do
    {image, ox, oy, ex, ey, angle, alpha}
  end
end
