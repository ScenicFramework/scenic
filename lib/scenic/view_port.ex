#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort do
  use GenServer
  alias Scenic.Graph
require Logger
#  import IEx

  @name                 :view_port

  @viewport_registry    :viewport_registry

  #============================================================================
  # client api

  def set_scene( scene_id, viewport_id \\ @name )
  def set_scene( scene_name, viewport_id ) when is_atom(scene_name) do
    Process.whereis( scene_name )
    |> set_scene( viewport_id )
  end
  def set_scene( scene_pid, viewport_id ) when is_pid(scene_pid) do
    # let the new scene know it has the context
    GenServer.cast( viewport_id, {:set_scene, scene_pid})
  end

  #--------------------------------------------------------
  def set_graph( graph )
  def set_graph( %Graph{} = graph ) do
    min = Graph.minimal( graph )
    case current_scene?() do
      true ->   Scenic.ViewPort.Driver.set_graph( min )
      false ->  :context_lost
    end
  end

  #--------------------------------------------------------
  def update_graph( graph )
  def update_graph( %Graph{} = graph ) do
    case current_scene?() do
      true ->
        # calculate the deltas
        deltas = Graph.get_delta_scripts( graph )
        Scenic.ViewPort.Driver.update_graph( deltas )
      false ->
        :context_lost
    end
  end

  #--------------------------------------------------------
  def current_scene()
  def current_scene() do
    case Registry.lookup(@viewport_registry, :graph_reset) do
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
    case Registry.lookup(@viewport_registry, :graph_reset) do
      [] -> false
      [{_,current_scene_pid}] -> current_scene_pid == scene_pid
      _  -> false
    end
  end


  #----------------------------------------------
  def signal_scene( signal ) do
    # needs a different dispatcher than sending a message to the driver.
    # there is only one current scene, and that is in the viewport_registry

    # dispatch the call to any listening drivers
    Registry.dispatch(@viewport_registry, signal, fn(entries) ->
      for {_vp_pid, scene_pid} <- entries do
        try do
          GenServer.cast(scene_pid, signal)
        catch
          kind, reason ->
            formatted = Exception.format(kind, reason, System.stacktrace)
            Logger.error "Registry.dispatch/3 failed with #{formatted}"
        end
      end
    end)
  end

  #============================================================================
  # setup the viewport

  def start_link( sup ) do
    GenServer.start_link(__MODULE__, sup, name: @name)
  end

  def init( _ ) do
    {:ok, nil}
  end

  #============================================================================
  # internal support

  #--------------------------------------------------------
  def handle_cast( {:set_scene, scene_id}, state ) when is_pid(scene_id) or is_atom(scene_id) do
    # unregister the current scene
    Registry.unregister(@viewport_registry, :graph_update)
    Registry.unregister(@viewport_registry, :graph_reset)

    # register the new scene for resets
    Registry.register(@viewport_registry, :graph_reset, scene_id )

    # reset the graph
    GenServer.cast( scene_id, :graph_reset )

    # register the new scene for updates
    Registry.register(@viewport_registry, :graph_update, scene_id )

    # save the scene and return
    {:noreply, state}
  end

end