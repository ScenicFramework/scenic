#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Driver.Supervisor do
  use Supervisor

  @name       :vp_drivers

#  import IEx

  #============================================================================
  # setup the viewport supervisor - start with no drivers

  def start_link( ) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init( :ok ) do
    # get the requested default drivers from the config
    children = case Application.get_env(:scenic, Scenic)[:view_ports] do
      nil -> []
      view_ports -> view_ports
    end

    Supervisor.init(children, strategy: :one_for_one)
  end


  #============================================================================
  # internal support


end