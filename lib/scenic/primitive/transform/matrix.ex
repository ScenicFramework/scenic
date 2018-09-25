#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Matrix do
  @moduledoc false
  use Scenic.Primitive.Transform

  @matrix_byte_size 16 * 4

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a binary containing 16 32-bit floats
      #{IO.ANSI.yellow()}Received: #{inspect(data)}

      Please use the Scenic.Math.Matrix module to build this data.

      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(<<_::binary-size(@matrix_byte_size)>>), do: true
  def verify(_), do: false
end
