#
#  Created by Boyd Multerer on 1/24/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# one supervisor to bring up the main scenic servers

defmodule Scenic.Supervisor do
  use Supervisor

  def start_link( ) do
    Supervisor.start_link(__MODULE__, :ok, name: :scenic)
  end

  def init( :ok ) do
    [
      supervisor(Scenic.Cache.Supervisor, []),
      supervisor(Scenic.ViewPort.Supervisor, [])
    ]
    |> Supervisor.init( strategy: :one_for_one )
  end

end
