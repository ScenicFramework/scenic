#
#  Created by Boyd Multerer on April 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# top level static viewport supervisor. Each viewport also has a
# supervisor to hold it together.

defmodule Scenic.ViewPort.SupervisorTop do
  @moduledoc false

  use Supervisor
  alias Scenic.ViewPort

  # import IEx

  # ============================================================================
  # setup the viewport supervisor

  def start_link(viewports) do
    Supervisor.start_link(__MODULE__, viewports)
  end

  def init(viewports) do
    viewports
    |> Enum.map(fn vp_config ->
      ViewPort.Config.valid!(vp_config)
      {ViewPort.Supervisor, vp_config}
    end)
    |> Supervisor.init(strategy: :one_for_one)
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
