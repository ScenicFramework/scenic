#
#  Created by Boyd Multerer on 2017-10-07.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Driver.Supervisor do
  @moduledoc false

  use Supervisor

  # import IEx

  # ============================================================================
  # setup the viewport supervisor - get the list of drivers from the config

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init({root_sup, size, drivers}) do
    drivers
    |> Enum.map(fn driver_config ->
      driver = driver_config[:module]
      {driver, {root_sup, size, driver_config}}
    end)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
