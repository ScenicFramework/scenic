#
#  Copyright © 2017 Boyd Multerer. All rights reserved.
#

defmodule Scenic.Math.MatrixTest do
  use ExUnit.Case
  doctest Scenic.Math
  alias Scenic.Math.Matrix
  alias Scenic.Math.Matrix.Utils

  @matrix_a [
              3.0, 2.0, 0.0, 1.0,
              4.0, 0.0, 1.0, 2.0,
              3.0, 0.0, 2.0, 1.0,
              9.0, 2.0, 3.0, 1.0
            ]
            |> Utils.to_binary()

  @matrix_a_double [
                     6.0, 4.0, 0.0, 2.0,
                     8.0, 0.0, 2.0, 4.0,
                     6.0, 0.0, 4.0, 2.0,
                     18.0, 4.0, 6.0, 2.0
                   ]
                   |> Utils.to_binary()

  @matrix_b [
              1.5, 3.0, 0.0, 1.0,
              4.0, 0.1, 1.0, 2.0,
              2.9, 0.0, 2.0, 1.0,
              3.0, 2.0, 4.0, 1.2
            ]
            |> Utils.to_binary()

  @matrix_c [
              0, 10, 20, 30,
              1, 11, 21, 31,
              2, 12, 22, 32,
              3, 13, 23, 33
            ]
            |> Utils.to_binary()

  @matrix_zero [
                 0.0, 0.0, 0.0, 0.0,
                 0.0, 0.0, 0.0, 0.0,
                 0.0, 0.0, 0.0, 0.0,
                 0.0, 0.0, 0.0, 0.0
               ]
               |> Utils.to_binary()

  @matrix_identity [
                     1.0, 0.0, 0.0, 0.0,
                     0.0, 1.0, 0.0, 0.0,
                     0.0, 0.0, 1.0, 0.0,
                     0.0, 0.0, 0.0, 1.0
                   ]
                   |> Utils.to_binary()

  # ----------------------------------------------------------------------------
  # zero()
  test "zero returns the zero matrix" do
    assert Matrix.zero() == @matrix_zero
  end

  # ----------------------------------------------------------------------------
  # identity()
  test "identity returns the identity matrix" do
    assert Matrix.identity() == @matrix_identity
  end

  # ============================================================================
  # explicit builders

  # --------------------------------------------------------
  # 2x2 builder
  # test "build(row0, row1) works" do
  #   assert Matrix.build({0, 10}, {1, 11}) ==
  #            {
  #              {0.0, 10.0, 0.0, 0.0},
  #              {1.0, 11.0, 0.0, 0.0},
  #              {0.0, 0.0, 1.0, 0.0},
  #              {0.0, 0.0, 0.0, 1.0}
  #            }
  #            |> Utils.to_binary()
  # end

  # test "build({row0, row1}) works" do
  #   assert Matrix.build({{0, 10}, {1, 11}}) ==
  #            {
  #              {0.0, 10.0, 0.0, 0.0},
  #              {1.0, 11.0, 0.0, 0.0},
  #              {0.0, 0.0, 1.0, 0.0},
  #              {0.0, 0.0, 0.0, 1.0}
  #            }
  #            |> Utils.to_binary()
  # end

  # # --------------------------------------------------------
  # # 3x3 builder
  # test "build(row0, row1, row3) works" do
  #   assert Matrix.build({0, 10, 20}, {1, 11, 21}, {2, 12, 22}) ==
  #            {
  #              {0.0, 10.0, 20.0, 0.0},
  #              {1.0, 11.0, 21.0, 0.0},
  #              {2.0, 12.0, 22.0, 0.0},
  #              {0.0, 0.0, 0.0, 1.0}
  #            }
  #            |> Utils.to_binary()
  # end

  # test "build({row0, row1, row3}) works" do
  #   assert Matrix.build({{0, 10, 20}, {1, 11, 21}, {2, 12, 22}}) ==
  #            {
  #              {0.0, 10.0, 20.0, 0.0},
  #              {1.0, 11.0, 21.0, 0.0},
  #              {2.0, 12.0, 22.0, 0.0},
  #              {0.0, 0.0, 0.0, 1.0}
  #            }
  #            |> Utils.to_binary()
  # end

  # # --------------------------------------------------------
  # # 4x4 builder
  # test "build(row0, row1, row3, row4) works" do
  #   assert Matrix.build({0, 10, 20, 30}, {1, 11, 21, 31}, {2, 12, 22, 32}, {3, 13, 23, 33}) ==
  #            {
  #              {0.0, 10.0, 20.0, 30.0},
  #              {1.0, 11.0, 21.0, 31.0},
  #              {2.0, 12.0, 22.0, 32.0},
  #              {3.0, 13.0, 23.0, 33.0}
  #            }
  #            |> Utils.to_binary()
  # end

  # test "build({row0, row1, row3, row4}) works" do
  #   assert Matrix.build({{0, 10, 20, 30}, {1, 11, 21, 31}, {2, 12, 22, 32}, {3, 13, 23, 33}}) ==
  #            {
  #              {0.0, 10.0, 20.0, 30.0},
  #              {1.0, 11.0, 21.0, 31.0},
  #              {2.0, 12.0, 22.0, 32.0},
  #              {3.0, 13.0, 23.0, 33.0}
  #            }
  #            |> Utils.to_binary()
  # end

  # ============================================================================
  # specific build functions

  # --------------------------------------------------------
  # build_translation
  test "build_translation( 2x2 ) works" do
    mx =
      [
        1.0, 0.0, 0.0, 2.0,
        0.0, 1.0, 0.0, 3.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
      ]
      |> Utils.to_binary()

    # assert Matrix.build_translation(2.0, 3.0) == mx
    assert Matrix.build_translation({2.0, 3.0}) == mx
  end

  # test "build_translation( 3x3 ) works" do
  #   mx =
  #     [
  #       1.0, 0.0, 0.0, 2.0,
  #       0.0, 1.0, 0.0, 3.0,
  #       0.0, 0.0, 1.0, 4.0,
  #       0.0, 0.0, 0.0, 1.0
  #     ]
  #     |> Utils.to_binary()

  #   assert Matrix.build_translation(2.0, 3.0, 4.0) == mx
  #   assert Matrix.build_translation({2.0, 3.0, 4.0}) == mx
  # end

  # --------------------------------------------------------
  # build_scale
  test "build_scale(s) works" do
    mx =
      [
        2.0, 0.0, 0.0, 0.0,
        0.0, 2.0, 0.0, 0.0,
        0.0, 0.0, 2.0, 0.0,
        0.0, 0.0, 0.0, 1.0
      ]
      |> Utils.to_binary()

    assert Matrix.build_scale(2.0) == mx
  end

  test "build_scale( point ) works" do
    mx =
      [
        2.0, 0.0, 0.0, 0.0,
        0.0, 3.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
      ]
      |> Utils.to_binary()

    # assert Matrix.build_scale(2.0, 3.0) == mx
    assert Matrix.build_scale({2.0, 3.0}) == mx
  end

  # test "build_scale( x,y,z ) works" do
  #   mx =
  #     [
  #       2.0, 0.0, 0.0, 0.0,
  #       0.0, 3.0, 0.0, 0.0,
  #       0.0, 0.0, 4.0, 0.0,
  #       0.0, 0.0, 0.0, 1.0
  #     ]
  #     |> Utils.to_binary()

  #   assert Matrix.build_scale(2.0, 3.0, 4.0) == mx
  #   assert Matrix.build_scale({2.0, 3.0, 4.0}) == mx
  # end

  # --------------------------------------------------------
  # build_rotation( radians )

  test "build_rotation builds a z rotation" do
    cos = :math.cos(1.0)
    sin = :math.sin(1.0)

    mx =
      [
        cos, -sin, 0.0, 0.0,
        sin, cos, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0
      ]
      |> Utils.to_binary()

    assert Matrix.build_rotation(1.0) == mx
  end

  # --------------------------------------------------------
  # build_rotate_around( radians, point, axis \\ :z)

  test "build_rotate_around works around :z by default" do
    r = 1.0
    x = 10
    y = 20

    mx_inv = Matrix.build_translation({-x, -y})
    mx_rot = Matrix.build_rotation(r)
    mx_bak = Matrix.build_translation({x, y})

    mx = Matrix.mul(mx_inv, mx_rot) |> Matrix.mul(mx_bak)

    assert Matrix.build_rotate_around(r, {x, y}) == mx
  end

  # ============================================================================
  # act on a matrix

  test "rotate rotates a matrix" do
    mx_trans = Matrix.build_translation({123, 456})
    mx_rot = Matrix.build_rotation(1.3)
    assert Matrix.rotate(mx_trans, 1.3) == Matrix.mul(mx_trans, mx_rot)
  end

  test "translate translates a matrix" do
    mx_trans = Matrix.build_translation({123, 456})
    mx_rot = Matrix.build_rotation(1.3)
    assert Matrix.translate(mx_rot, {123, 456}) == Matrix.mul(mx_rot, mx_trans)
  end

  test "translate does nothing if the value is nil" do
    mx_rot = Matrix.build_rotation(1.3)
    assert Matrix.translate(mx_rot, nil) == mx_rot
  end

  test "scale scales a matrix" do
    mx_scale = Matrix.build_scale(1.2)
    mx_rot = Matrix.build_rotation(1.3)
    assert Matrix.scale(mx_rot, 1.2) == Matrix.mul(mx_rot, mx_scale)
  end

  test "scale does nothing if the value is nil" do
    mx_rot = Matrix.build_rotation(1.3)
    assert Matrix.scale(mx_rot, nil) == mx_rot
  end

  # ============================================================================
  # main functions

  # ----------------------------------------------------------------------------
  # close?( a, b, within )
  test "close? returns true if two matrixes are the same" do
    assert Matrix.close?(@matrix_a, @matrix_a)
  end

  test "close? returns true if two matrixes are similar" do
    assert Matrix.close?(@matrix_b, Matrix.put(@matrix_b, 0, 0, 1.50001), 0.001)
  end

  test "close? returns false if two matrixes beyond within" do
    refute Matrix.close?(@matrix_a, Matrix.put(@matrix_b, 0, 0, 1.502), 0.001)
  end

  test "close? returns false if two matrixes are different" do
    refute Matrix.close?(@matrix_b, @matrix_a)
  end

  # ----------------------------------------------------------------------------
  test "get works" do
    assert Matrix.get(@matrix_c, 0, 0) == 0.0
    assert Matrix.get(@matrix_c, 0, 1) == 1.0
    assert Matrix.get(@matrix_c, 0, 2) == 2.0
    assert Matrix.get(@matrix_c, 0, 3) == 3.0

    assert Matrix.get(@matrix_c, 1, 0) == 10.0
    assert Matrix.get(@matrix_c, 1, 1) == 11.0
    assert Matrix.get(@matrix_c, 1, 2) == 12.0
    assert Matrix.get(@matrix_c, 1, 3) == 13.0

    assert Matrix.get(@matrix_c, 2, 0) == 20.0
    assert Matrix.get(@matrix_c, 2, 1) == 21.0
    assert Matrix.get(@matrix_c, 2, 2) == 22.0
    assert Matrix.get(@matrix_c, 2, 3) == 23.0

    assert Matrix.get(@matrix_c, 3, 0) == 30.0
    assert Matrix.get(@matrix_c, 3, 1) == 31.0
    assert Matrix.get(@matrix_c, 3, 2) == 32.0
    assert Matrix.get(@matrix_c, 3, 3) == 33.0
  end

  test "get does the right thing out of bounds" do
    assert_raise FunctionClauseError, fn ->
      Matrix.get(@matrix_c, -1, 0)
    end

    assert_raise FunctionClauseError, fn ->
      Matrix.get(@matrix_c, 4, 0)
    end

    assert_raise FunctionClauseError, fn ->
      Matrix.get(@matrix_c, 0, -1)
    end

    assert_raise FunctionClauseError, fn ->
      Matrix.get(@matrix_c, 0, 4)
    end
  end

  # ----------------------------------------------------------------------------
  # put(matrix, x, y, v)
  # put an element into the matrix
  test "put works" do
    assert @matrix_zero
           |> Matrix.put(0, 0, 123)
           |> Matrix.get(0, 0) == 123.0

    assert @matrix_zero
           |> Matrix.put(0, 1, 123)
           |> Matrix.get(0, 1) == 123.0

    assert @matrix_zero
           |> Matrix.put(0, 2, 123)
           |> Matrix.get(0, 2) == 123.0

    assert @matrix_zero
           |> Matrix.put(0, 3, 123)
           |> Matrix.get(0, 3) == 123.0

    assert @matrix_zero
           |> Matrix.put(1, 0, 123)
           |> Matrix.get(1, 0) == 123.0

    assert @matrix_zero
           |> Matrix.put(1, 1, 123)
           |> Matrix.get(1, 1) == 123.0

    assert @matrix_zero
           |> Matrix.put(1, 2, 123)
           |> Matrix.get(1, 2) == 123.0

    assert @matrix_zero
           |> Matrix.put(1, 3, 123)
           |> Matrix.get(1, 3) == 123.0

    assert @matrix_zero
           |> Matrix.put(2, 0, 123)
           |> Matrix.get(2, 0) == 123.0

    assert @matrix_zero
           |> Matrix.put(2, 1, 123)
           |> Matrix.get(2, 1) == 123.0

    assert @matrix_zero
           |> Matrix.put(2, 2, 123)
           |> Matrix.get(2, 2) == 123.0

    assert @matrix_zero
           |> Matrix.put(2, 3, 123)
           |> Matrix.get(2, 3) == 123.0

    assert @matrix_zero
           |> Matrix.put(3, 0, 123)
           |> Matrix.get(3, 0) == 123.0

    assert @matrix_zero
           |> Matrix.put(3, 1, 123)
           |> Matrix.get(3, 1) == 123.0

    assert @matrix_zero
           |> Matrix.put(3, 2, 123)
           |> Matrix.get(3, 2) == 123.0

    assert @matrix_zero
           |> Matrix.put(3, 3, 123)
           |> Matrix.get(3, 3) == 123.0
  end

  test "put does the right thing out of bounds" do
    assert_raise FunctionClauseError, fn ->
      Matrix.put(@matrix_c, -1, 0, 10.0)
    end

    assert_raise FunctionClauseError, fn ->
      Matrix.put(@matrix_c, 4, 0, 10.0)
    end

    assert_raise FunctionClauseError, fn ->
      Matrix.put(@matrix_c, 0, -1, 10.0)
    end

    assert_raise FunctionClauseError, fn ->
      Matrix.put(@matrix_c, 0, 4, 10.0)
    end
  end

  # ----------------------------------------------------------------------------
  # get_xy(matrix)
  # get the xy coordinates from the matrix
  test "get_xy works" do
    assert Matrix.get_xy(@matrix_c) == {30.0, 31.0}
  end

  # ----------------------------------------------------------------------------
  # get_xyz(matrix)
  # get the xyz coordinates from the matrix
  test "get_xyz works" do
    assert Matrix.get_xyz(@matrix_c) == {30.0, 31.0, 32.0}
  end

  # ----------------------------------------------------------------------------
  # add( a, b )
  test "add adds two matrices together" do
    answer = Matrix.add(@matrix_a, @matrix_b)

    target =
      [
        4.5, 5.0, 0.0, 2.0,
        8.0, 0.1, 2.0, 4.0,
        5.9, 0.0, 4.0, 2.0,
        12.0, 4.0, 7.0, 2.2
      ]
      |> Utils.to_binary()

    assert Matrix.close?(answer, target)
  end

  test "add checks types" do
    assert_raise ArgumentError, fn ->
      Matrix.add(:not_a_matrix, @matrix_b)
    end

    assert_raise ArgumentError, fn ->
      Matrix.add(<<1, 2, 3>>, @matrix_b)
    end

    assert_raise ArgumentError, fn ->
      Matrix.add(@matrix_a, :not_a_matrix)
    end

    assert_raise ArgumentError, fn ->
      Matrix.add(@matrix_a, <<1, 2, 3>>)
    end
  end

  # ----------------------------------------------------------------------------
  # sub( a, b )
  test "sub subtracts two matrices" do
    answer = Matrix.sub(@matrix_a, @matrix_b)

    target =
      [
        1.5, -1.0, 0.0, 0.0,
        0.0, -0.1, 0.0, 0.0,
        0.1, 0.0, 0.0, 0.0,
        6.0, 0.0, -1.0, -0.2
      ]
      |> Utils.to_binary()

    assert Matrix.close?(answer, target)
  end

  test "sub checks types" do
    assert_raise ArgumentError, fn ->
      Matrix.sub(:not_a_matrix, @matrix_b)
    end

    assert_raise ArgumentError, fn ->
      Matrix.sub(<<1, 2, 3>>, @matrix_b)
    end

    assert_raise ArgumentError, fn ->
      Matrix.sub(@matrix_a, :not_a_matrix)
    end

    assert_raise ArgumentError, fn ->
      Matrix.sub(@matrix_a, <<1, 2, 3>>)
    end
  end

  # ----------------------------------------------------------------------------
  # mul( a, b )
  # multiply two matrices
  # see http://ncalculators.com/matrix/4x4-matrix-multiplication-calculator.htm
  test "mul multiplies two matrices" do
    answer = Matrix.mul(@matrix_a, @matrix_b)

    target =
      [
        15.5, 11.2, 6.0, 8.2,
        14.9, 16.0, 10.0, 7.4,
        13.3, 11.0, 8.0, 6.2,
        33.2, 29.2, 12.0, 17.2
      ]
      |> Utils.to_binary()

    assert Matrix.close?(answer, target)
  end

  # multiply a matrix and a scalar
  test "mul multiplies a matrix and a scalar" do
    answer = Matrix.mul(@matrix_a, 2.0)
    assert Matrix.close?(answer, @matrix_a_double)

    answer = Matrix.mul(@matrix_a, 2)
    assert Matrix.close?(answer, @matrix_a_double)
  end

  # multiply a list of matrices
  test "mul multiplies a list of matrices" do
    answer = Matrix.mul([@matrix_a, @matrix_b])

    target =
      [
        15.5, 11.2, 6.0, 8.2,
        14.9, 16.0, 10.0, 7.4,
        13.3, 11.0, 8.0, 6.2,
        33.2, 29.2, 12.0, 17.2
      ]
      |> Utils.to_binary()

    assert Matrix.close?(answer, target)
    # once more for good measure. Longer list. should not raise
    Matrix.mul([@matrix_a, @matrix_b, @matrix_a, @matrix_b])
  end

  test "mul checks types" do
    # lists
    assert_raise FunctionClauseError, fn ->
      Matrix.mul(:not_a_matrix_list)
    end

    assert_raise ArgumentError, fn ->
      Matrix.mul([@matrix_a, :not_a_matrix, @matrix_b])
    end

    # scalars
    assert_raise ArgumentError, fn ->
      Matrix.mul(<<1, 2, 3>>, 12)
    end

    assert_raise ArgumentError, fn ->
      Matrix.mul(@matrix_a, "not a scalar")
    end

    # matrices
    assert_raise ArgumentError, fn ->
      Matrix.mul(:not_a_matrix, @matrix_b)
    end

    assert_raise ArgumentError, fn ->
      Matrix.mul(<<1, 2, 3>>, @matrix_b)
    end

    assert_raise ArgumentError, fn ->
      Matrix.mul(@matrix_a, :not_a_matrix)
    end

    assert_raise ArgumentError, fn ->
      Matrix.mul(@matrix_a, <<1, 2, 3>>)
    end
  end

  # ----------------------------------------------------------------------------
  # div( a, s )
  # divide a matrix by a scalar
  test "div divides a matrix by a scalar" do
    answer = Matrix.div(@matrix_a_double, 2.0)
    assert Matrix.close?(answer, @matrix_a)

    answer = Matrix.div(@matrix_a_double, 2)
    assert Matrix.close?(answer, @matrix_a)
  end

  test "div checks types" do
    assert_raise ArgumentError, fn ->
      Matrix.div(:not_a_matrix, 2.0)
    end

    assert_raise ArgumentError, fn ->
      Matrix.div(<<1, 2, 3>>, 2.0)
    end

    assert_raise FunctionClauseError, fn ->
      Matrix.div(@matrix_a, :not_a_scalar)
    end
  end

  # ----------------------------------------------------------------------------
  # find the determinant of a matrix. See example at:
  # https://people.richland.edu/james/lecture/m116/matrices/determinant.html
  test "determinant works" do
    assert Matrix.determinant(@matrix_a) == 24.0
  end

  test "determinant finds a zero" do
    m =
      [
        3.0, 2.0, 0.0, 1.0,
        4.0, 0.0, 1.0, 2.0,
        0.0, 0.0, 0.0, 0.0,
        9.0, 2.0, 3.0, 1.0
      ]
      |> Utils.to_binary()

    assert Matrix.determinant(m) == 0.0
  end

  test "determinant checks types" do
    assert_raise ArgumentError, fn ->
      Matrix.determinant(:not_a_matrix)
    end

    assert_raise ArgumentError, fn ->
      Matrix.determinant(<<1, 2, 3>>)
    end
  end

  # ----------------------------------------------------------------------------
  # calculate the Transpose matrix
  # see http://ncalculators.com/matrix/4x4-inverse-matrix-calculator.htm
  test "transpose works" do
    assert Matrix.transpose(@matrix_a) ==
             [
               3.0, 4.0, 3.0, 9.0,
               2.0, 0.0, 0.0, 2.0,
               0.0, 1.0, 2.0, 3.0,
               1.0, 2.0, 1.0, 1.0
             ]
             |> Utils.to_binary()
  end

  test "transpose checks types" do
    assert_raise ArgumentError, fn ->
      Matrix.transpose(:not_a_matrix)
    end

    assert_raise ArgumentError, fn ->
      Matrix.transpose(<<1, 2, 3>>)
    end
  end

  # ----------------------------------------------------------------------------
  # calculate the adjugate matrix
  # see http://ncalculators.com/matrix/4x4-inverse-matrix-calculator.htm
  test "adjugate works" do
    assert Matrix.adjugate(@matrix_a) ==
             [
               -6.0, 6.0, -12.0, 6.0,
               16.0, -12.0, 12.0, -4.0,
               4.0, -12.0, 24.0, -4.0,
               10.0, 6.0, 12.0, -10.0
             ]
             |> Utils.to_binary()
  end

  test "adjugate checks types" do
    assert_raise ArgumentError, fn ->
      Matrix.adjugate(:not_a_matrix)
    end

    assert_raise ArgumentError, fn ->
      Matrix.adjugate(<<1, 2, 3>>)
    end
  end

  # ----------------------------------------------------------------------------
  # find the inverse of a matrix. See example at:
  # http://www.cg.info.hiroshima-cu.ac.jp/~miyazaki/knowledge/teche23.html
  # see http://ncalculators.com/matrix/4x4-inverse-matrix-calculator.htm

  test "invert works" do
    inverse = Matrix.invert(@matrix_a)

    target =
      [
        -6 / 24, 6 / 24, -12 / 24, 6 / 24,
        16 / 24, -12 / 24, 12 / 24, -4 / 24,
        4 / 24, -12 / 24, 24 / 24, -4 / 24,
        10 / 24, 6 / 24, 12 / 24, -10 / 24
      ]
      |> Utils.to_binary()

    assert Matrix.close?(inverse, target)
  end

  test "invert returns error if determinant is zero" do
    m =
      [
        3.0, 2.0, 0.0, 1.0,
        4.0, 0.0, 1.0, 2.0,
        0.0, 0.0, 0.0, 0.0,
        9.0, 2.0, 3.0, 1.0
      ]
      |> Utils.to_binary()

    assert Matrix.invert(m) == :err_zero_determinant
  end

  test "invert checks types" do
    assert_raise ArgumentError, fn ->
      Matrix.invert(:not_a_matrix)
    end

    assert_raise ArgumentError, fn ->
      Matrix.invert(<<1, 2, 3>>)
    end
  end

  # ----------------------------------------------------------------------------
  # project a vector with a matrix

  test "project_vector works with a vector2 tuple" do
    mx = Matrix.build_translation({5, 7})
    assert Matrix.project_vector(mx, {10, 20}) == {15, 27}
  end

  # test "project_vector works with a vector3 tuple" do
  #   mx = Matrix.build_translation({5, 7, 11})
  #   assert Matrix.project_vector(mx, {10, 20, 30}) == {15, 27, 41}
  # end

  test "project_vector checks types" do
    assert_raise ArgumentError, fn ->
      Matrix.project_vector(:not_a_matrix, {10, 20})
    end

    assert_raise FunctionClauseError, fn ->
      Matrix.project_vector(@matrix_a, :not_a_vector)
    end

    assert_raise ArgumentError, fn ->
      Matrix.project_vector(@matrix_a, {1, :not_a_scalar})
    end

    # assert_raise ArgumentError, fn ->
    #   Matrix.project_vector(@matrix_a, {1, 2, :not_a_scalar})
    # end
  end

  # ----------------------------------------------------------------------------
  # project packed 2d vectors with a matrix
  test "project_vector2s works with a packed vector2 binary" do
    mx = Matrix.build_translation({5, 7})

    vectors_in = <<
      10::float-size(32)-native,
      20::float-size(32)-native,
      100::float-size(32)-native,
      200::float-size(32)-native
    >>

    assert Matrix.project_vectors(mx, vectors_in) == <<
             15::float-size(32)-native,
             27::float-size(32)-native,
             105::float-size(32)-native,
             207::float-size(32)-native
           >>
  end

  test "project_vector2 checks types" do
    vectors_good = <<
      10::float-size(32)-native,
      20::float-size(32)-native,
      100::float-size(32)-native,
      200::float-size(32)-native
    >>

    vectors_wrong_size = <<
      10::float-size(32)-native,
      20::float-size(32)-native,
      100::float-size(32)-native
    >>

    assert_raise ArgumentError, fn ->
      Matrix.project_vectors(:not_a_matrix, vectors_good)
    end

    assert_raise ArgumentError, fn ->
      Matrix.project_vectors(@matrix_a, vectors_wrong_size)
    end
  end

  # ----------------------------------------------------------------------------
  # project packed 3d vectors with a matrix
  # test "project_vector3s works with a packed vector2 binary" do
  #   mx = Matrix.build_translation({5, 7, 11})

  #   vectors_in = <<
  #     10::float-size(32)-native,
  #     20::float-size(32)-native,
  #     30::float-size(32)-native,
  #     100::float-size(32)-native,
  #     200::float-size(32)-native,
  #     300::float-size(32)-native
  #   >>

  #   assert Matrix.project_vector3s(mx, vectors_in) == <<
  #            15::float-size(32)-native,
  #            27::float-size(32)-native,
  #            41::float-size(32)-native,
  #            105::float-size(32)-native,
  #            207::float-size(32)-native,
  #            311::float-size(32)-native
  #          >>
  # end

  # test "project_vector3 checks types" do
  #   vectors_good = <<
  #     10::float-size(32)-native,
  #     20::float-size(32)-native,
  #     30::float-size(32)-native,
  #     100::float-size(32)-native,
  #     200::float-size(32)-native,
  #     300::float-size(32)-native
  #   >>

  #   vectors_wrong_size = <<
  #     10::float-size(32)-native,
  #     20::float-size(32)-native,
  #     30::float-size(32)-native,
  #     100::float-size(32)-native,
  #     200::float-size(32)-native
  #   >>

  #   assert_raise ArgumentError, fn ->
  #     Matrix.project_vector3s(:not_a_matrix, vectors_good)
  #   end

  #   assert_raise ArgumentError, fn ->
  #     Matrix.project_vector3s(@matrix_a, vectors_wrong_size)
  #   end
  # end
end
