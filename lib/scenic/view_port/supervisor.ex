#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Supervisor do
  use Supervisor
#  alias Scenic.ViewPort

  @dynamic_supervisor   :vp_dynamic_sup
#  @dynamic_scenes       :dynamic_scenes
#  @dynamic_drivers      :dynamic_drivers

  #============================================================================
  # setup the viewport supervisor

  def start_link( args ) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init( args ) do
    [
      {Scenic.ViewPort, args},
      {DynamicSupervisor, name: @dynamic_supervisor, strategy: :one_for_one},
    ]
    |> Supervisor.init( strategy: :rest_for_one )
  end

end
