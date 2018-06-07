#
#  Created by Boyd Multerer on June 5, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Path do
  use Scenic.Primitive
#  alias Scenic.Primitive
#  alias Scenic.Primitive.Style

#  import IEx

  @styles   [:hidden, :stroke]

  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Path must be a list of actions. See docs."


  #--------------------------------------------------------
  def verify( actions ) when is_list(actions), do: {:ok, actions}
  def verify( _ ), do: :invalid_data


  #============================================================================
  def valid_styles(), do: @styles

  #============================================================================

  #--------------------------------------------------------
  def default_pin( _ ) do
    {0,0}
  end


end

