#
#  Created by Boyd Multerer
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# NIF version of the matrix math library. Accepts only binary form of matrices

# always row major

defmodule Scenic.Math.Matrix do
  alias Scenic.Math
  alias Scenic.Math.Matrix
  import :erlang, only: [{:nif_error, 1}]

  #  import IEx

  @app Mix.Project.config()[:app]
  # @env Mix.env

  # load the NIF
  @compile {:autoload, false}
  @on_load :load_nifs
  def load_nifs do
    :ok =
      :filename.join(:code.priv_dir(@app), 'matrix')
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

  @spec zero() :: Math.matrix()
  def zero(), do: @matrix_zero

  @spec identity() :: Math.matrix()
  def identity(), do: @matrix_identity

  # ============================================================================
  # build matrices - all output a binary matrix

  # --------------------------------------------------------
  # explicit builders.

  # --------------------------------------------------------
  # from a tupled matrix
  def build({{v0x, v0y}, {v1x, v1y}}) do
    build({v0x, v0y}, {v1x, v1y})
  end

  def build({{v0x, v0y, v0z}, {v1x, v1y, v1z}, {v2x, v2y, v2z}}) do
    build({v0x, v0y, v0z}, {v1x, v1y, v1z}, {v2x, v2y, v2z})
  end

  def build(
        {{v0x, v0y, v0z, v0w}, {v1x, v1y, v1z, v1w}, {v2x, v2y, v2z, v2w}, {v3x, v3y, v3z, v3w}}
      ) do
    build({v0x, v0y, v0z, v0w}, {v1x, v1y, v1z, v1w}, {v2x, v2y, v2z, v2w}, {v3x, v3y, v3z, v3w})
  end

  # --------------------------------------------------------
  # from a 2x2 tuple matrix
  def build({v0x, v0y}, {v1x, v1y}) do
    <<
      v0x::float-size(32)-native,
      v0y::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      v1x::float-size(32)-native,
      v1y::float-size(32)-native,
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
  # from a 3x3 matrix
  def build({v0x, v0y, v0z}, {v1x, v1y, v1z}, {v2x, v2y, v2z}) do
    <<
      v0x::float-size(32)-native,
      v0y::float-size(32)-native,
      v0z::float-size(32)-native,
      0.0::float-size(32)-native,
      v1x::float-size(32)-native,
      v1y::float-size(32)-native,
      v1z::float-size(32)-native,
      0.0::float-size(32)-native,
      v2x::float-size(32)-native,
      v2y::float-size(32)-native,
      v2z::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      0.0::float-size(32)-native,
      1.0::float-size(32)-native
    >>
  end

  # --------------------------------------------------------
  # build a 4x4 matrix
  def build(
        {v0x, v0y, v0z, v0w},
        {v1x, v1y, v1z, v1w},
        {v2x, v2y, v2z, v2w},
        {v3x, v3y, v3z, v3w}
      ) do
    <<
      v0x::float-size(32)-native,
      v0y::float-size(32)-native,
      v0z::float-size(32)-native,
      v0w::float-size(32)-native,
      v1x::float-size(32)-native,
      v1y::float-size(32)-native,
      v1z::float-size(32)-native,
      v1w::float-size(32)-native,
      v2x::float-size(32)-native,
      v2y::float-size(32)-native,
      v2z::float-size(32)-native,
      v2w::float-size(32)-native,
      v3x::float-size(32)-native,
      v3y::float-size(32)-native,
      v3z::float-size(32)-native,
      v3w::float-size(32)-native
    >>
  end

  # ============================================================================
  # specific builders. each does a certain job

  # --------------------------------------------------------
  # translation matrix

  def build_translation({x, y}), do: build_translation(x, y, 0.0)
  def build_translation({x, y, z}), do: build_translation(x, y, z)
  def build_translation(x, y), do: build_translation(x, y, 0.0)

  def build_translation(x, y, z) do
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
  # scale matrix

  def build_scale(s) when is_number(s), do: build_scale(s, s, s)
  def build_scale({x, y}), do: build_scale(x, y, 1.0)
  def build_scale({x, y, z}), do: build_scale(x, y, z)
  def build_scale(x, y), do: build_scale(x, y, 1.0)

  def build_scale(x, y, z) do
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

  def build_rotation(radians)

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
  def build_rotate_around(radians, point)

  def build_rotate_around(radians, {x, y}) do
    build_translation(-x, -y)
    |> Matrix.mul(build_rotation(radians))
    |> Matrix.mul(build_translation(x, y))
  end

  # ============================================================================
  # act on a matrix

  # --------------------------------------------------------
  def rotate(matrix, nil), do: matrix

  def rotate(matrix, amount) do
    build_rotation(amount)
    |> (&Matrix.mul(matrix, &1)).()
  end

  # def rotate( matrix, radians, axis ) when is_atom(axis) do
  #   build_rotation( radians, axis )
  #   |> ( &Matrix.mul(matrix, &1) ).()
  # end

  # --------------------------------------------------------
  def translate(matrix, {x, y}), do: translate(matrix, x, y)
  def translate(matrix, {x, y, z}), do: translate(matrix, x, y, z)
  def translate(matrix, nil), do: matrix
  def translate(matrix, x, y), do: build_translation(x, y) |> (&Matrix.mul(matrix, &1)).()
  def translate(matrix, x, y, z), do: build_translation(x, y, z) |> (&Matrix.mul(matrix, &1)).()

  # --------------------------------------------------------
  def scale(matrix, {x, y}), do: scale(matrix, x, y)
  def scale(matrix, {x, y, z}), do: scale(matrix, x, y, z)
  def scale(matrix, nil), do: matrix
  def scale(matrix, s), do: build_scale(s) |> (&Matrix.mul(matrix, &1)).()
  def scale(matrix, x, y), do: build_scale(x, y) |> (&Matrix.mul(matrix, &1)).()
  def scale(matrix, x, y, z), do: build_scale(x, y, z) |> (&Matrix.mul(matrix, &1)).()

  # ============================================================================
  # get / set functions

  # --------------------------------------------------------
  # pure tuple version is faster, but this fits the binary version better
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
  # pure tuple version is faster, but this fits the binary version better
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
  def get_xyz(matrix)

  def get_xyz(<<
        _::binary-size(12),
        x::float-size(32)-native,
        _::binary-size(12),
        y::float-size(32)-native,
        _::binary-size(12),
        z::float-size(32)-native,
        _::binary
      >>) do
    {x, y, z}
  end

  # ============================================================================
  # main functions

  # --------------------------------------------------------
  # test if two matrices are close. Is sometimes better than
  # testing equality as floating point errors can be a factor
  def close?(a, b, tolerance \\ 0.000001)

  def close?(<<_::binary-size(@matrix_size)>> = a, <<_::binary-size(@matrix_size)>> = b, t)
      when is_float(t) do
    # in NIF
    nif_close(a, b, t)
  end

  defp nif_close(_, _, _), do: nif_error("Did not find nif_close")

  # --------------------------------------------------------
  def add(a, b) do
    # in NIF
    nif_add(a, b)
  end

  defp nif_add(_, _), do: nif_error("Did not find nif_add")

  # --------------------------------------------------------
  def sub(a, b) do
    # in NIF
    nif_subtract(a, b)
  end

  defp nif_subtract(_, _), do: nif_error("Did not find nif_subtract")

  # --------------------------------------------------------
  # multiply a list of matrices
  def mul(matrix_list) when is_list(matrix_list) do
    # in NIF
    nif_multiply_list(matrix_list)
  end

  # --------------------------------------------------------
  # multiply by a scalar
  def mul(a, s) when is_integer(s), do: mul(a, s * 1.0)

  def mul(a, s) when is_float(s) do
    # in NIF
    nif_multiply_scalar(a, s)
  end

  # --------------------------------------------------------
  # multiply two matrixes
  def mul(a, b) do
    # in NIF
    nif_multiply(a, b)
  end

  defp nif_multiply(_, _), do: nif_error("Did not find nif_multiply")
  defp nif_multiply_scalar(_, _), do: nif_error("Did not find nif_multiply_scalar")
  defp nif_multiply_list(_), do: nif_error("Did not find nif_multiply_list")

  # --------------------------------------------------------
  # divide by a scalar
  def div(a, s) when is_integer(s), do: Matrix.div(a, s * 1.0)

  def div(a, s) when is_float(s) do
    # in NIF
    nif_divide_scalar(a, s)
  end

  defp nif_divide_scalar(_, _), do: nif_error("Did not find nif_divide_scalar")

  # --------------------------------------------------------
  def transpose(a) do
    # in NIF
    nif_transpose(a)
  end

  defp nif_transpose(_), do: nif_error("Did not find nif_transpose")

  # --------------------------------------------------------
  def determinant(a) do
    # in NIF
    nif_determinant(a)
  end

  defp nif_determinant(_), do: nif_error("Did not find nif_determinant")

  # --------------------------------------------------------
  def adjugate(a) do
    # in NIF
    nif_adjugate(a)
  end

  defp nif_adjugate(_), do: nif_error("Did not find nif_adjugate")

  # --------------------------------------------------------
  def invert(a) do
    case nif_determinant(a) do
      0.0 ->
        :err_zero_determinant

      det ->
        a
        |> nif_adjugate()
        |> nif_multiply_scalar(1.0 / det)
    end
  end

  # --------------------------------------------------------
  def project_vector(a, {x, y}) do
    # in NIF
    nif_project_vector2(a, x, y)
  end

  # --------------------------------------------------------
  def project_vector(a, {x, y, z}) do
    # in NIF
    nif_project_vector3(a, x, y, z)
  end

  defp nif_project_vector2(_, _, _), do: nif_error("Did not find nif_project_vector2")
  defp nif_project_vector3(_, _, _, _), do: nif_error("Did not find nif_project_vector3")

  # --------------------------------------------------------
  def project_vector2s(a, vector_bin) do
    # in NIF
    nif_project_vector2s(a, vector_bin)
  end

  defp nif_project_vector2s(_, _), do: nif_error("Did not find nif_project_vector2s")

  # --------------------------------------------------------
  def project_vector3s(a, vector_bin) do
    # in NIF
    nif_project_vector3s(a, vector_bin)
  end

  defp nif_project_vector3s(_, _), do: nif_error("Did not find nif_project_vector3s")
end
