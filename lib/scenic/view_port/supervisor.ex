#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Supervisor do
  use Supervisor
  alias Scenic.ViewPort

  @dynamic_scenes       :dynamic_scenes

  #============================================================================
  # setup the viewport supervisor

  def start_link( ) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init( :ok ) do
    [
#      Supervisor.child_spec({Registry, keys: :unique, name: :viewport_registry},  id: :viewport_registry),
      Supervisor.child_spec({Registry, keys: :duplicate, name: :driver_registry}, id: :driver_registry),
      {Scenic.ViewPort, []},
      {DynamicSupervisor, name: @dynamic_scenes, strategy: :one_for_one},
#      Supervisor.child_spec({Registry, keys: :duplicate, name: :input_registry},  id: :input_registry),
      supervisor(ViewPort.Driver.Supervisor, []),
#      supervisor(ViewPort.Input.Tracker.Supervisor, [])
    ]
    |> Supervisor.init( strategy: :rest_for_one )
  end

end
