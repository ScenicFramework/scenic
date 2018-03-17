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

  def input( input_event, pid \\ @name ), do: GenServer.cast( pid, {:input, input_event} )





  # TEMPORARY
  def request_set(), do: Scenic.ViewPort.request_set()


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
      graph_offsets:  %{},
      input_chain:    []
    }

    {:ok, state}
  end



  #============================================================================
  # handle_cast


  #--------------------------------------------------------
  # filter the input through the list of scenes in order.
  # each scene will choose whether or not to transform the event and pass it along
  # to the next in the filter list, or to end the process.
  def handle_cast( {:input, _}, %{input_chain: []} = state ), do: {:noreply, state}
  def handle_cast( {:input, input_event}, %{input_chain: [head | tail]} = state ) do
    GenServer.cast( head, {:filter_input, input_event, tail} )
    {:noreply, state}
  end


  #============================================================================
  # utilities


end
















