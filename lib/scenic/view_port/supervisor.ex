#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Supervisor do
  use Supervisor
  alias Scenic.ViewPort

  @dynamic_supervisor   :vp_dynamic_sup
#  @dynamic_scenes       :dynamic_scenes
#  @dynamic_drivers      :dynamic_drivers

  import IEx

  #============================================================================
  # setup the viewport supervisor

  def start_link( %ViewPort.Config{} = config ) do
    Supervisor.start_link(__MODULE__, config)
  end

  def init( config ) do
    # seperate the drivers from the rest of the config
    drivers = config.drivers
    config = Map.delete(config, :drivers)

    # finish the init
    build_children(drivers, config)
    |> Supervisor.init( strategy: :one_for_all )
  end

  def build_children([], config) do
    [
      {ViewPort, {self(), config}},
      {DynamicSupervisor, strategy: :one_for_one},
    ]
  end

  def build_children(drivers, config) do
    [
      {ViewPort, {self(), config}},
      {ViewPort.Driver.Supervisor, {self(), drivers}},
      {DynamicSupervisor, strategy: :one_for_one}
    ]
  end

end




#      Supervisor.child_spec({Registry, keys: :unique, name: :viewport_registry},  id: :viewport_registry),
#      Supervisor.child_spec({Registry, keys: :duplicate, name: :driver_registry}, id: :driver_registry),
  #    {DynamicSupervisor, name: @dynamic_supervisor, strategy: :one_for_one},
  #    {Scenic.ViewPort, args},
#      supervisor(ViewPort.Driver.Supervisor, []),
#      {DynamicSupervisor, name: @dynamic_drivers, strategy: :one_for_one},
#      Supervisor.child_spec({Registry, keys: :duplicate, name: :input_registry},  id: :input_registry),
#      supervisor(ViewPort.Input.Tracker.Supervisor, [])
