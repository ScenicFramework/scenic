#
#  Re-Created by Boyd Multerer on November 30, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontBlur do
  use Scenic.Primitive.Style

# import IEx

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info( data ), do: """
    #{IO.ANSI.red()}#{__MODULE__} data must be a positive number
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
  """

  #--------------------------------------------------------
  def verify( blur ) do
    try do
      normalize( blur )
      true
    rescue
      _ -> false
    end
  end

  #--------------------------------------------------------
  def normalize( blur ) when is_number(blur) and blur >= 0 do
    blur
  end
end