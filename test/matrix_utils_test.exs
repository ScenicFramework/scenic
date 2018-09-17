#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Matrix.UtilsTest do
  use ExUnit.Case
  alias Scenic.Math.Matrix.Utils

  @matrix_list [
    3.0, 2.0, 0.0, 1.0,
    4.0, 0.0, 1.0, 2.0,
    3.0, 0.0, 2.0, 1.0,
    9.0, 2.0, 3.0, 1.0
  ]

  @matrix_bin <<
    3.0::float-size(32)-native,
    2.0::float-size(32)-native,
    0.0::float-size(32)-native,
    1.0::float-size(32)-native,
    4.0::float-size(32)-native,
    0.0::float-size(32)-native,
    1.0::float-size(32)-native,
    2.0::float-size(32)-native,
    3.0::float-size(32)-native,
    0.0::float-size(32)-native,
    2.0::float-size(32)-native,
    1.0::float-size(32)-native,
    9.0::float-size(32)-native,
    2.0::float-size(32)-native,
    3.0::float-size(32)-native,
    1.0::float-size(32)-native
  >>

  # ----------------------------------------------------------------------------
  # to_binary( matrix_list )
  test "to_binary works" do
    assert Utils.to_binary(@matrix_list) == @matrix_bin
  end

  # ----------------------------------------------------------------------------
  # to_list( matrix )
  test "to_list works" do
    assert Utils.to_list(@matrix_bin) == @matrix_list
  end

end