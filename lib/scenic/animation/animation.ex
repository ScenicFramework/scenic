#
#  Created by Boyd Multerer on 5/9/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# in general any given animation will story any private state it needs
# in the primitive's assigns map, with that animation's reference as the key.

defmodule Scenic.Animation do
  alias Scenic.Graph
#  alias Scenic.Scene
#  alias Scenic.Primitive
#  alias Scenic.Primitive.Style
  alias Scenic.Utilities

#  import IEx

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
  def build(callback_or_module, args)

  def build(callback, args) when is_function(callback, 3) do
    do_build(callback, args)
  end

  def build(module, args) when is_atom(module) do
    do_build(module, args)
  end

  def do_build(action, args) do
    ref = make_ref
    {
      :ok,
      {:animation, ref}.
      {:animation, ref, action, args, nil}
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
      {:animation, ref, action, args, nil}, g_acc ->
        case tick_animation( g_acc, 0, action, args ) do
          {:continue, %Graph{} = graph_out, args_out} ->
            {true, {ref, action, args_out, current_time}, graph_out }

          {:stop, %Graph{} = graph_out} ->
#            graph_out = stop_animation(graph_out, 0, action)
            {false, graph_out}
        end

      {:animation, ref, action, args, start_time}, g_acc ->
        case tick_animation( g_acc, current_time - start_time, action, args ) do
          {:continue, %Graph{} = graph_out, args_out} ->
            {true, {ref, action, args_out, start_time}, graph_out }

          {:stop, %Graph{} = graph_out} ->
#            graph_out = stop_animation(graph_out, current_time - start_time, action)
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
    {graph, animations}
  end


  #--------------------------------------------------------
  defp tick_animation(graph, elapsed_time, callback, data)
  defp tick_animation(graph, elapsed_time, callback, data) when is_function(callback, 3) do
    callback.(graph, elapsed_time, data)
  end
  defp tick_animation(graph, elapsed_time, module, data) do
    module.tick(graph, elapsed_time, data)
  end

  #--------------------------------------------------------
  # stop is only called for module-based animations
  # if you are returning stop from a callback, then you have already had the opportunity to stop...
  defp stop_animation(graph, elapsed_time, callback, data)
  defp stop_animation(graph, elapsed_time, module, data) when is_atom(module) do
    {:ok, graph} = module.stop(graph, elapsed_time, data)
    graph
  end
  defp stop_animation(graph, _, _, _), do: graph


end



