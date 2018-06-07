#
#  Created by Boyd Multerer on 6/4/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Join do
  use Scenic.Primitive.Style

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info() do
    ":join must be one of :miter, :round, :bevel\r\n"
  end

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

  def normalize( :miter ), do: :miter
  def normalize( :round ), do: :round
  def normalize( :bevel ), do: :bevel

end