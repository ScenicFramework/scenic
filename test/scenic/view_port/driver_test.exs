#
#  Created by Boyd Multerer on 11/08/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


defmodule Scenic.ViewPort.DriverTest do
  use ExUnit.Case, async: true
  use Bitwise
  doctest Scenic
  alias Scenic.ViewPort.Driver

#  import IEx

  @driver_registry    :driver_registry

  defp verify_registries() do
    assert Registry.keys(@driver_registry, self()) == []
  end


  #============================================================================
  # set_graph

  test "set_graph sends a list to the driver" do
    verify_registries()
    # register to receive :set_graph calls
    {:ok, _} = Registry.register(:driver_registry, :set_graph, :set_graph )

    # set a graph (list)
    Driver.set_graph( [1,2,3] )

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:set_graph, [1, 2, 3]}}  )
  end


  #============================================================================
  # set_graph

  test "update_graph sends a list to the driver" do
    verify_registries()
    # register to receive :set_graph calls
    {:ok, _} = Registry.register(:driver_registry, :update_graph, :update_graph )

    # set a graph (list)
    Driver.update_graph( [1,2,3] )

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:update_graph, [1, 2, 3]}}  )
  end


  #============================================================================
  # identify

  test "identify returns a list of active drivers and their options" do
    verify_registries()
    # register to receive :set_graph calls
    {:ok, _} = Registry.register(:driver_registry, :identify, {__MODULE__, [a: 1, b: 2]} )

    # get the list of drivers
    assert Driver.identify() == [{{__MODULE__, [a: 1, b: 2]}, self()}]
  end

  #============================================================================
  # cast

  test "cast casts a message to the drivers" do
    verify_registries()
    # register to receive :set_graph calls
    {:ok, _} = Registry.register(:driver_registry, :driver_cast, :driver_cast )

    # set a graph (list)
    Driver.cast( :test_message )

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:driver_cast, :test_message}}  )
  end





end