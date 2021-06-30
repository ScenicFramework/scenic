#
#  Created by Boyd Multerer on 2017-05-11.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Hidden do
  @moduledoc """
  Flags whether or not to draw a primitive.

  Example:

      graph
      |> rectangle({100, 200}, hidden: true)

  ## Data
  * `true` - "Hide" the primitive. Drawing is skipped.
  * `false` - "Show" the primitive. Drawing is run.

  Note: setting `hidden: true` on a group will hide all the primitives in
  the group. This is very efficient as it simply skips drawing the group
  and everything in it.
  """

  use Scenic.Primitive.Style

  # ============================================================================

  def validate( true ), do: {:ok, true}
  def validate( false ), do: {:ok, false}
  def validate( data )  do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Hidden specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The :hidden style must be either true or false#{IO.ANSI.default_color()}
      """
    }
  end

end
