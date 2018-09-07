#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Matrix.UtilsTest do
  use ExUnit.Case
  alias Scenic.Math.Matrix.Utils

  @matrix {
    {3.0, 2.0, 0.0, 1.0},
    {4.0, 0.0, 1.0, 2.0},
    {3.0, 0.0, 2.0, 1.0},
    {9.0, 2.0, 3.0, 1.0}
  }

  @matrix_bin_col <<
    3.0::float-size(32)-native,
    4.0::float-size(32)-native,
    3.0::float-size(32)-native,
    9.0::float-size(32)-native,
    2.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    2.0::float-size(32)-native,
    0.0::float-size(32)-native,
    1.0::float-size(32)-native,
    2.0::float-size(32)-native,
    3.0::float-size(32)-native,
    1.0::float-size(32)-native,
    2.0::float-size(32)-native,
    1.0::float-size(32)-native,
    1.0::float-size(32)-native
  >>

  @matrix_bin_row <<
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
  # to_binary( matrix, major )
  test "to_binary column major works" do
    assert Utils.to_binary(@matrix, :col) == @matrix_bin_col
  end

  test "to_binary row major works" do
    assert Utils.to_binary(@matrix, :row) == @matrix_bin_row
  end

  test "to_binary does nothing if it already is a binary" do
    assert Utils.to_binary(@matrix_bin_col) == @matrix_bin_col
  end

  # ----------------------------------------------------------------------------
  # to_tuple( matrix, major )
  test "to_tuple column major works" do
    assert Utils.to_tuple(@matrix_bin_col, :col) == @matrix
  end

  test "to_tuple row major works" do
    assert Utils.to_tuple(@matrix_bin_row, :row) == @matrix
  end

  test "to_tuple does nothing if it already is a tuple" do
    assert Utils.to_tuple(@matrix) == @matrix
  end
end
