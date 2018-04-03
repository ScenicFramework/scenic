#
#  Created by Boyd Multerer on 4/3/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Animation do
  alias Scenic.Graph
  alias Scenic.Utilities

  import IEx

  @callback add_to_graph(map, any, atom | {atom,atom} | function) :: map

  @callback tick(any, integer, any) :: {:continue, any, any} | {:stop, any}
  @callback stop(any, integer, any) :: {:ok, any}

  #===========================================================================
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Animation


      def append(animations, data, opts \\ [])
      def append(animations, data, opts) when is_list(animations) do
        Scenic.Animation.append( animations, __MODULE__, data, opts )
      end

      def stop(graph, elapsed_time, args), do: {:ok, graph}

#      def filter_input(event, primitive, graph),    do: {:continue, event, graph}

      #--------------------------------------------------------
      defoverridable [
        append:       3,
        stop:         3
      ]
    end # quote
  end # defmacro


  #--------------------------------------------------------
  def build(args, module_or_tick_callback)
  def build(args, tick_callback) when is_function(tick_callback, 3) do
    do_build(args, {tick_callback, nil} )
  end
  def build( args, module ) when is_atom(module) do
    do_build( args, module )
  end

  def build(args, tick_callback, stop_callback)
  def build(args, tick_callback, stop_callback)
  when is_function(tick_callback, 3) and is_function(stop_callback, 3) do
    do_build(args, {tick_callback, nil} )
  end

  def do_build(args, actions) do
    ref = make_ref
    {
      :ok,
      {:animation, ref}.
      {:animation, ref, actions, args, nil}
    }
  end

  #--------------------------------------------------------
  def append( animations, callback_or_module, args ) when is_list(animations) do
    {:ok, ref, entry} = build(callback_or_module, args)
  end

  #--------------------------------------------------------
  @doc """
  Tick all the animations in the list against the graph

  Returns {list, graph}
  """
  def tick( graph, animations ) do
    # get the time before entering the loop, so it is consistent across
    # multiple animation steps
    current_time = :os.system_time(:milli_seconds)
    {animations, graph} = Utilities.Enum.filter_map_reduce(animations, graph, fn
      {:animation, ref, actions, args, start_time}, g_acc ->

        start_time = case start_time do
          nil -> current_time
          time -> time
        end
        elapsed_time = current_time - start_time

        case tick_animation( g_acc, elapsed_time, actions, args ) do
          {:continue, %Graph{} = graph_out, args_out} ->
            {true, {ref, actions, args_out, current_time}, graph_out }

          {:stop, %Graph{} = graph_out} ->
            {:ok, graph_out} = stop_animation(graph_out, elapsed_time, actions, args)
            {false, graph_out}
        end
    end)
    {graph, animations}
  end

  #--------------------------------------------------------
  @doc """
  Stop an animation and remove it from the list. Gives it
  an opportunity to transform the graph one last time.
  """
  def stop(graph, animations, {:animation, stop_ref} ) do
    current_time = :os.system_time(:milli_seconds)
    {animations, graph} = Utilities.Enum.filter_reduce(animations, graph, fn
      {:animation, ^stop_ref, actions, args, start_time}, g ->
        start_time = case start_time do
          nil -> current_time
          time -> time
        end
        elapsed_time = current_time - start_time

        # Give it a chance to transform the graph once more
        {:ok, g} = stop_animation(g, elapsed_time, actions, args)

        # filter out this animation
        {false, g}

      keeper, g ->
        {true, g}
    end) 
    {graph, animations}
  end


  #--------------------------------------------------------
  defp tick_animation(graph, elapsed_time, actions, data)
  defp tick_animation(graph, elapsed_time, module, data) when is_atom(module) do
    module.tick(graph, elapsed_time, data)
  end
  defp tick_animation(graph, elapsed_time, {tick_action, _}, data) when is_function(tick_action, 3) do
    tick_action.(graph, elapsed_time, data)
  end

  #--------------------------------------------------------
  # stop is only called for module-based animations
  # if you are returning stop from a callback, then you have already had the opportunity to stop...
  defp stop_animation(graph, elapsed_time, callback, data)
  defp stop_animation(graph, elapsed_time, module, data) when is_atom(module) do
    module.stop(graph, elapsed_time, data)
  end
  defp stop_animation(graph, elapsed_time, {_, stop_action}, data) when is_function(stop_action, 3) do
    stop_action.(graph, elapsed_time, data)
  end
  defp stop_animation(graph, _, _, _), do: {:ok, graph}


end



