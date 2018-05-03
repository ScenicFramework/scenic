#
#  Created by Boyd Multerer, May 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# NIF version of the matrix math library. Accepts only binary form of matrices

# always row major

defmodule Scenic.Math.MatrixExp do
  alias Scenic.Math.MatrixExp, as: Matrix
  alias Scenic.Math.MatrixOld

  @matrix_zero      {
      {0.0, 0.0, 0.0, 0.0},
      {0.0, 0.0, 0.0, 0.0},
      {0.0, 0.0, 0.0, 0.0},
      {0.0, 0.0, 0.0, 0.0}
    }

  @matrix_identity  {
      {1.0, 0.0, 0.0, 0.0},
      {0.0, 1.0, 0.0, 0.0},
      {0.0, 0.0, 1.0, 0.0},
      {0.0, 0.0, 0.0, 1.0}
    }


if Mix.env() == :dev do
  def time() do
    a = MatrixOld.build_rotation( 0.1 )
    b = MatrixOld.build_translation( 10, 20 )
    c = MatrixOld.build_rotation( -0.05 )
    Benchwarmer.benchmark fn -> Matrix.mul( [a,b,c,a,b,c] ) end
  end
end

  #--------------------------------------------------------
  # multiply two matrixes
  def mul( a, b ) do
    nif_multiply( a, b )    # in NIF
  end
   # multiply two matrixes - this should go out to the nif, but will
   # fail back to the elixir version
  defp nif_multiply({
      {a00,a10,a20,a30},
      {a01,a11,a21,a31},
      {a02,a12,a22,a32},
      {a03,a13,a23,a33}
    },{
      {b00,b10,b20,b30},
      {b01,b11,b21,b31},
      {b02,b12,b22,b32},
      {b03,b13,b23,b33}
    }) do
    IO.puts "--------------> NON-NIF Matrix Multiply"
    {
      {
        (a00 * b00) + (a10 * b01) + (a20 * b02) + (a30 * b03),
        (a00 * b10) + (a10 * b11) + (a20 * b12) + (a30 * b13),
        (a00 * b20) + (a10 * b21) + (a20 * b22) + (a30 * b23),
        (a00 * b30) + (a10 * b31) + (a20 * b32) + (a30 * b33)
      },
      {
        (a01 * b00) + (a11 * b01) + (a21 * b02) + (a31 * b03),
        (a01 * b10) + (a11 * b11) + (a21 * b12) + (a31 * b13),
        (a01 * b20) + (a11 * b21) + (a21 * b22) + (a31 * b23),
        (a01 * b30) + (a11 * b31) + (a21 * b32) + (a31 * b33)
      },
      {
        (a02 * b00) + (a12 * b01) + (a22 * b02) + (a32 * b03),
        (a02 * b10) + (a12 * b11) + (a22 * b12) + (a32 * b13),
        (a02 * b20) + (a12 * b21) + (a22 * b22) + (a32 * b23),
        (a02 * b30) + (a12 * b31) + (a22 * b32) + (a32 * b33)
      },
      {
        (a03 * b00) + (a13 * b01) + (a23 * b02) + (a33 * b03),
        (a03 * b10) + (a13 * b11) + (a23 * b12) + (a33 * b13),
        (a03 * b20) + (a13 * b21) + (a23 * b22) + (a33 * b23),
        (a03 * b30) + (a13 * b31) + (a23 * b32) + (a33 * b33)
      }
    }
  end

  #--------------------------------------------------------
  # multiply down a list
  def mul(matrix_list) when is_list(matrix_list) do
    do_mul_list( @matrix_identity, matrix_list )
  end

  defp do_mul_list( m, [] ), do: m
  defp do_mul_list( m, [head | tail] ) do
    Matrix.mul(m, head)
    |>  do_mul_list( tail )
  end

end
