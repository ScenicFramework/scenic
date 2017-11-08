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

  import IEx

  @input_registry    :input_registry


  #============================================================================
  # helpers
  def start_click_tracker() do
    {:ok, pid} = Tracker.start_link( {Click,[]}, nil )
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
    {:ok, pid} = Tracker.start_link( {Click,[]}, nil )
    keys = Registry.keys( @input_registry, pid )
    assert Enum.member?( keys, :mouse_button )
    GenServer.stop(pid)
  end


  #============================================================================
  # handle_input

  test "handle_input does nothing on events on other mouse buttons"

  test "handle_input stops tracker on mouse release" do
    {:ok, pid} = Tracker.start_link( {Click,[]}, nil )
    assert Process.alive?( pid )


    refute Process.alive?( pid )
  end


  test "handle_input stops tracker on mouse press"

  test "handle_input sends click on release in uid"
  test "handle_input does NOT send on click release outside uid"
  test "handle_input does NOT send on click press outside uid"

end
