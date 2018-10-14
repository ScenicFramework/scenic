#
#  Created by Boyd Multerer on 2017-10-25.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.ClearColor do
  @moduledoc """
  Set the background color of the entire window/screen.

  Note: Since the `:clear_color` affect is global, it will only be honored when set
  on the base of the root scene. In other words, it has no affect on groups or
  when set on Components.

  Example:

      @graph Graph.build( clear_color: :white )

  ## Data

  Any [valid color](Scenic.Primitive.Style.Paint.Color.html).
  """

  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Paint.Color

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a valid color
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      Note: the :clear_color style is only honored on the root node of the root graph. 
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  # named color
  @doc false
  def verify(color) do
    try do
      normalize(color)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  @doc false
  def normalize(color), do: Color.to_rgba(color)
end
