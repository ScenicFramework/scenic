#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort2 do
  use GenServer
  alias Scenic.ViewPort.Driver
  require Logger

#  import IEx

  @name :viewport

  #============================================================================
  # client api



  #============================================================================
  # internal server api


  #--------------------------------------------------------
  def start_link(:ok) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  #--------------------------------------------------------
  def init( :ok ) do

    # set up the initial state
    state = %{
      master_graph:   %{},
      graph_offsets:  %{}
    }

    {:ok, state}
  end



  #============================================================================
  # utilities


end
















