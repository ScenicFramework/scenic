#
#  Created by Boyd Multerer on 11/08/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#


defmodule Scenic.ViewPort.Input.Tracker.ClickTest do
  use ExUnit.Case, async: true
  use Bitwise
  doctest Scenic
  alias Scenic.ViewPort.Input.Tracker
  alias Scenic.ViewPort.Input.Tracker.Click

#  import IEx

  @input_registry   :input_registry

  #============================================================================
  # helpers
  def start_click_tracker() do
    start_opts = {
      self(),
      :target_id,
      [1,2,3],
      :left
    }

    {:ok, pid} = Tracker.start_link( {Click,[]}, start_opts )
    assert Process.alive?( pid )
    pid
  end

  #============================================================================
  # init

  test "init registers the click tracker for mouse_button input" do
    {:ok, :state} = Click.init( :state )
    keys = Registry.keys( @input_registry, self() )
    assert Enum.member?( keys, :mouse_button )
  end

  test "startup registers the click tracker for mouse_button input" do
    pid = start_click_tracker()
    keys = Registry.keys( @input_registry, pid )
    assert Enum.member?( keys, :mouse_button )
    GenServer.stop(pid)
  end


  #============================================================================
  # handle_input

  # can't test handle_input directly (as far as I can tell) becuase it exits it's 
  # process (normally) and I want to test for that...

  test "handle_input does nothing on events on other mouse buttons" do
    state = %{
      scene_pid:      self(),
      target_id:      :test_id,
      valid_uids:     [1,2,3],
      target_button:  :left,
      uid_fn:         fn(_) -> nil end,
      stop_fn:        fn() -> GenServer.cast(self(), :stopping) end
    }

    input = {:mouse_button, :right, :press, 0, {1,2}}
    {:noreply, _} = Click.handle_input(input, state)
    input = {:mouse_button, :right, :release, 0, {1,2}}
    {:noreply, _} = Click.handle_input(input, state)

    # confirm a driver update message was sent
    refute_received( {:"$gen_cast", :stopping} )
  end

  test "handle_input stops tracker on mouse release" do
    state = %{
      scene_pid:      self(),
      target_id:      :test_id,
      valid_uids:     [1,2,3],
      target_button:  :left,
      uid_fn:         fn(_) -> nil end,
      stop_fn:        fn() -> GenServer.cast(self(), :stopping) end
    }
    input = {:mouse_button, :left, :release, 0, {1,2}}
    {:noreply, _} = Click.handle_input(input, state)

    # confirm a driver update message was sent
    assert_received( {:"$gen_cast", :stopping} )
  end

  test "handle_input sends click on release in uid" do
    state = %{
      scene_pid:      self(),
      target:         :test_target,
      valid_uids:     [1,2,3],
      target_button:  :left,
      uid_fn:         fn(_) -> 2 end,
      stop_fn:        fn() -> :ok end
    }
    input = {:mouse_button, :left, :release, 0, {1,2}}
    {:noreply, _} = Click.handle_input(input, state)

    # confirm a driver update message was sent
    assert_received( {:"$gen_cast", {:input_uid, {:click, :test_target, {1, 2}}, 2}} )
  end

  test "handle_input does NOT send on click release outside uid" do
    state = %{
      scene_pid:      self(),
      target_id:      :test_id,
      valid_uids:     [1,2,3],
      target_button:  :left,
      uid_fn:         fn(_) -> 4 end,
      stop_fn:        fn() -> :ok end
    }
    input = {:mouse_button, :left, :release, 0, {1,2}}
    {:noreply, _} = Click.handle_input(input, state)

    # assert the process mailbox is empty
    assert Process.info(self(), :messages) == {:messages, []}
  end

  test "handle_input does NOT send on click press outside uid" do
    state = %{
      scene_pid:      self(),
      target_id:      :test_id,
      valid_uids:     [1,2,3],
      target_button:  :left,
      uid_fn:         fn(_) -> 4 end,
      stop_fn:        fn() -> :ok end
    }
    input = {:mouse_button, :left, :press, 0, {1,2}}
    {:noreply, _} = Click.handle_input(input, state)

    # assert the process mailbox is empty
    assert Process.info(self(), :messages) == {:messages, []}
  end

  test "handle_input stops tracker on mouse press - no click message sent" do
    state = %{
      scene_pid:      self(),
      target_id:      :test_id,
      valid_uids:     [1,2,3],
      target_button:  :left,
      uid_fn:         fn(_) -> 2 end,
      stop_fn:        fn() -> GenServer.cast(self(), :stopping) end
    }
    input = {:mouse_button, :left, :press, 0, {1,2}}
    {:noreply, _} = Click.handle_input(input, state)

    # confirm a driver update message was sent
    assert_received( {:"$gen_cast", :stopping} )
    refute_received( {:"$gen_cast", {:input_uid, {:click, :test_id, {1, 2}}, 2}} )
  end
end
