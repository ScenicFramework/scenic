#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Stroke do
  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Paint

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info( data ), do: """
    #{IO.ANSI.red()}#{__MODULE__} data must be {width, paint_type}
    #{IO.ANSI.yellow()}Received: #{inspect(data)}

    This is very similar to the :fill style. with an added width
    examples:
        {12, :red}
        {12, {:color, :red}}

    #{IO.ANSI.default_color()}
  """

  #--------------------------------------------------------
  # named color

  def verify( stroke ) do
    try do
      normalize( stroke )
      true
    rescue
      _ -> false
    end    
  end

  #--------------------------------------------------------

  def normalize( {width, paint} ) when is_number(width) and width >= 0 do
    { width, Paint.normalize(paint) }
  end

end