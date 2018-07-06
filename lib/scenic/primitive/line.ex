#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Line do
  use Scenic.Primitive
#  alias Scenic.Primitive
#  alias Scenic.Primitive.Style

#  import IEx

  @styles   [:hidden, :stroke, :cap]

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Line data must be two points: {{x0,y0}, {x1,y1}}"


  #--------------------------------------------------------
  def verify( {{x0, y0}, {x1, y1}} = data ) when
    is_number(x0) and is_number(y0) and
    is_number(x1) and is_number(y1), do: {:ok, data}
  def verify( _ ), do: :invalid_data


  #============================================================================
  def valid_styles(), do: @styles

  #============================================================================

  #--------------------------------------------------------
  def default_pin(data), do: centroid( data )

  #--------------------------------------------------------
  def centroid(data)
  def centroid({{x0, y0}, {x1, y1}}) do
    {
      round( (x0 + x1) / 2 ),
      round( (y0 + y1) / 2 )
    }
  end

end

