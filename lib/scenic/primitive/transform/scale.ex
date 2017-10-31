#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Transform.Scale do
  use Scenic.Primitive.Transform


  # rotate type codes
  @scale_pct          1
  @scale_pct_pin      2

  @scale_xyz          3
  @scale_xyz_pin      4


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Transform :rotate must conform to the documentation\n"

  #--------------------------------------------------------
  def verify( percent )
  def verify( pct ) when is_number(pct), do: true         # rotate z axis - no pin
  def verify( {pct, nil} ) when is_number(pct), do: true  # rotate z axis - no pin
  def verify( {pct, {x,y}} ) when is_number(pct) and is_integer(x) and is_integer(y), do:
    true  # rotate z axis - with pin

  def verify( {{px,py,pz}, nil} ) when is_number(px) and is_number(py) and is_number(pz), do:
    true
  def verify( {{px,py,pz}, {x,y,z}} ) when is_number(px) and is_number(py) and is_number(pz) and
    is_integer(x) and is_integer(y) and is_integer(z), do:
    true

  def verify( _ ), do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( pct, :native ) when is_number(pct),         do: << @scale_pct :: size(8), pct :: float-size(32)-native >>
  def serialize( {pct, nil}, :native ) when is_number(pct),  do: << @scale_pct :: size(8), pct :: float-size(32)-native >>
  def serialize( {pct, {x,y}}, :native ) when is_number(pct) do
    <<
      @scale_pct_pin :: size(8),
      pct :: float-size(32)-native,
      x  :: integer-size(16)-native,
      y  :: integer-size(16)-native
    >>
  end
  def serialize( {{px,py,pz}, nil}, :native ) do
    <<
      @scale_xyz :: size(8),
      px :: float-size(32)-native,
      py :: float-size(32)-native,
      pz :: float-size(32)-native,
    >>
  end
  def serialize( {{px,py,pz}, {x,y,z}}, :native ) do
    <<
      @scale_xyz_pin :: size(8),
      px :: float-size(32)-native,
      py :: float-size(32)-native,
      pz :: float-size(32)-native,
      x  :: integer-size(16)-native,
      y  :: integer-size(16)-native,
      z  :: integer-size(16)-native
    >>
  end

  def serialize( pct, :big ) when is_number(pct),         do: << @scale_pct :: size(8), pct :: float-size(32)-big >>
  def serialize( {pct, nil}, :big ) when is_number(pct),  do: << @scale_pct :: size(8), pct :: float-size(32)-big >>
  def serialize( {pct, {x,y}}, :big ) when is_number(pct) do
    <<
      @scale_pct_pin :: size(8),
      pct :: float-size(32)-big,
      x  :: integer-size(16)-big,
      y  :: integer-size(16)-big
    >>
  end
  def serialize( {{px,py,pz}, nil}, :big ) do
    <<
      @scale_xyz :: size(8),
      px :: float-size(32)-big,
      py :: float-size(32)-big,
      pz :: float-size(32)-big,
    >>
  end
  def serialize( {{px,py,pz}, {x,y,z}}, :big ) do
    <<
      @scale_xyz_pin :: size(8),
      px :: float-size(32)-big,
      py :: float-size(32)-big,
      pz :: float-size(32)-big,
      x  :: integer-size(16)-big,
      y  :: integer-size(16)-big,
      z  :: integer-size(16)-big
    >>
  end


  #--------------------------------------------------------
  def deserialize( mx, order \\ :native )

  def deserialize( <<
      @scale_pct :: size(8),
      pct :: float-size(32)-native,
      bin :: binary
    >>, :native ), do: {{pct, nil}, bin}
  def deserialize( <<
      @scale_pct_pin :: size(8),
      pct :: float-size(32)-native,
      x   :: integer-size(16)-native,
      y   :: integer-size(16)-native,
      bin :: binary
    >>, :native ), do: {{pct, {x,y}}, bin}
  def deserialize( <<
      @scale_xyz :: size(8),
      px  :: float-size(32)-native,
      py  :: float-size(32)-native,
      pz  :: float-size(32)-native,
      bin :: binary
    >>, :native ), do: {{{px,py,pz}, nil}, bin}
  def deserialize( <<
      @scale_xyz_pin :: size(8),
      px  :: float-size(32)-native,
      py  :: float-size(32)-native,
      pz  :: float-size(32)-native,
      x   :: integer-size(16)-native,
      y   :: integer-size(16)-native,
      z   :: integer-size(16)-native,
      bin :: binary
    >>, :native ), do: {{{px,py,pz}, {x,y,z}}, bin}

  def deserialize( <<
      @scale_pct :: size(8),
      pct :: float-size(32)-big,
      bin :: binary
    >>, :big ), do: {{pct, nil}, bin}
  def deserialize( <<
      @scale_pct_pin :: size(8),
      pct :: float-size(32)-big,
      x   :: integer-size(16)-big,
      y   :: integer-size(16)-big,
      bin :: binary
    >>, :big ), do: {{pct, {x,y}}, bin}
  def deserialize( <<
      @scale_xyz :: size(8),
      px  :: float-size(32)-big,
      py  :: float-size(32)-big,
      pz  :: float-size(32)-big,
      bin :: binary
    >>, :big ), do: {{{px,py,pz}, nil}, bin}
  def deserialize( <<
      @scale_xyz_pin :: size(8),
      px  :: float-size(32)-big,
      py  :: float-size(32)-big,
      pz  :: float-size(32)-big,
      x   :: integer-size(16)-big,
      y   :: integer-size(16)-big,
      z   :: integer-size(16)-big,
      bin :: binary
    >>, :big ), do: {{{px,py,pz}, {x,y,z}}, bin}

  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


end