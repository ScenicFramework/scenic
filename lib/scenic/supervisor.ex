#
#  Created by Boyd Multerer on 1/24/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# one supervisor to bring up the main scenic servers

defmodule Scenic.Supervisor do
  @moduledoc false
  use Supervisor

  @viewports :scenic_dyn_viewports

  def start_link( opts \\ [] )
  def start_link( {a,b} ), do: start_link( [{a,b}] )
  def start_link( opts ) when is_list(opts) do
    Supervisor.start_link(__MODULE__, opts, name: :scenic)
  end

  #--------------------------------------------------------
  def init( opts ) do
    opts
    |> Keyword.get( :viewports, [] )
    |> do_init
  end

  #--------------------------------------------------------
  # init with no default viewports
  def do_init( [] ) do
    [
      {Scenic.ViewPort.Tables, nil},
      supervisor(Scenic.Cache.Supervisor, []),
      {DynamicSupervisor, name: @viewports, strategy: :one_for_one}
    ]
    |> Supervisor.init( strategy: :one_for_one )
  end

  #--------------------------------------------------------
  # init with default viewports
  def do_init( viewports ) do
    [
      {Scenic.ViewPort.Tables, nil},
      supervisor(Scenic.Cache.Supervisor, []),
      supervisor(Scenic.ViewPort.SupervisorTop, [viewports]),
      {DynamicSupervisor, name: @viewports, strategy: :one_for_one}
    ]
    |> Supervisor.init( strategy: :one_for_one )
  end

end
