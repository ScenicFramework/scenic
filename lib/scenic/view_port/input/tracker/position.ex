#
#  Created by Boyd Multerer on 11/06/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# This is a simple tracker for detecting if an object or objects have been "clicked" on
# Mouse down starts on one of the ids, 
# Mouse up must also be on one of the ids to be counted as a click

# note that trackers do not need to be in this directory
# This is just a good place for the common ones


defmodule Scenic.ViewPort.Input.Tracker.Position do
  use Scenic.ViewPort.Input.Tracker
  alias Scenic.ViewPort.Input

#  import IEx

  #===========================================================================
  # The genserver part - tracks individual mouse clicks / gestures

  def start( target_button, target, cookie, scene_pid \\ nil )
  def start( tb, target, cookie, nil ), do: start( tb, target, cookie, self() )
  def start( target_button, target, cookie, scene_pid ) do

    # doing this so that tests can "mock" out the uid_fn and stop_fn
    # may also be nice in the future...
    # YES! this feels hacky. but I'm open to suggestions...
#    uid_fn  = fn(pos) -> Scene.find_by_screen_pos(pos, scene_pid) end
#    stop_fn = fn() -> Input.Tracker.stop() end 

    state = %{
      scene_pid:      scene_pid,
      target:         target,
      cookie:         cookie,
      target_button:  target_button,
#      uid_fn:         uid_fn,
#      stop_fn:        stop_fn
    }
    Input.Tracker.start({__MODULE__,[]}, state)
  end

  #--------------------------------------------------------
  def init( state ) do
    # register to receive mouse button events
    Input.register( [:cursor_button, :cursor_pos] )
    {:ok, state }
  end

  #--------------------------------------------------------
  # any change in mouse button state stops this tracker
  def handle_input({:cursor_button, _, _, _, _}, state) do
    Input.unregister( :all )
    Input.Tracker.stop()
    {:noreply, state}
  end

  #--------------------------------------------------------
  # any change in mouse button state stops this tracker
  def handle_input({:cursor_pos, pos}, %{scene_pid: scene_pid, cookie: cookie, target: %{uid: uid}} = state) do
    GenServer.cast(scene_pid, {:input_uid, {:position, pos, cookie}, uid})
    {:noreply, state}
  end

  def handle_input(msg, state) do
    IO.inspect(msg)
    super(msg, state)
  end
  
end