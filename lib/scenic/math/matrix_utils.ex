# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.Matrix.Utils do
  @moduledoc """
  Helper functions for working with matrices.

  The matrix format for the main `Scenic.Math.Matrix` functions is a 64 byte
  binary blob containing 16 4-byte floats. This is great for doing the math in
  code, but not so great for reading or understanding the values by a human.

  These functions transform more readable/writable formats into the binary blob
  and vice versa.
  """

  alias Scenic.Math

  # --------------------------------------------------------
  # binary format is column-major

  @doc """
  Convert a readable format into a binary blob.

  Parameters:
  * `matrix_list` - a list of 16 numbers

  Returns:
  A binary matrix blob
  """

  @spec to_binary(matrix :: Math.matrix_list()) :: Math.matrix()
  def to_binary(matrix_list)

  # --------------------------------------------------------
  # binary format is column-major
  def to_binary([
        a00,
        a10,
        a20,
        a30,
        a01,
        a11,
        a21,
        a31,
        a02,
        a12,
        a22,
        a32,
        a03,
        a13,
        a23,
        a33
      ]) do
    <<
      a00::float-size(32)-native,
      a10::float-size(32)-native,
      a20::float-size(32)-native,
      a30::float-size(32)-native,
      a01::float-size(32)-native,
      a11::float-size(32)-native,
      a21::float-size(32)-native,
      a31::float-size(32)-native,
      a02::float-size(32)-native,
      a12::float-size(32)-native,
      a22::float-size(32)-native,
      a32::float-size(32)-native,
      a03::float-size(32)-native,
      a13::float-size(32)-native,
      a23::float-size(32)-native,
      a33::float-size(32)-native
    >>
  end

  @doc """
  Convert a binary matrix into a list of 16 numbers.

  Parameters:
  * `matrix` - a binary matrix

  Returns:
  A list of 16 numbers
  """
  def to_list(matrix)

  def to_list(<<
        a00::float-size(32)-native,
        a10::float-size(32)-native,
        a20::float-size(32)-native,
        a30::float-size(32)-native,
        a01::float-size(32)-native,
        a11::float-size(32)-native,
        a21::float-size(32)-native,
        a31::float-size(32)-native,
        a02::float-size(32)-native,
        a12::float-size(32)-native,
        a22::float-size(32)-native,
        a32::float-size(32)-native,
        a03::float-size(32)-native,
        a13::float-size(32)-native,
        a23::float-size(32)-native,
        a33::float-size(32)-native
      >>) do
    [
      a00,
      a10,
      a20,
      a30,
      a01,
      a11,
      a21,
      a31,
      a02,
      a12,
      a22,
      a32,
      a03,
      a13,
      a23,
      a33
    ]
  end
end
