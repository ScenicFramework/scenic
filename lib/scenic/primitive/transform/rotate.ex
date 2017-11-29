#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Rotate do
  use Scenic.Primitive.Transform


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Transform :rotate must conform to the documentation\n"

  #--------------------------------------------------------
  def verify( rotation )
  def verify( rz ) when is_number(rz), do: true         # rotate z axis - no pin
  def verify( {rx,ry,rz} ) when is_number(rx) and is_number(ry) and is_number(rz), do: true
  def verify( _ ), do: false


end
