#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Scale do
  use Scenic.Primitive.Transform

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Transform :rotate must conform to the documentation\n"

  #--------------------------------------------------------
  def verify( percent )
  def verify( pz ) when is_number(pz), do: true         # rotate z axis - no pin
  def verify( {px,py,pz} ) when is_number(px) and is_number(py) and is_number(pz), do: true
  def verify( _ ), do: false

end