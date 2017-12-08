#
#  Created by Boyd Multerer on 11/06/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# This is a simple tracker for detecting if an object or objects have been "clicked" on
# Mouse down starts on one of the ids, 
# Mouse up must also be on one of the ids to be counted as a click

# note that trackers do not need to be in this directory
# This is just a good place for the common ones


defmodule Scenic.ViewPort.Input.Tracker.Click do
  use Scenic.ViewPort.Input.Tracker
  alias Scenic.ViewPort.Input
  alias Scenic.Scene

#  import IEx

  #===========================================================================
  # The genserver part - tracks individual mouse clicks / gestures

  def start( target_button, target_id, target_uid, valid_uids, scene_pid \\ nil )
  def start( tb, tid, tuid, uid, pid ) when is_integer( uid), do: start( tb, tid, tuid, [uid], pid )
  def start( tb, tid, tuid, uids, nil ), do: start( tb, tid, tuid, uids, self() )
  def start( target_button, target_id, target_uid, valid_uids, scene_pid ) do

    # doing this so that tests can "mock" out the uid_fn and stop_fn
    # may also be nice in the future...
    # YES! this feels hacky. but I'm open to suggestions...
    uid_fn  = fn(pos) -> Scene.find_by_screen_pos(pos, scene_pid) end
    stop_fn = fn() -> Input.Tracker.stop() end 

    state = %{
      scene_pid:      scene_pid,
      target_id:      target_id,
      target_uid:     target_uid,
      valid_uids:     valid_uids,
      target_button:  target_button,
      uid_fn:         uid_fn,
      stop_fn:        stop_fn
    }
    Input.Tracker.start({__MODULE__,[]}, state)
  end

  #--------------------------------------------------------
  def init( state ) do
    # register to receive mouse button events
    Input.register( :mouse_button )
    {:ok, state }
  end

  #--------------------------------------------------------
  # bit of a cheat going straight for the release code of 0, but hey...
  def handle_input({:mouse_button, btn, action, _, pos}, state) do
    do_handle_input(btn, pos, action, state)
  end

  def handle_input(msg, state) do
    super(msg, state)
  end


  #--------------------------------------------------------
  defp do_handle_input(btn, pos, :release, %{
      scene_pid:      scene_pid,
      target_id:      target_id,
      target_uid:     target_uid,
      valid_uids:     valid_uids,
      target_button:  target_button,
      uid_fn:         uid_fn,
      stop_fn:        stop_fn
    } = state) when btn == target_button do

    # find the uid the button is over
    uid = uid_fn.(pos)

    # if the found uid is in the valid uid list, then send the click message note
    # that it is OK to have nil in the list if you want to click on the background
    if Enum.member?(valid_uids, uid) do
      GenServer.cast(scene_pid, {:input_uid, {:click, target_id, target_uid, pos}, uid})
    end

    # not enough to let the registry just catch that this process is going away.
    # need to tell the dirver too so that it doesn't spam the app with messages
    # so do this cleanly...
    Input.unregister( :mouse_button )

    # tear down this process - no longer needed
    stop_fn.()

    {:noreply, state}
  end

  defp do_handle_input(btn, _, _, %{stop_fn: stop_fn, target_button: t_btn} = state)
  when btn == t_btn do
    # tear down this process - no longer needed
    stop_fn.()
    {:noreply, state}
  end

  defp do_handle_input(_, _, _, state) do
    {:noreply, state}
  end
  
end