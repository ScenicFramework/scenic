#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Rotate do
  use Scenic.Primitive.Transform


  # rotate type codes
  @rot_z            1
  @rot_z_pin        2

  @rot_xyz          3
  @rot_xyz_pin      4

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Transform :rotate must conform to the documentation\n"

  #--------------------------------------------------------
  def verify( rotation )
  def verify( rz ) when is_number(rz), do: true         # rotate z axis - no pin
  def verify( {rz, nil} ) when is_number(rz), do: true  # rotate z axis - no pin
  def verify( {rz, {x,y}} ) when is_number(rz) and is_integer(x) and is_integer(y), do:
    true  # rotate z axis - with pin

  def verify( {{rx,ry,rz}, nil} ) when is_number(rx) and is_number(ry) and is_number(rz), do:
    true
  def verify( {{rx,ry,rz}, {x,y,z}} ) when is_number(rx) and is_number(ry) and is_number(rz) and
    is_integer(x) and is_integer(y) and is_integer(z), do:
    true

  def verify( _ ), do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( rz, :native ) when is_number(rz),         do: << @rot_z :: size(8), rz :: float-size(32)-native >>
  def serialize( {rz, nil}, :native ) when is_number(rz),  do: << @rot_z :: size(8), rz :: float-size(32)-native >>
  def serialize( {rz, {x,y}}, :native ) when is_number(rz) do
    <<
      @rot_z_pin :: size(8),
      rz :: float-size(32)-native,
      x  :: integer-size(16)-native,
      y  :: integer-size(16)-native
    >>
  end
  def serialize( {{rx,ry,rz}, nil}, :native ) do
    <<
      @rot_xyz :: size(8),
      rx :: float-size(32)-native,
      ry :: float-size(32)-native,
      rz :: float-size(32)-native,
    >>
  end
  def serialize( {{rx,ry,rz}, {x,y,z}}, :native ) do
    <<
      @rot_xyz_pin :: size(8),
      rx :: float-size(32)-native,
      ry :: float-size(32)-native,
      rz :: float-size(32)-native,
      x  :: integer-size(16)-native,
      y  :: integer-size(16)-native,
      z  :: integer-size(16)-native
    >>
  end

  def serialize( rz, :big ) when is_number(rz),         do: << @rot_z :: size(8), rz :: float-size(32)-big >>
  def serialize( {rz, nil}, :big ) when is_number(rz),  do: << @rot_z :: size(8), rz :: float-size(32)-big >>
  def serialize( {rz, {x,y}}, :big ) when is_number(rz) do
    <<
      @rot_z_pin :: size(8),
      rz :: float-size(32)-big,
      x  :: integer-size(16)-big,
      y  :: integer-size(16)-big
    >>
  end
  def serialize( {{rx,ry,rz}, nil}, :big ) do
    <<
      @rot_xyz :: size(8),
      rx :: float-size(32)-big,
      ry :: float-size(32)-big,
      rz :: float-size(32)-big,
    >>
  end
  def serialize( {{rx,ry,rz}, {x,y,z}}, :big ) do
    <<
      @rot_xyz_pin :: size(8),
      rx :: float-size(32)-big,
      ry :: float-size(32)-big,
      rz :: float-size(32)-big,
      x  :: integer-size(16)-big,
      y  :: integer-size(16)-big,
      z  :: integer-size(16)-big
    >>
  end


  #--------------------------------------------------------
  def deserialize( mx, order \\ :native )
  def deserialize( <<
      @rot_z :: size(8),
      rz  :: float-size(32)-native,
      bin :: binary
    >>, :native ), do: {{rz, nil}, bin}
  def deserialize( <<
      @rot_z :: size(8),
      rz  :: float-size(32)-native,
      x   :: integer-size(16)-native,
      y   :: integer-size(16)-native,
      bin :: binary
    >>, :native ), do: {{rz, {x,y}}, bin}
  def deserialize( <<
      @rot_xyz :: size(8),
      rx  :: float-size(32)-native,
      ry  :: float-size(32)-native,
      rz  :: float-size(32)-native,
      bin :: binary
    >>, :native ), do: {{{rx,ry,rz}, nil}, bin}
  def deserialize( <<
      @rot_xyz_pin :: size(8),
      rx  :: float-size(32)-native,
      ry  :: float-size(32)-native,
      rz  :: float-size(32)-native,
      x   :: integer-size(16)-native,
      y   :: integer-size(16)-native,
      z   :: integer-size(16)-native,
      bin :: binary
    >>, :native ), do: {{{rx,ry,rz}, {x,y,z}}, bin}
  
  def deserialize( <<
      @rot_z :: size(8),
      rz  :: float-size(32)-big,
      bin :: binary
    >>, :big ), do: {{rz, nil}, bin}
  def deserialize( <<
      @rot_z :: size(8),
      rz  :: float-size(32)-big,
      x   :: integer-size(16)-big,
      y   :: integer-size(16)-big,
      bin :: binary
    >>, :big ), do: {{rz, {x,y}}, bin}
  def deserialize( <<
      @rot_xyz :: size(8),
      rx  :: float-size(32)-big,
      ry  :: float-size(32)-big,
      rz  :: float-size(32)-big,
      bin :: binary
    >>, :big ), do: {{{rx,ry,rz}, nil}, bin}
  def deserialize( <<
      @rot_xyz_pin :: size(8),
      rx  :: float-size(32)-big,
      ry  :: float-size(32)-big,
      rz  :: float-size(32)-big,
      x   :: integer-size(16)-big,
      y   :: integer-size(16)-big,
      z   :: integer-size(16)-big,
      bin :: binary
    >>, :big ), do: {{{rx,ry,rz}, {x,y,z}}, bin}

  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


end