#
#  Created by Boyd Multerer on 11/06/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Input.Tracker.Supervisor do
  use Supervisor

  @name       :trackers

#  import IEx

  #============================================================================
  # setup the viewport supervisor - get the list of drivers from the config

  def start_link( ) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init( :ok ) do
    Supervisor.init( [], strategy: :simple_one_for_one )
  end

end