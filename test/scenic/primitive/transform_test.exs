#
#  Created by Boyd Multerer on 2017-07-08.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.TransformTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Transform

  #  import IEx

  alias Scenic.Primitive.Transform
  alias Scenic.Math.Matrix
  alias Scenic.Math.Vector2

  @identity Matrix.identity()

  @pin {10, 20}
  @rotation 1.1
  @scale {1.1, 0.8}
  @translate {4, 5}
  @mx Matrix.build_rotation(-0.2)

  @tx %{
    pin: @pin,
    rotate: @rotation,
    scale: @scale,
    translate: @translate,
    matrix: @mx
  }

  # ============================================================================
  # calculate the local matrix

  test "combine returns nil if the transform is nil" do
    assert Transform.combine(nil) == nil
  end

  test "combine returns nil if only pin is set" do
    only_pin = %{pin: {10, 20}}
    assert Transform.combine(only_pin) == nil
  end

  test "scale shortcut gets properly expanded" do
    tx = [s: 0.6]

    assert NimbleOptions.validate(tx, Transform.opts_schema()) ==
             {:ok, [s: {0.6, 0.6}]}
  end

  test "combine calculates the local matrix in the right order" do
    # first calc all the matrices
    mx_pin = Matrix.build_translation(@pin)
    mx_inv_pin = Matrix.build_translation(Vector2.invert(@pin))
    mx_rotation = Matrix.build_rotation(@rotation)
    mx_scale = Matrix.build_scale(@scale)
    mx_translation = Matrix.build_translation(@translate)

    # multiply them together
    expected =
      @identity
      |> Matrix.mul(@mx)
      |> Matrix.mul(mx_translation)
      |> Matrix.mul(mx_pin)
      |> Matrix.mul(mx_rotation)
      |> Matrix.mul(mx_scale)
      |> Matrix.mul(mx_inv_pin)

    # calcualte the normal way
    assert Transform.combine(@tx) == expected
  end
end
