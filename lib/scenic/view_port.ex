#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort do
  use GenServer
  alias Scenic.ViewPort.Driver
  require Logger

#  import IEx

#  @name                 :view_port

  @viewport_registry    :viewport_registry

  #============================================================================
  # client api

  def set_scene( scene_id, viewport_id \\ @name )
  def set_scene( scene_name, viewport_id ) when is_atom(scene_name) do
    Process.whereis( scene_name )
    |> set_scene( viewport_id )
  end
  def set_scene( scene_pid, viewport_id ) when is_pid(scene_pid) do
    case current_scene() do
      nil -> 
        # tell the new scene to register itself
        GenServer.call( scene_pid, {:register, @viewport_registry})
        :ok
      old_scene ->
        # tell the old scene to unregister itself
        case GenServer.call( old_scene, {:unregister, @viewport_registry}) do
          :ok -> 
            # tell the new scene to register itself
            GenServer.call( scene_pid, {:register, @viewport_registry})
            :ok
          other -> other
        end
    end
  end

  #--------------------------------------------------------
  def set_graph( min_graph )
  def set_graph( min_graph ) do
    case current_scene?() do
      true ->   Driver.set_graph( min_graph )
      false ->  :context_lost
    end
  end

  #--------------------------------------------------------
  def update_graph( deltas )
  def update_graph( deltas ) do
    case current_scene?() do
      true ->
        # calculate the deltas
        Driver.update_graph( deltas )
      false ->
        :context_lost
    end
  end

  #--------------------------------------------------------
  def current_scene()
  def current_scene() do
    case Registry.lookup(@viewport_registry, :messages) do
      [] -> nil
      [{_,current_scene_pid}] -> current_scene_pid
      _  -> nil
    end
  end

  #--------------------------------------------------------
  def current_scene?( scene_id \\ nil )
  def current_scene?( nil ), do: current_scene?( self() )
  def current_scene?( scene_name ) when is_atom(scene_name) do
    Process.whereis( scene_name )
    |> current_scene?()
  end
  def current_scene?( scene_pid ) when is_pid(scene_pid) do
    case Registry.lookup(@viewport_registry, :messages) do
      [] -> false
      [{_,current_scene_pid}] -> current_scene_pid == scene_pid
      _  -> false
    end
  end


  #----------------------------------------------
  def send_to_scene( message ) do
    case current_scene() do
      nil -> {:err, :no_scene_set}
      pid -> GenServer.cast(pid, message)
    end
  end


  #============================================================================
  # setup the viewport

#  def start_link( sup ) do
#    GenServer.start_link(__MODULE__, sup, name: @name)
#  end
#
#  def init( _ ) do
#    {:ok, nil}
#  end

  #============================================================================
  # internal support

  #--------------------------------------------------------
#  def handle_cast( {:set_scene, scene_id}, state ) when is_pid(scene_id) or is_atom(scene_id) do
#    # unregister the current scene
#    Registry.unregister(@viewport_registry, :messages)
#
#    # register the new scene for resets
#    Registry.register(@viewport_registry, :messages, scene_id )
#
#    # reset the graph
#    GenServer.cast( scene_id, :graph_reset )
#
#    # save the scene and return
#    {:noreply, state}
#  end

end