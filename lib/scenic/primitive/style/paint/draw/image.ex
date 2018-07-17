#
#  Created by Boyd Multerer on 6/4/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Paint.Image do

  #--------------------------------------------------------
  def normalize( image ) when is_bitstring(image) do
    normalize( { image, 0, 0, 0, 0, 0, 0xff } )
  end

  def normalize( {image, alpha} ) do
    normalize( { image, 0, 0, 0, 0, 0, alpha } )
  end

  def normalize( {image, ox, oy, ex, ey, angle, alpha} ) when
  is_number(ox) and is_number(oy) and is_number(ex) and is_number(ey) and
  is_bitstring(image) and is_number(angle) and is_number(alpha) and
  alpha >= 0 and alpha <= 0xff do
    { image, ox, oy, ex, ey, angle, alpha }
  end

end