#
#  Created by Boyd Multerer on 2017-11-02.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.MatrixTest do
  use ExUnit.Case, async: true
  doctest Scenic

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

  test "info works" do
    assert Matrix.info(:test_data) =~ ":test_data"
  end

  test "verify passes valid data" do
    assert Matrix.verify(@data) == true
  end

  test "verify fails invalid data" do
    assert Matrix.verify(@data <> <<0>>) == false
    assert Matrix.verify(:banana) == false
  end
end
