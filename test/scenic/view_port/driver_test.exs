#
#  Created by Boyd Multerer on 11/08/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


defmodule Scenic.ViewPort.DriverTest do
  use ExUnit.Case, async: false
  use Bitwise
  doctest Scenic
  alias Scenic.ViewPort.Driver

#  import IEx

  @driver_registry      :driver_registry
  @viewport_registry    :viewport_registry

  @sync_message         :timer_sync

  defp verify_registries() do
    assert Registry.keys(@driver_registry, self()) == []
  end

  #============================================================================
  # set_root_graph

  test "set_root_graph sends a graph_id to the driver" do
    verify_registries()
    # register to receive :set_graph calls
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # set a graph (list)
    Driver.set_root_graph( 0 )

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:set_root_graph, 0}}  )
  end


  #============================================================================
  # set_graph

  test "set_graph sends a list to the driver" do
    verify_registries()
    # register to receive :set_graph calls
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # set a graph (list)
    Driver.set_graph( 0, [1,2,3] )

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:set_graph, {0, [1, 2, 3]}}}  )
  end


  #============================================================================
  # update_graph

  test "update_graph sends a list to the driver" do
    verify_registries()
    # register to receive :update_graph calls
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # set a graph (list)
    Driver.update_graph( 0, [1,2,3] )

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:update_graph, {0, [1, 2, 3]}}}  )
  end

  test "update_graph does NOT send an empty list to the driver" do
    verify_registries()
    # register to receive :update_graph calls
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # set a graph (list)
    Driver.update_graph( 0, [] )

    # make sure it was sent
    refute_receive( {:"$gen_cast", {:update_graph, {0, []}}}  )
  end

  #============================================================================
  # delete_graph

  test "delete_graph sends a graph_id to the driver" do
    verify_registries()
    # register to receive :set_graph calls
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # set a graph (list)
    Driver.delete_graph( 0 )

    # make sure it was sent
    assert_receive( {:"$gen_cast", {:delete_graph, 0}}  )
  end

  #============================================================================
  # identify

  test "identify returns a list of active drivers and their options" do
    verify_registries()
    # register to receive :set_graph calls
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, [a: 1, b: 2]} )

    # get the list of drivers
    assert Driver.identify() == [{{__MODULE__, [a: 1, b: 2]}, self()}]
  end

  #============================================================================
  # cast

  test "cast casts a message to the drivers" do
    verify_registries()
    # register to receive :set_graph calls
    {:ok, _} = Registry.register(@driver_registry, :driver, {__MODULE__, 123} )

    # set a graph (list)
    Driver.cast( :test_message )

    # make sure it was sent
    assert_receive( {:"$gen_cast", :test_message}  )
  end


  #============================================================================
  # faux mod callbacks
  def init( _ ) do
    {:ok, :init_state}
  end

  def handle_call( :call_msg, :from, :faux_state ) do
    {:reply, :handle_call_reply, :handle_call_state}
  end

  def handle_cast( :cast_msg, :faux_state ) do
    {:noreply, :handle_cast_state}
  end

  def handle_cast( {:set_graph, {_, _}}, :faux_state ) do
    {:noreply, :set_graph_state}
  end

  def handle_cast( {:update_graph, {_, _}}, :faux_state ) do
    {:noreply, :update_graph_state}
  end

  def handle_cast( _, :faux_state ) do
    {:noreply, :generic_state}
  end

  def handle_input( {:key, :a, :press, 3}, :faux_state ) do
    {:noreply, :handle_input_state}
  end

  def handle_info( :info_msg, :faux_state ) do
    {:noreply, :handle_info_state}
  end

  def default_sync_interval(), do: 63

  @state %{
    driver_module:  __MODULE__,
    driver_state:   :faux_state,
    sync_interval:  nil
  }

  #--------------------------------------------------------
  # input
  test "no sync interval in opts uses the driver's default" do
    {:ok, state} = Driver.init( {__MODULE__, []} )
    %{
      driver_module:  __MODULE__,
      driver_state:   :init_state,
      sync_interval:  63
    } = state
  end

  test "init accepts a nil sync interval" do
    {:ok, state} = Driver.init( {__MODULE__, [sync_interval: nil]} )
    %{
      driver_module:  __MODULE__,
      driver_state:   :init_state,
      sync_interval:  nil
    } = state
  end

  test "init accepts a sync interval" do
    {:ok, state} = Driver.init( {__MODULE__, [sync_interval: 64]} )
    %{
      driver_module:  __MODULE__,
      driver_state:   :init_state,
      sync_interval:  64,
      last_msg:       last_msg,
      timer:          {:interval, timer_ref}
    } = state
    assert is_integer(last_msg)
    assert is_reference(timer_ref)
  end

  test "init rejects a non-int sync interval" do
    assert_raise Driver.Error, fn ->
      Driver.init( {__MODULE__, [sync_interval: :invalid]} )
    end
  end

  test "init rejects negative sync intervals" do
    assert_raise Driver.Error, fn ->
      Driver.init( {__MODULE__, [sync_interval: -64]} )
    end
  end

  #--------------------------------------------------------
  # handle_call

  test "handle_call just passes up to the module" do
    {:reply, :handle_call_reply, state} = Driver.handle_call( :call_msg, :from, @state )
    %{ driver_state: :handle_call_state } = state
  end

  #--------------------------------------------------------
  # handle_cast
  
  test "handle_cast passes unknown messages up to the module" do
    {:noreply, state} = Driver.handle_cast( :cast_msg, @state )
    %{ driver_state: :handle_cast_state } = state
  end

  #--------------------------------------------------------
  # handle_cast :set_graph and :update_graph
  test "handle_cast :set_graph calls the module and updates last_msg" do
    {:noreply, state} = Driver.handle_cast( {:set_graph, {0, [1,2,3]}}, @state )
    %{ driver_state: :set_graph_state, last_msg: time } = state
    assert is_integer(time)
  end

  test "handle_cast :update_graph calls the module and updates last_msg" do
    {:noreply, state} = Driver.handle_cast( {:update_graph, {0, [1,2,3]}}, @state )
    %{ driver_state: :update_graph_state, last_msg: time } = state
    assert is_integer(time)
  end

  test "handle_cast :update_graph shorts the module if delta is empty" do
    {:noreply, state} = Driver.handle_cast( {:update_graph, {0, []}}, @state )
    %{ driver_state: :faux_state } = state
  end

  #--------------------------------------------------------
  # handle_info

  def handle_sync(:faux_state) do
    {:noreply, :sync_state}
  end


  test "handle_info passes unknown messages up to the module" do
    {:noreply, state} = Driver.handle_info( :info_msg, @state )
    %{ driver_state: :handle_info_state } = state
  end
  
  test "handle_info sync signals the scene" do
    # set up to receive the signal
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )

    state = @state
    |> Map.put( :last_msg, 0 )
    |> Map.put( :sync_interval, 64 )

    {:noreply, state} = Driver.handle_info( @sync_message, state )
    %{ driver_state: :sync_state } = state

    assert_receive( {:"$gen_cast", :graph_update}  )
  end

  test "handle_info sync does not signal the scene if last_msg is recent" do
    # set up to receive the signal
    {:ok, _} = Registry.register(@viewport_registry, :messages, self() )

    state = @state
    |> Map.put( :last_msg, :os.system_time(:millisecond) )
    |> Map.put( :sync_interval, 64 )

    {:noreply, state} = Driver.handle_info( @sync_message, state )
    %{ driver_state: :faux_state } = state

    refute_receive( {:"$gen_cast", :graph_update}  )
  end

end







