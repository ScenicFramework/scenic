#
#  Created by Boyd Multerer on 2017-10-03.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Pin do
  @moduledoc """
  Set the pin for rotate and scale transforms.

  When rotating or scaling, you need to set the point that doesn't move. This is
  the pin. If you don't set one, Scenic will try to use a sensible default for
  whatever primitive you are transforming.

  Use the `:pin` option to set it explicitly

  `{pin_x, pin_y }`  

  Example:
      graph
      |> text("Rotated!", rotate: 1.2, pin: {10, 20})
  """
  use Scenic.Primitive.Transform

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  defdelegate info(data), to: Scenic.Primitive.Transform.Translate

  # --------------------------------------------------------
  @doc false
  defdelegate verify(percent), to: Scenic.Primitive.Transform.Translate

  # --------------------------------------------------------
  @doc false
  defdelegate normalize(v2), to: Scenic.Primitive.Transform.Translate
end
