#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Transform.Matrix do
  use Scenic.Primitive.Transform
#  alias Scenic.Primitive.Style

#  @dflag            Style.dflag()
#  @type_code        0x0020

  @matrix_byte_size   16 * 4


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Transform :matrix must be a either a binary containing 16 32-bit floats\n" <>
    "Please use the Scenic.Math.MatrixBin module for this."

  #--------------------------------------------------------
  def verify( <<_ :: binary-size(@matrix_byte_size) >> ), do: true
  def verify( _ ), do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( <<mx :: binary-size(@matrix_byte_size) >>, :native), do: mx
  def serialize( <<
      a00 :: float-size(32)-native,
      a10 :: float-size(32)-native,
      a20 :: float-size(32)-native,
      a30 :: float-size(32)-native,

      a01 :: float-size(32)-native,
      a11 :: float-size(32)-native,
      a21 :: float-size(32)-native,
      a31 :: float-size(32)-native,

      a02 :: float-size(32)-native,
      a12 :: float-size(32)-native,
      a22 :: float-size(32)-native,
      a32 :: float-size(32)-native,

      a03 :: float-size(32)-native,
      a13 :: float-size(32)-native,
      a23 :: float-size(32)-native,
      a33 :: float-size(32)-native
    >>, :big ) do
    <<
      a00 :: float-size(32)-big,
      a10 :: float-size(32)-big,
      a20 :: float-size(32)-big,
      a30 :: float-size(32)-big,

      a01 :: float-size(32)-big,
      a11 :: float-size(32)-big,
      a21 :: float-size(32)-big,
      a31 :: float-size(32)-big,

      a02 :: float-size(32)-big,
      a12 :: float-size(32)-big,
      a22 :: float-size(32)-big,
      a32 :: float-size(32)-big,

      a03 :: float-size(32)-big,
      a13 :: float-size(32)-big,
      a23 :: float-size(32)-big,
      a33 :: float-size(32)-big
    >>
  end
  #--------------------------------------------------------
  # binary format is row-major
#  def serialize({
#      {a00,a10,a20,a30},
#      {a01,a11,a21,a31},
#      {a02,a12,a22,a32},
#      {a03,a13,a23,a33}
#    }) do
#    <<
#      a00 :: float-size(32)-big,
#      a10 :: float-size(32)-big,
#      a20 :: float-size(32)-big,
#      a30 :: float-size(32)-big,
#
#      a01 :: float-size(32)-big,
#      a11 :: float-size(32)-big,
#      a21 :: float-size(32)-big,
#      a31 :: float-size(32)-big,
#
#      a02 :: float-size(32)-big,
#      a12 :: float-size(32)-big,
#      a22 :: float-size(32)-big,
#      a32 :: float-size(32)-big,
#
#      a03 :: float-size(32)-big,
#      a13 :: float-size(32)-big,
#      a23 :: float-size(32)-big,
#      a33 :: float-size(32)-big
#    >>
#  end

  #--------------------------------------------------------
  def deserialize( mx, order \\ :native )
  def deserialize( <<mx :: binary-size(@matrix_byte_size) >>, :native), do: mx
  def deserialize( <<
      a00 :: float-size(32)-big,
      a10 :: float-size(32)-big,
      a20 :: float-size(32)-big,
      a30 :: float-size(32)-big,

      a01 :: float-size(32)-big,
      a11 :: float-size(32)-big,
      a21 :: float-size(32)-big,
      a31 :: float-size(32)-big,

      a02 :: float-size(32)-big,
      a12 :: float-size(32)-big,
      a22 :: float-size(32)-big,
      a32 :: float-size(32)-big,

      a03 :: float-size(32)-big,
      a13 :: float-size(32)-big,
      a23 :: float-size(32)-big,
      a33 :: float-size(32)-big,
      bin   :: binary
    >>, :big ) do
    {
      <<
      a00 :: float-size(32)-native,
      a10 :: float-size(32)-native,
      a20 :: float-size(32)-native,
      a30 :: float-size(32)-native,

      a01 :: float-size(32)-native,
      a11 :: float-size(32)-native,
      a21 :: float-size(32)-native,
      a31 :: float-size(32)-native,

      a02 :: float-size(32)-native,
      a12 :: float-size(32)-native,
      a22 :: float-size(32)-native,
      a32 :: float-size(32)-native,

      a03 :: float-size(32)-native,
      a13 :: float-size(32)-native,
      a23 :: float-size(32)-native,
      a33 :: float-size(32)-native
      >>,
      bin
    }
  end

  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


end