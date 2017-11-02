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

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( rz, order ) when is_number(rz), do: serialize( {0.0,0.0,rz}, order )

  def serialize( {rx,ry,rz}, :native ) do
    {:ok, <<
      rx :: float-size(32)-native,
      ry :: float-size(32)-native,
      rz :: float-size(32)-native,
    >>}
  end
  def serialize( {rx,ry,rz}, :big ) do
    {:ok, <<
      rx :: float-size(32)-big,
      ry :: float-size(32)-big,
      rz :: float-size(32)-big,
    >>}
  end

  #--------------------------------------------------------
  def deserialize( mx, order \\ :native )
  def deserialize( <<
      rx :: float-size(32)-native,
      ry :: float-size(32)-native,
      rz :: float-size(32)-native,
      bin :: binary
    >>, :native ),  do: {:ok, {rx,ry,rz}, bin}
  def deserialize( <<
      rx :: float-size(32)-big,
      ry :: float-size(32)-big,
      rz :: float-size(32)-big,
      bin :: binary
    >>, :big ),     do: {:ok, {rx,ry,rz}, bin}

  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


end
