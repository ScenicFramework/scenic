#
#  Created by Boyd Multerer on June 5, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Fill do
  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Paint

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Style :fill must be a color/image.\r\n"
  end

  #--------------------------------------------------------
  # named color

  def verify( paint ) do
    try do
      normalize( paint )
      true
    rescue
      _ -> false
    end    
  end

  #--------------------------------------------------------

  def normalize( paint ) do
    Paint.normalize(paint)
  end

end