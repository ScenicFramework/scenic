#
#  Created by Boyd Multerer on 2017-10-07.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Supervisor do
  @moduledoc false

  use Supervisor
  alias Scenic.ViewPort

  #  import IEx

  # ============================================================================
  # setup the viewport supervisor

  def child_spec(config) do
    %{
      id: Map.get(config, :name) || make_ref(),
      start: {__MODULE__, :start_link, [config]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(%ViewPort.Config{} = config) do
    Supervisor.start_link(__MODULE__, config)
  end

  def start_link(%{} = config) do
    start_link(struct(ViewPort.Config, config))
  end

  def init(config) do
    # seperate the drivers from the rest of the config
    drivers = config.drivers
    config = Map.delete(config, :drivers)

    # finish the init
    build_children(drivers, config)
    |> Supervisor.init(strategy: :one_for_all)
  end

  def build_children([], config) do
    [
      {ViewPort, {self(), config}},
      {DynamicSupervisor, strategy: :one_for_one}
    ]
  end

  def build_children(drivers, config) do
    [
      {ViewPort, {self(), config}},
      {ViewPort.Driver.Supervisor, {self(), config.size, drivers}},
      {DynamicSupervisor, strategy: :one_for_one}
    ]
  end
end
