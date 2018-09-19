#
#  Created by Boyd Multerer
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# NIF version of the matrix math library. Accepts only binary form of matrices

# always row major

defmodule Scenic.Math.Matrix do
  @moduledoc """
  A collection of functions to work with matrices.

  All the matrix fucntions in this module work exclusively with the binary form
  of a matrix, which is a compact binary of 16 4-byte floats.

  If you would like to convert back and forth from the more human friendly list
  version, then please use the functions in [Scenic.Math.Matrix.Utils](Scenic.Math.Matrix.Utils)
  """

  alias Scenic.Math
  alias Scenic.Math.Matrix
  import :erlang, only: [{:nif_error, 1}]

  #  import IEx

  @app Mix.Project.config()[:app]

  # load the NIF
  @compile {:autoload, false}
  @on_load :load_nifs
  @doc false
  def load_nifs do
    :ok =
      @app
      |> :code.priv_dir()
      |> :filename.join('matrix')
      |> :erlang.load_nif(0)
  end

  @matrix_size 4 * 16

  @matrix_zero <<
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native
  >>

  @matrix_identity <<
    1.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    1.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    1.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    0.0::float-size(32)-native,
    1.0::float-size(32)-native
  >>

  # ============================================================================
  # common constants
  @doc "A matrix where all the values are 0"
  @spec zero() :: Math.matrix()
  def zero(), do: @matrix_zero

  @doc "The identity matrix"
  @spec identity() :: Math.matrix()
  def identity(), do: @matrix_identity

  # ============================================================================
  # build matrices - all output a binary matrix

  # --------------------------------------------------------
  # explicit builders.

  # --------------------------------------------------------
  # from a tupled matrix
  # def build({{v0x, v0y}, {v1x, v1y}}) do
  #   build({v0x, v0y}, {v1x, v1y})
  # end

  # def build({{v0x, v0y, v0z}, {v1x, v1y, v1z}, {v2x, v2y, v2z}}) do
  #   build({v0x, v0y, v0z}, {v1x, v1y, v1z}, {v2x, v2y, v2z})
  # end

  # def build(
  #       {{v0x, v0y, v0z, v0w}, {v1x, v1y, v1z, v1w}, {v2x, v2y, v2z, v2w}, {v3x, v3y, v3z, v3w}}
  #     ) do
  #   build({v0x, v0y, v0z, v0w}, {v1x, v1y, v1z, v1w}, {v2x, v2y, v2z, v2w}, {v3x, v3y, v3z, v3w})
  # end

  # # --------------------------------------------------------
  # # from a 2x2 tuple matrix
  # def build({v0x, v0y}, {v1x, v1y}) do
  #   <<
  #     v0x::float-size(32)-native,
  #     v0y::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     v1x::float-size(32)-native,
  #     v1y::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     1.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     1.0::float-size(32)-native
  #   >>
  # end

  # # --------------------------------------------------------
  # # from a 3x3 matrix
  # def build({v0x, v0y, v0z}, {v1x, v1y, v1z}, {v2x, v2y, v2z}) do
  #   <<
  #     v0x::float-size(32)-native,
  #     v0y::float-size(32)-native,
  #     v0z::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     v1x::float-size(32)-native,
  #     v1y::float-size(32)-native,
  #     v1z::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     v2x::float-size(32)-native,
  #     v2y::float-size(32)-native,
  #     v2z::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     0.0::float-size(32)-native,
  #     1.0::float-size(32)-native
  #   >>
  # end

  # # --------------------------------------------------------
  # # build a 4x4 matrix
  # def build(
  #       {v0x, v0y, v0z, v0w},
  #       {v1x, v1y, v1z, v1w},
  #       {v2x, v2y, v2z, v2w},
  #       {v3x, v3y, v3z, v3w}
  #     ) do
  #   <<
  #     v0x::float-size(32)-native,
  #     v0y::float-size(32)-native,
  #     v0z::float-size(32)-native,
  #     v0w::float-size(32)-native,
  #     v1x::float-size(32)-native,
  #     v1y::float-size(32)-native,
  #     v1z::float-size(32)-native,
  #     v1w::float-size(32)-native,
  #     v2x::float-size(32)-native,
  #     v2y::float-size(32)-native,
  #     v2z::float-size(32)-native,
  #     v2w::float-size(32)-native,
  #     v3x::float-size(32)-native,
  #     v3y::float-size(32)-native,
  #     v3z::float-size(32)-native,
  #     v3w::float-size(32)-native
  #   >>
  # end

  # ============================================================================
  # specific builders. each does a certain job

  # --------------------------------------------------------
  # translation matrix
  @doc """
  Build a matrix that represents a simple translation.

  Parameters:
  * vector_2: the vector defining how much to translate

  Returns:
  A binary matrix
  """
  @spec build_translation(vector_2 :: Math.vector_2()) :: Math.matrix()
  def build_translation(vector_2)
  def build_translation({x, y}), do: do_build_translation({x, y, 0.0})
  # def build_translation({x, y, z}), do: build_translation(x, y, z)
  # def build_translation(x, y), do: build_translation(x, y, 0.0)
  defp do_build_translation({x, y, z}) do
    <<
      1.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      x * 1.0::float-size(32)-native,
      0.0::float-size(32)-native,
      1.0::float-size(32)-native,
      0.0::float-size(32)-native,
      y * 1.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      1.0::float-size(32)-native,
      z * 1.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      1.0::float-size(32)-native
    >>
  end

  # --------------------------------------------------------
  @doc """
  Build a matrix that represents a scaling operation.

  Parameters:
  * scale: the amount to scale by. Can be either a number or a vector_2

  Returns:
  A binary matrix
  """
  @spec build_scale(scale :: number | Math.vector_2()) :: Math.matrix()
  def build_scale(scale)
  def build_scale(s) when is_number(s), do: do_build_scale({s, s, s})
  def build_scale({x, y}), do: do_build_scale({x, y, 1.0})
  # def build_scale({x, y, z}), do: build_scale(x, y, z)
  # def build_scale(x, y), do: build_scale(x, y, 1.0)
  defp do_build_scale({x, y, z}) do
    <<
      x * 1.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      y * 1.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      z * 1.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      1.0::float-size(32)-native
    >>
  end

  # --------------------------------------------------------
  # rotation matrix

  #  def build_rotation( {radians, axis} )
  #      when is_number(radians) and is_atom(axis) do
  #    build_rotation( radians, axis )
  #  end
  # def build_rotation( {axis, radians} )
  #     when is_number(radians) and is_atom(axis) do
  #   build_rotation( radians, axis )
  # end

  @doc """
  Build a matrix that represents a 2D rotation around the origin.

  Parameters:
  * angle: the amount to rotate, in radians

  Returns:
  A binary matrix
  """
  @spec build_rotation(angle :: number) :: Math.matrix()
  def build_rotation(angle)

  # def build_rotation( radians, :x ) do
  #   cos = :math.cos( radians )
  #   sin = :math.sin( radians )
  #   <<
  #     1.0 :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,

  #     0.0 :: float-size(32)-native,
  #     cos :: float-size(32)-native,
  #     sin :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,

  #     0.0 :: float-size(32)-native,
  #     -sin :: float-size(32)-native,
  #     cos :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,

  #     0.0 :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,
  #     1.0 :: float-size(32)-native
  #   >>
  # end

  # def build_rotation( radians, :y ) do
  #   cos = :math.cos( radians )
  #   sin = :math.sin( radians )
  #   <<
  #     cos :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,
  #     sin :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,

  #     0.0 :: float-size(32)-native,
  #     1.0 :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,

  #     -sin :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,
  #     cos :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,

  #     0.0 :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,
  #     0.0 :: float-size(32)-native,
  #     1.0 :: float-size(32)-native
  #   >>
  # end

  def build_rotation(radians) do
    cos = :math.cos(radians)
    sin = :math.sin(radians)

    <<
      cos::float-size(32)-native,
      -sin::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      sin::float-size(32)-native,
      cos::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      1.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      1.0::float-size(32)-native
    >>
  end

  # --------------------------------------------------------
  @doc """
  Build a matrix that represents a 2D rotation around a point.

  Parameters:
  * angle: the amount to rotate, in radians
  * pin: position to pin the rotation around

  Returns:
  A binary matrix
  """
  @spec build_rotate_around(angle :: number, pin :: Math.point()) :: Math.matrix()
  def build_rotate_around(angle, pin)

  def build_rotate_around(radians, {x, y}) do
    build_translation({-x, -y})
    |> Matrix.rotate(radians)
    |> Matrix.translate({x, y})
  end

  # ============================================================================
  # act on a matrix

  # --------------------------------------------------------
  @doc """
  Multiply a matrix by a rotation.

  Parameters:
  * matrix: The incoming source matrix
  * angle: the amount to rotate, in radians or nil (which does nothing

  Returns:
  A binary matrix
  """
  @spec rotate(matrix :: Math.matrix(), angle :: number | nil) :: Math.matrix()
  def rotate(matrix, angle)
  def rotate(matrix, nil), do: matrix

  def rotate(matrix, angle) do
    Matrix.mul(
      matrix,
      build_rotation(angle)
    )
  end

  # def rotate( matrix, radians, axis ) when is_atom(axis) do
  #   build_rotation( radians, axis )
  #   |> ( &Matrix.mul(matrix, &1) ).()
  # end

  # --------------------------------------------------------
  @doc """
  Multiply a matrix by a translation.

  Parameters:
  * matrix: The incoming source matrix
  * vector_2: the vector to translate by or nil (which does nothing)

  Returns:
  A binary matrix
  """
  @spec translate(matrix :: Math.matrix(), vector_2 :: Math.vector_2() | nil) :: Math.matrix()
  def translate(matrix, vector_2)
  def translate(matrix, nil), do: matrix

  def translate(matrix, {x, y}) do
    Matrix.mul(
      matrix,
      build_translation({x, y})
    )
  end

  # def translate(matrix, {x, y, z}), do: translate(matrix, x, y, z)
  # def translate(matrix, nil), do: matrix
  # def translate(matrix, x, y), do: build_translation(x, y) |> (&Matrix.mul(matrix, &1)).()
  # def translate(matrix, x, y, z), do: build_translation(x, y, z) |> (&Matrix.mul(matrix, &1)).()

  # --------------------------------------------------------
  @doc """
  Multiply a matrix by a scale factor.

  Parameters:
  * matrix: The incoming source matrix
  * scale: the amount to scale by. Can be either a number, a vector, or nil (which does nothing)

  Returns:
  A binary matrix
  """
  @spec scale(matrix :: Math.matrix(), scale :: number | Math.vector_2() | nil) :: Math.matrix()
  def scale(matrix, scale)
  def scale(matrix, nil), do: matrix
  # def scale(matrix, {x, y}), do: scale(matrix, {x, y})
  # def scale(matrix, {x, y, z}), do: scale(matrix,{ x, y, z})
  def scale(matrix, s) do
    Matrix.mul(
      matrix,
      build_scale(s)
    )
  end

  # def scale(matrix, x, y), do: build_scale(x, y) |> (&Matrix.mul(matrix, &1)).()
  # def scale(matrix, x, y, z), do: build_scale(x, y, z) |> (&Matrix.mul(matrix, &1)).()

  # ============================================================================
  # get / set functions

  # --------------------------------------------------------
  @doc """
  Get a single value out of a binary matrix.

  Parameters:
  * matrix: The source matrix
  * x: the column to pull the data from
  * y: the row to pull the data from

  Returns:
  A number
  """
  @spec get(matrix :: Math.matrix(), x :: number, y :: number) :: number
  def get(matrix, x, y)

  def get(matrix, x, y)
      when is_integer(x) and is_integer(y) and x >= 0 and y >= 0 and x < 4 and y < 4 do
    skip_size = y * 4 * 4 + x * 4

    <<
      _::binary-size(skip_size),
      v::float-size(32)-native,
      _::binary
    >> = matrix

    v
  end

  # --------------------------------------------------------
  @doc """
  Put a single value into a binary matrix.

  Parameters:
  * matrix: The source matrix
  * x: the column to pull the data from
  * y: the row to pull the data from
  * v: the value to put into the matrix. Must be a number.

  Returns:
  A number
  """
  @spec put(matrix :: Math.matrix(), x :: number, y :: number, v :: number) :: Math.matrix()
  def put(matrix, x, y, v)
  def put(matrix, x, y, v) when is_integer(v), do: put(matrix, x, y, v * 1.0)

  def put(matrix, x, y, v)
      when is_integer(x) and is_integer(y) and is_float(v) and x >= 0 and y >= 0 and x < 4 and
             y < 4 do
    skip_size = y * 4 * 4 + x * 4

    <<
      pre::binary-size(skip_size),
      _::binary-size(4),
      post::binary
    >> = matrix

    <<
      pre::binary,
      v::float-size(32)-native,
      post::binary
    >>
  end

  # --------------------------------------------------------
  @doc """
  Extract the 2D vector represented by the matrix.

  Parameters:
  * matrix: The source matrix

  Returns:
  A vector_2
  """
  @spec get_xy(matrix :: Math.matrix()) :: Math.vector_2()
  def get_xy(matrix)

  def get_xy(<<
        _::binary-size(12),
        x::float-size(32)-native,
        _::binary-size(12),
        y::float-size(32)-native,
        _::binary
      >>) do
    {x, y}
  end

  # --------------------------------------------------------
  # def get_xyz(matrix)
  # def get_xyz(<<
  #       _::binary-size(12),
  #       x::float-size(32)-native,
  #       _::binary-size(12),
  #       y::float-size(32)-native,
  #       _::binary-size(12),
  #       z::float-size(32)-native,
  #       _::binary
  #     >>) do
  #   {x, y, z}
  # end

  # ============================================================================
  # main functions

  # --------------------------------------------------------
  # test if two matrices are close. Is sometimes better than
  # testing equality as floating point errors can be a factor
  @doc """
  Test if two matrices are close in value to each other.

  Parameters:
  * matrix_a: The first matrix
  * matrix_b: The second matrix
  * tolerance: Defines what close means. Defaults to: 0.000001

  Returns:
  A boolean
  """
  @spec close?(matrix_a :: Math.matrix(), matrix_a :: Math.matrix(), tolerance :: number) ::
          boolean
  def close?(matrix_a, matrix_b, tolerance \\ 0.000001)

  def close?(<<_::binary-size(@matrix_size)>> = a, <<_::binary-size(@matrix_size)>> = b, t)
      when is_float(t) do
    # in NIF
    nif_close(a, b, t)
  end

  defp nif_close(_, _, _), do: nif_error("Did not find nif_close")

  # --------------------------------------------------------
  @doc """
  Add two matrices together.

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix_a: The first matrix
  * matrix_b: The second matrix

  Returns:
  The resulting matrix
  """
  @spec add(matrix_a :: Math.matrix(), matrix_b :: Math.matrix()) :: Math.matrix()
  def add(matrix_a, matrix_b) do
    # in NIF
    nif_add(matrix_a, matrix_b)
  end

  defp nif_add(_, _), do: nif_error("Did not find nif_add")

  # --------------------------------------------------------
  @doc """
  Subtract one matrix from another.

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix_a: The first matrix
  * matrix_b: The second matrix, which is subtracted from the first

  Returns:
  The resulting matrix
  """
  @spec sub(matrix_a :: Math.matrix(), matrix_b :: Math.matrix()) :: Math.matrix()
  def sub(matrix_a, matrix_b) do
    # in NIF
    nif_subtract(matrix_a, matrix_b)
  end

  defp nif_subtract(_, _), do: nif_error("Did not find nif_subtract")

  # --------------------------------------------------------
  @doc """
  Multiply a list of matrices together.

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix_list: A list of matrices

  Returns:
  The resulting matrix
  """
  @spec mul(matrix_list :: list(Math.matrix())) :: Math.matrix()
  def mul(matrix_list)

  def mul(matrix_list) when is_list(matrix_list) do
    # in NIF
    nif_multiply_list(matrix_list)
  end

  # --------------------------------------------------------
  @doc """
  Multiply a matrix by another matrix or a scalar.

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix: A matrix
  * multiplier: A number (scalar) or a matrix to multiply by

  Returns:
  The resulting matrix
  """
  @spec mul(matrix :: Math.matrix(), multiplier :: number | Math.matrix()) :: Math.matrix()

  def mul(matrix, multiplier)
  def mul(a, s) when is_integer(s), do: mul(a, s * 1.0)

  def mul(a, s) when is_float(s) do
    # in NIF
    nif_multiply_scalar(a, s)
  end

  # multiply two matrixes
  def mul(matrix_a, matrix_b) do
    # in NIF
    nif_multiply(matrix_a, matrix_b)
  end

  defp nif_multiply(_, _), do: nif_error("Did not find nif_multiply")
  defp nif_multiply_scalar(_, _), do: nif_error("Did not find nif_multiply_scalar")
  defp nif_multiply_list(_), do: nif_error("Did not find nif_multiply_list")

  # --------------------------------------------------------
  @doc """
  Divide a matrix by a scalar.

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix: A matrix
  * divisor: A number (scalar) to divide by

  Returns:
  The resulting matrix
  """
  @spec div(matrix :: Math.matrix(), divisor :: number) :: Math.matrix()
  def div(matrix, scalar)
  def div(a, s) when is_integer(s), do: Matrix.div(a, s * 1.0)

  def div(a, s) when is_float(s) do
    # in NIF
    nif_divide_scalar(a, s)
  end

  defp nif_divide_scalar(_, _), do: nif_error("Did not find nif_divide_scalar")

  # --------------------------------------------------------
  @doc """
  Transpose a matrix

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix: A matrix

  Returns:
  The resulting matrix
  """
  @spec transpose(matrix :: Math.matrix()) :: Math.matrix()
  def transpose(matrix) do
    # in NIF
    nif_transpose(matrix)
  end

  defp nif_transpose(_), do: nif_error("Did not find nif_transpose")

  # --------------------------------------------------------
  @doc """
  Calculate the determinant of a matrix

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix: A matrix

  Returns:
  The resulting matrix
  """
  @spec determinant(matrix :: Math.matrix()) :: Math.matrix()
  def determinant(matrix) do
    # in NIF
    nif_determinant(matrix)
  end

  defp nif_determinant(_), do: nif_error("Did not find nif_determinant")

  # --------------------------------------------------------
  @doc """
  Calculate the adjugate of a matrix

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix: A matrix

  Returns:
  The resulting matrix
  """
  @spec adjugate(matrix :: Math.matrix()) :: Math.matrix()
  def adjugate(matrix) do
    # in NIF
    nif_adjugate(matrix)
  end

  defp nif_adjugate(_), do: nif_error("Did not find nif_adjugate")

  # --------------------------------------------------------
  @doc """
  Inverte a matrix.

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix: A matrix

  Returns:
  The resulting matrix
  """
  @spec invert(matrix :: Math.matrix()) :: Math.matrix()
  def invert(matrix) do
    case nif_determinant(matrix) do
      0.0 ->
        :err_zero_determinant

      det ->
        matrix
        |> nif_adjugate()
        |> nif_multiply_scalar(1.0 / det)
    end
  end

  # --------------------------------------------------------
  @doc """
  Project a vector by a matrix.

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix: A matrix
  * vector: The vector to project

  Returns:
  The projected vector
  """
  @spec project_vector(matrix :: Math.matrix(), vector_2 :: Math.vector_2()) :: Math.vector_2()
  def project_vector(matrix, {x, y}) do
    # in NIF
    nif_project_vector2(matrix, x, y)
  end

  # --------------------------------------------------------
  # def project_vector(a, {x, y, z}) do
  #   # in NIF
  #   nif_project_vector3(a, x, y, z)
  # end
  defp nif_project_vector2(_, _, _), do: nif_error("Did not find nif_project_vector2")
  # defp nif_project_vector3(_, _, _, _), do: nif_error("Did not find nif_project_vector3")

  # --------------------------------------------------------
  @doc """
  Project a list of vectors by a matrix.

  This operation is implemented as a NIF for performance.

  Parameters:
  * matrix: A matrix
  * vectors: The list of vectors to project

  Returns:
  A list of projected vectors
  """
  @spec project_vector(matrix :: Math.matrix(), vector_list :: list(Math.vector_2())) ::
          list(Math.vector_2())
  def project_vectors(a, vector_bin) do
    # in NIF
    nif_project_vector2s(a, vector_bin)
  end

  defp nif_project_vector2s(_, _), do: nif_error("Did not find nif_project_vector2s")

  # --------------------------------------------------------
  # def project_vector3s(a, vector_bin) do
  #   # in NIF
  #   nif_project_vector3s(a, vector_bin)
  # end
  # defp nif_project_vector3s(_, _), do: nif_error("Did not find nif_project_vector3s")
end
