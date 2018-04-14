#
#  Created by Boyd Multerer on 1/24/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# one supervisor to bring up the main scenic servers

defmodule Scenic.Supervisor do
  use Supervisor

  def start_link( initial_scene, args, opts \\ [] ) do
    Supervisor.start_link(__MODULE__, {initial_scene, args, opts}, name: :scenic)
  end

  def init( {initial_scene, args, opts} ) do
    [
      {Scenic.ViewPort.Tables, nil},
      supervisor(Scenic.Cache.Supervisor, []),
      supervisor(Scenic.ViewPort.Supervisor, [initial_scene, args, opts])
    ]
    |> Supervisor.init( strategy: :one_for_one )
  end

end
