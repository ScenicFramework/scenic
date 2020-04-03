#
#  Created by Boyd Multerer on 2017-10-02.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Matrix do
  @moduledoc """
  Apply an arbitrary matrix.

  Applies an arbitrary 4x4 matrix to a primitive. For now, only the 2-D part
  of the matrix actually does anything. Am using 4x4 though for future compatibility.

  Example:

      @matrix [ 0, 1, 2, 3,
                4, 5, 6, 7,
                8, 9, 10, 11,
                12, 13, 14, 15 ]
      |> Scenic.Math.Matrix.Matrix.Utils.to_binary()

      graph
      |> text("Transformer!", matrix: @matrix)
  """

  use Scenic.Primitive.Transform

  @matrix_byte_size 16 * 4

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a binary containing 16 32-bit floats
      #{IO.ANSI.yellow()}Received: #{inspect(data)}

      Please use the Scenic.Math.Matrix module to build this data.

      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(<<_::binary-size(@matrix_byte_size)>>), do: true
  def verify(_), do: false
end
