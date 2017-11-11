#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Supervisor do
  use Supervisor
  alias Scenic.ViewPort

  @name       :vp_supervisor

  #============================================================================
  # setup the viewport supervisor

  def start_link( ) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init( :ok ) do
    [
      Supervisor.child_spec({Registry, keys: :duplicate, name: :driver_registry}, id: :driver_registry),
      {ViewPort.Cache, []},
      Supervisor.child_spec({Registry, keys: :unique, name: :viewport_registry},  id: :viewport_registry),
      Supervisor.child_spec({Registry, keys: :duplicate, name: :input_registry},  id: :input_registry),
      supervisor(ViewPort.Driver.Supervisor, []),
      supervisor(ViewPort.Input.Tracker.Supervisor, [])
    ]
    |> Supervisor.init( strategy: :rest_for_one )
  end

end
