#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextHeight do
  use Scenic.Primitive.Style
  #  alias Scenic.Primitive.Style

  #  @dflag            Style.dflag()
  #  @type_code        0x0020

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a number
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  def verify(height) when is_number(height), do: true
  def verify(_), do: false
end
