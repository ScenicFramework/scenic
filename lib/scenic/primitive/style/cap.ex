#
#  Created by Boyd Multerer on 2018-06-04.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Cap do
  @moduledoc """
  Set how to draw the end of a line.

  Example:

      graph
      |> line({{0,0}, {100,100}}, cap: :round)

  ## Data
  * `:butt` - End of the line is flat, passing through the end point.
  * `:round` - End of the line is round, radiating from the end point.
  * `:square` - End of the line is flat, but projecting a square around the end point.
  """

  use Scenic.Primitive.Style

  # ============================================================================
  # data verification and serialization

  def validate( :butt ), do: { :ok, :butt }
  def validate( :round ), do: { :ok, :round }
  def validate( :square ), do: { :ok, :square }
  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Cap specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :cap style must be must be one of :butt, :round, or :square#{IO.ANSI.default_color()}
      """
    }
  end

end
