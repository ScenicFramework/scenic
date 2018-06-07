#
#  Created by Boyd Multerer on 10/02/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.Rotate do
  use Scenic.Primitive.Transform

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Transform :rotate must conform to the documentation\n"

  #--------------------------------------------------------
  def verify( angle ) do
    try do
      normalize( angle )
      true
    rescue
      _ -> false
    end
  end

  #--------------------------------------------------------
  # normalize named stipples
  def normalize( a ) when is_number(a), do: a


end
