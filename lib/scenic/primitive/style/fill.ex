#
#  Created by Boyd Multerer on 2018-06-05.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Fill do
  @moduledoc """
  Fill primitives with the specified paint.

  Example:

      graph
      |> rectangle({10, 20}, fill: :blue)

  ## Data

  Any [valid paint](Scenic.Primitive.Style.Paint.html).
  """

  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Paint

  # ============================================================================
  # data verification and serialization

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must be a valid paint type
      #{IO.ANSI.yellow()}Received: #{inspect(data)}
      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(paint) do
    try do
      normalize(paint)
      true
    rescue
      _ -> false
    end
  end

  # --------------------------------------------------------
  @doc false
  def normalize(paint) do
    Paint.normalize(paint)
  end
end
