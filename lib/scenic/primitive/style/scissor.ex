#
#  Created by Boyd Multerer on June 6, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Scissor do
  use Scenic.Primitive.Style

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    "Scissor region is a rect. Like this: {{x,y}, w, h}\r\n"
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

  def normalize( {{x,y}, w, h} ) do
    {{x,y}, w, h}
  end

end