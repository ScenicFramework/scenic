#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Supervisor do
  use Supervisor

  @name       :vp_supervisor

  #============================================================================
  # setup the viewport supervisor

  def start_link( ) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init( :ok ) do
    [
#      supervisor(Registry, [:duplicate, :driver_registry]),
#      supervisor(Registry, [:duplicate, :input_registry]),
      Supervisor.child_spec({Registry, keys: :duplicate, name: :driver_registry}, id: :driver_registry),
      Supervisor.child_spec({Registry, keys: :duplicate, name: :input_registry}, id: :input_registry),
      {Scenic.ViewPort, self()},
      supervisor(Scenic.ViewPort.Driver.Supervisor, [])
    ]
    |> Supervisor.init( strategy: :rest_for_one )
  end

end
