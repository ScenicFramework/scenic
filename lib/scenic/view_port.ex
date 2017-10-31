#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort do
  use GenServer
  alias Scenic.Graph


#  import IEx

  @name                 :view_port

  @context_table        :vp_context_tracking_table
  @context              :context
  @error_bad_context    :error_bad_context

  #============================================================================
  # client api

  def set_scene( scene_id, view_port_id \\ :view_port )
  def set_scene( nil, view_port_id ) do
    set_scene( self(), view_port_id )
  end
  def set_scene( scene_id, view_port_id ) when is_pid(scene_id) or is_atom(scene_id) do
    GenServer.cast( view_port_id, {:set_scene, scene_id})
  end

  #--------------------------------------------------------
  def set_graph( context , graph )
  def set_graph( context , %Graph{} = graph ) do
    min = Graph.minimal( graph )
    case current_context?( context ) do
      true ->   Scenic.ViewPort.Driver.set_graph( min )
      false ->  :context_lost
    end
  end

  #--------------------------------------------------------
  def update_graph( context, graph )
  def update_graph( context, %Graph{} = graph ) do
    # calculate the deltas
    deltas = Graph.get_delta_scripts( graph )
    case current_context?( context ) do
      true ->   Scenic.ViewPort.Driver.update_graph( deltas )
      false ->  :context_lost
    end
  end

  #--------------------------------------------------------
  def driver_message( message, view_port_id \\ :view_port ) do
    GenServer.cast( view_port_id, {:driver_message, message} )
  end

  #============================================================================
  # setup the viewport

  def start_link( sup ) do
    GenServer.start_link(__MODULE__, sup, name: @name)
  end

  def init( supervisor ) do
    init_context_tracking()
    {:ok, _} = Registry.register(:viewport_registry, :client_message, :driver_message )
    {:ok, %{supervisor: supervisor}}
  end

  #============================================================================
  # internal support

  #--------------------------------------------------------
  def handle_cast( {:set_scene, scene_id}, state ) when is_pid(scene_id) or is_atom(scene_id) do
    # Generate a new context
    new_context = make_context()

    # set the new context as the current one in the ets table
    track_current_context( new_context )

    # let the new scene know it has the context
    GenServer.cast( scene_id, {:context_gained, new_context})

    # save the scene and return
    {:noreply, Map.put(state, :scene, scene_id)}
  end


  #--------------------------------------------------------
  def handle_cast( {:driver_message, :update}, %{scene: scene} = state ) do
    GenServer.cast( scene, :vp_update )
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast( {:driver_message, :reset}, %{scene: scene} = state ) do
    GenServer.cast( scene, :vp_reset )
    {:noreply, state}
  end

  #--------------------------------------------------------
  def handle_cast( {:driver_message, msg}, state ) do
    IO.puts("Unknown driver message at ViewPort: #{inspect(msg)}")
    {:noreply, state}
  end

  #============================================================================
  # use an ets table to prevent two scenes from trying to update the viewport at
  # the same time. Only the currently registered context should get through.


  defp make_context(), do: {@context, make_ref(), self()}

  #--------------------------------------------------------
  defp init_context_tracking() do
    case :ets.info(@context_table) do
      :undefined ->
        :ets.new( @context_table, [:named_table, :set, :public] )
      _ -> @context_table
    end
  end

  #--------------------------------------------------------
  defp track_current_context( {:context, context_ref, _ }) when is_reference(context_ref) do
    :ets.insert(@context_table, {self(), context_ref})
  end

  #--------------------------------------------------------
  def current_context( vp_pid \\ @name ) when is_pid(vp_pid) do
    case :ets.lookup( @context_table, vp_pid ) do
      [{_, {:context, ref, internal}}] ->   {:ok, {:context, ref, internal}}
      _ ->                                  {:err, :bad_context}
    end
  end

  #--------------------------------------------------------
  def current_context!( vp_pid \\ @name ) when is_pid(vp_pid) do
    case :ets.lookup( @context_table, vp_pid ) do
      [{_, {:context, ref, internal}}] ->   {:context, ref, internal}
      _ ->                                  raise "bad context"
    end
  end

  #--------------------------------------------------------
  def current_context?( context )
  def current_context?( {@context, ref, vp_pid} ) when is_pid(vp_pid) and is_reference(ref) do
    case :ets.lookup( @context_table, vp_pid ) do
      [{_, ^ref}] ->  true
      _ ->            false
    end
  end
  def current_context?( _ ), do: @error_bad_context


end