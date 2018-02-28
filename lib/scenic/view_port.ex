#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort do
#  use GenServer
  alias Scenic.ViewPort.Driver
  require Logger

  import IEx

  @viewport_registry    :viewport_registry

  #============================================================================
  # client api

  # can't just make the scene calls directly as set_scene can be called
  # before the Scene's themselves have actually been initialized. For example,
  # an app may call set_scene during it's start function to set things up.

  def set_scene( scene_id, scene_param \\ nil )
  def set_scene( scene_name, scene_param ) when is_atom(scene_name) do
    Process.whereis( scene_name )
    |> set_scene( scene_param )
  end
  def set_scene( scene_pid, scene_param ) when is_pid(scene_pid) do
    GenServer.cast( scene_pid, {:set_scene, scene_param} )
  end


  ###############
  # No longer sure these belong here. Maybe just on the driver?
  #--------------------------------------------------------
  def set_root_graph( _scene_id ) do
#    Driver.set_root_graph( scene_id )
  end

  #--------------------------------------------------------
  def set_graph( scene_id, graph_list )
  def set_graph( _scene_id, graph_list ) do
#    Driver.set_graph( scene_id, graph_list )
    case current_scene?() do
      true ->   Driver.set_graph( graph_list )
      false ->  :context_lost
    end
  end

  #--------------------------------------------------------
  def update_graph( scene_id, delta_list )
  def update_graph( _scene_id, delta_list ) do
#    Driver.update_graph( scene_id, delta_list )
    case current_scene?() do
      true ->
        Driver.update_graph( delta_list )
      false ->
        :context_lost
    end
  end

  #----------------------------------------------
  def delete_graph( _scene_id ) do
#    Driver.delete_graph( scene_id )
  end
  ###############





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

  #----------------------------------------------
  # a graphic driver is requesting this scene identify itself
  # as the current scene. Used when a new driver is coming online.
  # could just use the scene pid, but this gives the scene a chance
  # to add other identifying information to the graph_id
#  def request_current() do
#    case current_scene() do
#      nil -> {:err, :no_scene_set}
#      pid ->
#        GenServer.cast(pid, {:request_identify, :set_root_graph, self()})
#    end
#  end

  #----------------------------------------------
  # a graphic driver is requesting this scene send a full graph list
  def request_set() do
    case current_scene() do
      nil ->
        {:err, :no_scene_set}
      pid ->
        GenServer.cast(pid, {:request_set, self()})
    end
  end

end
















