#
#  Created by Boyd Multerer on 1/24/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# one supervisor to bring up the main scenic servers

defmodule Scenic.Supervisor do
  use Supervisor

  @viewports :scenic_viewports

  def start_link( opts \\ [] ) do
    Supervisor.start_link(__MODULE__, opts, name: :scenic)
  end

  def init( _opts ) do
    [
      {Scenic.ViewPort.Tables, nil},
      supervisor(Scenic.Cache.Supervisor, []),
      {DynamicSupervisor, name: @viewports, strategy: :one_for_one}
    ]
    |> Supervisor.init( strategy: :one_for_one )
  end

end
