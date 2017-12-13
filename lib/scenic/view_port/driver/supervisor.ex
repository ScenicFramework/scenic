#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Driver.Supervisor do
  use Supervisor
  alias Scenic.ViewPort.Driver

  @name       :drivers

#  import IEx

  #============================================================================
  # setup the viewport supervisor - get the list of drivers from the config

  def start_link( ) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init( :ok ) do
    drivers = Application.get_env(:scenic, Scenic)[:drivers]

#    children = Enum.map( drivers, fn({driver, args}) ->
#      Supervisor.child_spec({Driver, {driver, args}}, id: args[:name])
#    end)
#    |> IO.inspect()

    children = Enum.map( drivers, fn({driver, args}) -> driver.start_params(args) end)
    
    Supervisor.init( children, strategy: :one_for_one )
  end

end