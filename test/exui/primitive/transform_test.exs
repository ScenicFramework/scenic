#
#  Created by Boyd Multerer on 7/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.TransformTest do
  use ExUnit.Case, async: true
  doctest Exui

#  import IEx

  alias Scenic.Primitive.Transform
  alias Scenic.Math.MatrixBin
  alias Scenic.Math.Matrix.Utils
  alias Scenic.Math.Vector

  @identity     MatrixBin.identity()

  @pin          {10,20}
  @rotation     {1.1, :z}
  @scale        {1.1,0.8}
  @translate    {4,5}
  @mx           MatrixBin.build_rotation(-0.2)

  @tx           Transform.build(
      pin:    @pin,
      rot:    @rotation,
      scl:    @scale,
      trans:  @translate,
      mx:     @mx
    )

  @dflag      3
  @mx_code    0x01

  #============================================================================
  # def build( opts )

  test "build sets the pin" do
    assert Transform.get_pin(@tx) == @pin
  end

  test "build sets the rotation" do
    assert Transform.get_rotation(@tx) == @rotation
  end

  test "build sets the scale" do
    assert Transform.get_scale(@tx) == @scale
  end

  test "build sets the translation" do
    assert Transform.get_translation(@tx) == @translate
  end

  test "build sets the matrix" do
    assert Transform.get_matrix(@tx) == @mx
  end
  
  test "build calculates the final matrix" do
    {_,_,_,_,_,fin} = @tx
    assert is_binary(fin) == true
  end


  #============================================================================
  # put( transform, type, value)

  test "put clears final matrix" do
    {_,_,_,_,_,nil} = Transform.put(@tx, :pin, {123,456})
    {_,_,_,_,_,nil} = Transform.put(@tx, :rot, 1)
    {_,_,_,_,_,nil} = Transform.put(@tx, :scale, 1.1)
    {_,_,_,_,_,nil} = Transform.put(@tx, :trans, {1,2})
    {_,_,_,_,_,nil} = Transform.put(@tx, :mx, nil)
  end

  test "put nils the value given a nil value" do
    {nil,_,_,_,_,nil} = Transform.put(@tx, :pin, nil)
    {_,nil,_,_,_,nil} = Transform.put(@tx, :rot, nil)
    {_,_,nil,_,_,nil} = Transform.put(@tx, :scale, nil)
    {_,_,_,nil,_,nil} = Transform.put(@tx, :trans, nil)
    {_,_,_,_,nil,nil} = Transform.put(@tx, :mx, nil)
  end

  test "put builds a new tuple if transform is nil" do
    {@pin,nil,nil,nil,nil,_}        = Transform.put(nil, :pin, @pin)
    {nil,@rotation,nil,nil,nil,_}   = Transform.put(nil, :rot, @rotation)
    {nil,nil,@scale,nil,nil,_}      = Transform.put(nil, :scale, @scale)
    {nil,nil,nil,@translate,nil,_}  = Transform.put(nil, :trans, @translate)
    {nil,nil,nil,nil,@mx,_}         = Transform.put(nil, :mx, @mx)
  end

  test "put sets the named value" do
    mx = MatrixBin.build_scale(1.01)

    {{11,22},_,_,_,_,_}   = Transform.put(@tx, :pin, {11,22})
    {_,{0.1,:x},_,_,_,_}  = Transform.put(@tx, :rot, {0.1,:x})
    {_,_,3.3,_,_,_}       = Transform.put(@tx, :scale, 3.3)
    {_,_,_,{1,2},_,_}     = Transform.put(@tx, :trans, {1,2})
    {_,_,_,_,^mx,_}       = Transform.put(@tx, :mx, mx)
  end


  #============================================================================
  # pin

  #--------------------------------------------------------
  test "get_pin returns the pin value" do
    assert Transform.get_pin(@tx) == @pin
  end

  test "get_pin returns nil given nil transform" do
    assert Transform.get_pin(nil) == nil
  end

  #--------------------------------------------------------
  test "put_pin updates the pin data and calculates new final" do
    {_,_,_,_,_,old_fin} = @tx
    {{11,22},_,_,_,_,new_fin} = Transform.put_pin(@tx, {11,22})
    refute new_fin == old_fin
  end


  #============================================================================
  # rotation
  
  #--------------------------------------------------------
  test "get_rotation returns the rotation data" do
    assert Transform.get_rotation(@tx) == @rotation
  end

  test "get_rotation returns nil given nil transform" do
    assert Transform.get_rotation(nil) == nil
  end

  #--------------------------------------------------------
  test "put_rotation updates the rotation and calculates new final" do
    {_,_,_,_,_,old_fin} = @tx
    {_,{0.1,:x},_,_,_,new_fin} = Transform.put_rotation(@tx, {0.1,:x})
    refute new_fin == old_fin
  end


  #============================================================================
  # scale
  
  #--------------------------------------------------------
  test "get_scale returns the scale data" do
    assert Transform.get_scale(@tx) == @scale
  end

  test "get_scale returns nil given nil transform" do
    assert Transform.get_scale(nil) == nil
  end

  #--------------------------------------------------------
  test "put_scale updates the scale data and calculates new final" do
    {_,_,_,_,_,old_fin} = @tx
    {_,_,3.3,_,_,new_fin} = Transform.put_scale(@tx, 3.3)
    refute new_fin == old_fin
  end


  #============================================================================
  # translation
  
  #--------------------------------------------------------
  test "get_translation returns the translation data" do
    assert Transform.get_translation(@tx) == @translate
  end

  test "get_translation returns nil given nil transform" do
    assert Transform.get_translation(nil) == nil
  end

  #--------------------------------------------------------
  test "put_translation updates the translation data and calculates new final" do
    {_,_,_,_,_,old_fin} = @tx
    {_,_,_,{1,2},_,new_fin} = Transform.put_translation(@tx, {1,2})
    refute new_fin == old_fin
  end


  #============================================================================
  # matrix
  
  #--------------------------------------------------------
  test "get_matrix returns the matrix data" do
    assert Transform.get_matrix(@tx) == @mx
  end

  test "get_matrix returns nil given nil transform" do
    assert Transform.get_matrix(nil) == nil
  end

  #--------------------------------------------------------
  test "put_matrix updates the matrix data and calculates new final" do
    mx = MatrixBin.build_scale(1.01)
    {_,_,_,_,_,old_fin} = @tx
    {_,_,_,_,^mx,new_fin} = Transform.put_matrix(@tx, mx)
    refute new_fin == old_fin
  end


  #============================================================================
  # final transform matrix
  
  #--------------------------------------------------------
  test "get_local returns the local matrix" do
    {_,_,_,_,_,fin} = @tx
    assert Transform.get_local(@tx) == fin
  end

  test "get_final returns nil given nil transform" do
    assert Transform.get_local(nil) == nil
  end

  test "get_final calculates and returns the final if it is nil" do
    {pin,rot,scl,trans,mx,fin} = @tx
    assert Transform.get_local({pin,rot,scl,trans,mx,nil}) == fin
  end


  #============================================================================
  # final transform matrix binary blob
  
  #--------------------------------------------------------
  test "get_data returns the final binary blob" do
    {_,_,_,_,_,fin} = @tx
    assert Transform.get_data(@tx) == <<
      @dflag    :: size(8),
      @mx_code  :: size(8),
      Utils.to_binary(fin, :row) :: binary
    >>
  end

  test "get_data returns nil given nil" do
    assert Transform.get_data(nil) == nil
  end

  test "get_data returns nil if everything is nil but the pin" do
    assert Transform.get_data({{1,2},nil,nil,nil,nil,nil}) == nil
  end

  test "get_data calculates and returns the final blob if it is nil" do
    {pin,rot,scl,trans,mx,fin} = @tx

    assert Transform.get_data({pin,rot,scl,trans,mx,nil}) == <<
      @dflag    :: size(8),
      @mx_code  :: size(8),
      Utils.to_binary(fin, :row) :: binary
    >>
  end


  #============================================================================
  # calculate the local matrix

  test "calculate_local returns nil if the transform is nil" do
    assert Transform.calculate_local(nil) == nil
  end

  test "calculate_local does nothing if only the pin is set" do
    only_pin = {{1,2},nil,nil,nil,nil,nil}
    assert Transform.calculate_local(only_pin) == only_pin
  end

  test "calculate_local calculates the local matrix in the right order" do
    # first calc all the matrices
    mx_pin          = MatrixBin.build_translation( @pin )
    mx_inv_pin      = MatrixBin.build_translation( Vector.invert(@pin) )
    mx_rotation     = MatrixBin.build_rotation( @rotation )
    mx_scale        = MatrixBin.build_scale( @scale )
    mx_translation  = MatrixBin.build_translation( @translate )

    # multiply them together
    expected = @identity
      |> MatrixBin.mul( @mx )
      |> MatrixBin.mul( mx_translation )
      |> MatrixBin.mul( mx_pin )
      |> MatrixBin.mul( mx_rotation )
      |> MatrixBin.mul( mx_scale )
      |> MatrixBin.mul( mx_inv_pin )

    # build the matching incoming transform tuple by hand with nil final
    tx = {
      @pin,
      @rotation,
      @scale,
      @translate,
      @mx,
      nil
    }

    # calcualte the normal way
    {_,_,_,_,_,local} = Transform.calculate_local( tx )

    # check the answer
    assert local == expected
  end






















end