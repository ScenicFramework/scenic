#
#  re-Created by Boyd Multerer May 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
#

defmodule Scenic.ViewPort.DriverTest do
  use ExUnit.Case, async: false
  use Bitwise
  doctest Scenic
  alias Scenic.ViewPort.Driver

#  import IEx


  #============================================================================
  # faux module callbacks...

  def init( opts ) do
    assert opts == [1,2,3]
    {:ok, :init_state}
  end

  def handle_info( msg, state ) do
    GenServer.cast(self(), {:test_handle_info, msg, state})
    {:noreply, :handle_info_state}
  end

  def handle_call( msg, from, state ) do
    GenServer.cast(self(), {:test_handle_call, msg, from, state})
    {:reply, :handle_call_reply, :handle_call_state}
  end

  def handle_cast( msg, state ) do
    GenServer.cast(self(), {:test_handle_cast, msg, state})
    {:noreply, :handle_cast_state}
  end


  #============================================================================
  # stop
  
  test "stop sends stop message to driver" do
    :ok = assert Driver.stop( self() )
    assert_receive( {:"$gen_cast", :stop} )
  end


  #============================================================================
  # child_spec
  # need a custom child_spec because there can easily be multiple scenes running at the same time
  # they are all really Scenic.Scene as the GenServer module, so need to use differnt ids

  test "child_spec uses the scene module and id - no args" do
    self = self()
    %{
      id:       id,
      start:    {Driver, :start_link, [{^self, :config}]},
      type:     :worker,
      restart:  :permanent,
      shutdown: 500
    } = Driver.child_spec({self, :config})
    assert is_reference(id)
  end

  #============================================================================
  # child_spec
  test "init sends self :after_init" do
    self = self()
    Driver.init( {self, :config} )
    assert_receive( {:"$gen_cast", {:after_init, ^self, :config}})
  end

  #============================================================================
  # handle_info
  
  test "handle_info sends unhandles messages to the module" do
    {:noreply, new_state} = assert Driver.handle_info(:abc, %{
      driver_module: __MODULE__,
      driver_state: :driver_state
    })
    assert new_state.driver_state == :handle_info_state

    assert_receive( {:"$gen_cast",
      {:test_handle_info, :abc, :driver_state}
    } )
  end

  #============================================================================
  # handle_call
  
  test "handle_call sends unhandled messages to mod" do
    self = self()
    {:reply, resp, new_state} = assert Driver.handle_call(
      :other, self, %{
      driver_module: __MODULE__,
      driver_state: :driver_state
    })
    assert resp == :handle_call_reply
    assert new_state.driver_state == :handle_call_state

    assert_receive( {:"$gen_cast",
      {:test_handle_call, :other, ^self, :driver_state}
    } )
  end

  #============================================================================
  # handle_cast
  
  test "handle_cast :stop sends driver stop to viewport" do
    self = self()

    {:noreply, _} = assert Driver.handle_cast(:stop, %{
      viewport: self
    })

    assert_receive( {:"$gen_cast", {:stop_driver, ^self} } )
  end

  test "handle_cast sends unhandles messages to the module" do
    {:noreply, new_state} = assert Driver.handle_cast(:abc, %{
      driver_module: __MODULE__,
      driver_state: :driver_state
    })
    assert new_state.driver_state == :handle_cast_state

    assert_receive( {:"$gen_cast",
      {:test_handle_cast, :abc, :driver_state}
    } )
  end

end