#
#  Created by Boyd Multerer on 5/11/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Hidden do
  use Scenic.Primitive.Style

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Style :hidden can only be true or false"

  #--------------------------------------------------------
  def verify( true ),     do: true
  def verify( false ),    do: true
  def verify( _ ),        do: false
  
end