#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Matrix do
  use Scenic.Primitive.Transform

  @matrix_byte_size   16 * 4

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Transform :matrix must be a binary containing 16 32-bit floats\n" <>
    "Please use the Scenic.Math.Matrix module for this."

  #--------------------------------------------------------
  def verify( <<_ :: binary-size(@matrix_byte_size) >> ), do: true
  def verify( _ ), do: false

end