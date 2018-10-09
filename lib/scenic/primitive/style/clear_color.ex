#
#  Created by Boyd Multerer on 2017-10-25.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.ClearColor do
  @moduledoc false

  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Paint.Color

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a valid color
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      Note: the :clear_color style is only honored on the root node of the root graph. 
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  # named color

  def verify(color) do
    try do
      normalize(color)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  def normalize(color), do: Color.to_rgba(color)
end
