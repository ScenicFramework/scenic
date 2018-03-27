#
#  Created by Boyd Multerer on 3/27/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# Supervisor for non-dynamic scenes

defmodule Scenic.Scene.Supervisor do
  use Supervisor

  def start_link( {ref, module, args} ) do
    Supervisor.start_link(__MODULE__, {ref, module, args})
  end

  def init( args ) do
    [
      {DynamicSupervisor, strategy: :one_for_one},
      {Scenic.Scene, args},
    ]
    |> Supervisor.init( strategy: :one_for_all )
  end

end
