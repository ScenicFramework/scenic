#
#  Created by Boyd Multerer on 10/03/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Translate do
  use Scenic.Primitive.Transform

  # serialized pin is always a 3-tuple of integers.  {x, y, z}


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Transform :translate must be a 2d, or 3d vector {x,y} or {x,y,z}\n"

  #--------------------------------------------------------
  def verify( pin )
  def verify( {x,y} ) when is_number(x) and is_number(y), do: true
  def verify( {x,y,z} ) when is_number(x) and is_number(y) and is_number(z), do: true
  def verify( _ ), do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {x,y}, order ), do: serialize( {x,y, 0.0}, order )
  def serialize( {x,y,z}, :native ) do
    {:ok, <<
      x :: float-size(32)-native,
      y :: float-size(32)-native,
      z :: float-size(32)-native
    >>}
  end
  def serialize( {x,y,z}, :big ) do
    {:ok, <<
      x :: float-size(32)-big,
      y :: float-size(32)-big,
      z :: float-size(32)-big
    >>}
  end

  #--------------------------------------------------------
  def deserialize( mx, order \\ :native )

  def deserialize( <<
      x   :: float-size(32)-native,
      y   :: float-size(32)-native,
      0.0 :: float-size(32)-native,
      bin :: binary
    >>, :native
 ), do: {:ok, {x, y}, bin}
  def deserialize( <<
      x   :: float-size(32)-native,
      y   :: float-size(32)-native,
      z   :: float-size(32)-native,
      bin :: binary
    >>, :native
 ), do: {:ok, {x, y, z}, bin}


  def deserialize( <<
      x   :: float-size(32)-big,
      y   :: float-size(32)-big,
      0.0 :: float-size(32)-big,
      bin :: binary
    >>, :big
 ), do: {:ok, {x, y}, bin}
  def deserialize( <<
      x   :: float-size(32)-big,
      y   :: float-size(32)-big,
      z   :: float-size(32)-big,
      bin :: binary
    >>, :big
 ), do: {:ok, {x, y, z}, bin}

  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


end