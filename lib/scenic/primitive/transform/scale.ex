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

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( pz, order ) when is_number(pz), do: serialize( {0.0,0.0,pz}, order )
  def serialize( {px,py,pz}, :native ) do
    {:ok, <<
      px :: float-size(32)-native,
      py :: float-size(32)-native,
      pz :: float-size(32)-native,
    >>}
  end
  def serialize( {px,py,pz}, :big ) do
    {:ok, <<
      px :: float-size(32)-big,
      py :: float-size(32)-big,
      pz :: float-size(32)-big,
    >>}
  end

  #--------------------------------------------------------
  def deserialize( mx, order \\ :native )
  def deserialize( <<
      px :: float-size(32)-native,
      py :: float-size(32)-native,
      pz :: float-size(32)-native,
      bin :: binary
    >>, :native ),  do: {:ok, {px,py,pz}, bin}
  def deserialize( <<
      px :: float-size(32)-big,
      py :: float-size(32)-big,
      pz :: float-size(32)-big,
      bin :: binary
    >>, :big ),     do: {:ok, {px,py,pz}, bin}

  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }

end