#
#  Created by Boyd Multerer on 2017-05-12.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextHeight do
  @moduledoc """
  Set the vertical spacing of lines of text in a single block.

  Example:

      graph
      |> text( "Some Text\\r\\nMore Text" text_height: 50 )

  The natural vertical spacing of the font is used by default. Set this style if
  you want to override it.

  ## Data

  `spacing`

  * `spacing` - Vertical spacing from line to line.
  """

  use Scenic.Primitive.Style
  #  alias Scenic.Primitive.Style

  #  @dflag            Style.dflag()
  #  @type_code        0x0020

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a number
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(height) when is_number(height), do: true
  def verify(_), do: false
end
