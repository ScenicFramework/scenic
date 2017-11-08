#
#  Created by Boyd Multerer on 11/08/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


defmodule Scenic.ViewPort.Input.TrackerTest do
  use ExUnit.Case, async: true
  use Bitwise
  doctest Scenic
  alias Scenic.ViewPort.Input.Tracker

#  import IEx

  @state %{
    tracker_module:  __MODULE__,
    tracker_state:   :faux_state,
  }

  #============================================================================
  # faux tracker mod callbacks
  def init( opts ) do
    assert opts == [1,2,3]
    {:ok, :init_state}
  end

  def handle_call( :call_msg, :from, :faux_state ) do
    {:reply, :handle_call_reply, :handle_call_state}
  end

  def handle_cast( :cast_msg, :faux_state ) do
    {:noreply, :handle_cast_state}
  end

  def handle_input( {:key, :a, :press, 3}, :faux_state ) do
    {:noreply, :handle_input_state}
  end

  def handle_info( :info_msg, :faux_state ) do
    {:noreply, :handle_info_state}
  end

  #============================================================================

  #--------------------------------------------------------
  # input
  test "input works and lets the module set up it's data" do
    {:ok, state} = Tracker.init( {__MODULE__, [1,2,3]} )
    assert state == %{
      tracker_module:  __MODULE__,
      tracker_state:   :init_state
    }
  end

  #--------------------------------------------------------
  # handle_call
  test "handle_call just passes up to the module" do
    {:reply, :handle_call_reply, state} = Tracker.handle_call( :call_msg, :from, @state )
    assert state == %{
      tracker_module: __MODULE__,
      tracker_state:  :handle_call_state
    }
  end

  #--------------------------------------------------------
  # handle_cast
  
  test "handle_cast passes unknown messages up to the module" do
    {:noreply, state} = Tracker.handle_cast( :cast_msg, @state )
    assert state == %{
      tracker_module: __MODULE__,
      tracker_state:  :handle_cast_state
    }
  end

  #--------------------------------------------------------
  # handle_cast -> handle_input
  test "handle_cast normalizes input before passing it up to handle_input" do
    {:noreply, state} = Tracker.handle_cast( {:input, {:key, {65, 1, 3}}}, @state )
    assert state == %{
      tracker_module: __MODULE__,
      tracker_state:  :handle_input_state
    }
  end

  #--------------------------------------------------------
  # handle_info
  
  test "handle_info passes unknown messages up to the module" do
    {:noreply, state} = Tracker.handle_info( :info_msg, @state )
    assert state == %{
      tracker_module: __MODULE__,
      tracker_state:  :handle_info_state
    }
  end

end