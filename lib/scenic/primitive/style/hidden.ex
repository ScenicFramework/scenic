#
#  Created by Boyd Multerer on 2017-05-11.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
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
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be either true or false
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(true), do: true
  def verify(false), do: true
  def verify(_), do: false
end
