#
#  Created by Boyd Multerer on 7/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.TransformTest do
  use ExUnit.Case, async: true
  doctest Scenic

#  import IEx

  alias Scenic.Primitive.Transform
  alias Scenic.Math.MatrixBin
  alias Scenic.Math.Vector

  @identity     MatrixBin.identity()

  @pin          {10,20}
  @rotation     {1.1, :z}
  @scale        {1.1,0.8}
  @translate    {4,5}
  @mx           MatrixBin.build_rotation(-0.2)

  @tx           %{
      pin:        @pin,
      rotate:     @rotation,
      scale:      @scale,
      translate:  @translate,
      matrix:     @mx
    }

  #============================================================================
  # calculate the local matrix

  test "calculate_local returns nil if the transform is nil" do
    assert Transform.calculate_local(nil) == nil
  end

  test "calculate_local returns nil if only pin is set" do
    only_pin = %{pin: {10,20}}
    assert Transform.calculate_local(only_pin) == nil
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

    # calcualte the normal way
    assert Transform.calculate_local( @tx ) == expected
  end






















end