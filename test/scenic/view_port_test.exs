#
#  Created by Boyd Multerer on 11/09/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


defmodule Scenic.ViewPortTest do
  use ExUnit.Case, async: false
  doctest Scenic
  alias Scenic.ViewPort

#  import IEx

  @driver_registry      :driver_registry
  @viewport_registry    :viewport_registry


  #============================================================================
  # set_scene
  test "set_scene casts a :set_scene to a scene with private data" do
    ViewPort.set_scene( self() )
    assert_receive( {:"$gen_cast", {:set_scene, nil}} )
  end

  test "set_scene casts a :set_scene to a scene" do
    ViewPort.set_scene( self(), :private_data )
    assert_receive( {:"$gen_cast", {:set_scene, :private_data}} )
  end


  #============================================================================
  # set_graph

  test "set_graph sends a minimal graph to the drivers" do
    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )

    # register for the driver message
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    ViewPort.set_graph( 0, [1,2,3] )

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:set_graph, [1, 2, 3]}}  )
  end


  #============================================================================
  # update_graph

  test "update_graph sends a minimal set of deltas to the drivers" do
    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )

    # register for the driver message
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    ViewPort.update_graph( 0, [1,2,3] )

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:update_graph, [1, 2, 3]}}  )
  end

  #============================================================================
  # delete_graph

  test "delete_graph sends a minimal set of deltas to the drivers" do
    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )

    # register for the driver message
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    ViewPort.delete_graph( 0 )

    # make sure it was sent
#    assert_receive( {:"$gen_cast", {:delete_graph, 0}}  )
  end

  #============================================================================
  # current_scene

  test "current_scene returns the pid of the current scene" do
    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )
    assert ViewPort.current_scene() == self()
  end

  test "current_scene returns nil if no scene is set" do
    assert ViewPort.current_scene() == nil
  end


  #============================================================================
  # current_scene?

  test "current_scene? returs true if the current process is the current scene" do
    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )
    assert ViewPort.current_scene?
  end

  test "current_scene? returs true if the identified process is the current scene" do
    # spin up a simple agent, just to have a not-self process to use
    {:ok, pid} = Agent.start_link(fn -> 1 + 1 end, name: __MODULE__)

    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, pid )

    assert ViewPort.current_scene?( pid )

    # clean up
    Agent.stop(pid)
  end

  test "current_scene? returns false current process (self) is not the current scene" do
    # spin up a simple agent, just to have a not-self process to use
    {:ok, pid} = Agent.start_link(fn -> 1 + 1 end, name: __MODULE__)

    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, pid )

    refute ViewPort.current_scene?()

    # clean up
    Agent.stop(pid)
  end
  test "current_scene? returns false if the identified process is not the current scene even if self is..." do
    # spin up a simple agent, just to have a not-self process to use
    {:ok, pid} = Agent.start_link(fn -> 1 + 1 end, name: __MODULE__)

    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )

    refute ViewPort.current_scene?( pid )

    # clean up
    Agent.stop(pid)
  end

  test "current_scene? returns false if no scene is set" do
    refute ViewPort.current_scene?
  end


  #============================================================================
  # send_to_scene

  test "send_to_scene sends a message to the current scene" do
    # set this process as the current scene
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )

    ViewPort.send_to_scene( {:test_message, [1,2,3]} )

    # make sure it was sent
    assert_received( {:"$gen_cast", {:test_message, [1,2,3]}}  )
  end


  #============================================================================
  # genserver side

#  #--------------------------------------------------------
#  # input
#
#  test "init works, even if it doesn't do anything" do
#    {:ok, nil} = ViewPort.init( :whatever )
#  end
#
#  #--------------------------------------------------------
#  # handle_cast
#  
#  test "handle_cast :set_scene sets the new scene" do
#    ViewPort.handle_cast({:set_scene, self()}, :whatever)
#    assert ViewPort.current_scene?( self() )
#  end
#
#  test "handle_cast :set_scene unregisters the previous scene" do
#    # spin up a simple agent, just to have a not-self process to use
#    {:ok, pid} = Agent.start_link(fn -> 1 + 1 end, name: __MODULE__)
#
#    # set the agent process as the current scene
#    {:ok, _} = Registry.register(@viewport_registry, :messages, pid )
#    assert ViewPort.current_scene?( pid )
#    refute ViewPort.current_scene?( self() )
#
#    ViewPort.handle_cast({:set_scene, self()}, :whatever)
#    refute ViewPort.current_scene?( pid )
#    assert ViewPort.current_scene?( self() )
#    assert_received( {:"$gen_cast", :graph_reset}  )
#
#    # clean up
#    Agent.stop(pid)
#  end
#
#  test "handle_cast :set_scene sends the new scene the :graph_reset message" do
#    ViewPort.handle_cast({:set_scene, self()}, :whatever)
#    assert_received( {:"$gen_cast", :graph_reset}  )
#  end
#
end



























