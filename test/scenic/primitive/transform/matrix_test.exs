#
#  Created by Boyd Multerer on 2017-11-02.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Transform.MatrixTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Transform.Matrix

  alias Scenic.Primitive.Transform.Matrix

  @data <<
    1.0::float-size(32)-native,
    1.1::float-size(32)-native,
    1.2::float-size(32)-native,
    1.3::float-size(32)-native,
    2.0::float-size(32)-native,
    2.1::float-size(32)-native,
    2.2::float-size(32)-native,
    2.3::float-size(32)-native,
    3.0::float-size(32)-native,
    3.1::float-size(32)-native,
    3.2::float-size(32)-native,
    3.3::float-size(32)-native,
    4.0::float-size(32)-native,
    4.1::float-size(32)-native,
    4.2::float-size(32)-native,
    4.3::float-size(32)-native
  >>

  test "validate accepts valid data" do
    assert Matrix.validate(@data) == {:ok, @data}
  end

  test "validate rejects bad data" do
    {:error, msg} = Matrix.validate(@data <> <<5.0::float-size(32)-native>>)
    assert msg =~ "Invalid Matrix"

    {:error, msg} = Matrix.validate( :banana )
    assert msg =~ "Invalid Matrix"
  end

end
