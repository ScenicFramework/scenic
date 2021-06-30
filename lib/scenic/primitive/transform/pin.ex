#
#  Created by Boyd Multerer on 2017-10-03.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
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

  def validate( {x,y} ) when is_number(x) and is_number(y), do: {:ok, {x,y}}
  def validate( data )  do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Pin
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :pin option must be {x, y}#{IO.ANSI.default_color()}
      """
    }
  end

end
