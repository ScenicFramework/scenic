#
#  Created by Boyd Multerer on 4/3/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Animation do
  alias Scenic.Graph
  alias Scenic.Utilities
  alias Scenic.Animation

  @callback make(map, any) :: {map, {:animation, integer}}
  @callback tick(any, integer, any) :: {:continue, any, any} | {:stop, any}
  @callback stop(any, integer, any) :: {:ok, any}

  #===========================================================================
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Animation


      def make(animations, data)
      def make(animations, data) when is_list(animations) do
        Scenic.Animation.make( animations, data, __MODULE__ )
      end

      def stop(graph, elapsed_time, args), do: {:ok, graph}

      #--------------------------------------------------------
      defoverridable [
        make:         2,
        stop:         3
      ]
    end # quote
  end # defmacro

  #--------------------------------------------------------
  def make( animations, args, module_or_callbacks )

  def make( %{} = animations, args, module ) when is_atom(module) do
    ref = make_animation_ref( animations )
    entry = {module, args, nil}
    {Map.put(animations, ref, entry), ref}
  end

  def make( %{} = animations, args, tick_callback ) when is_function(tick_callback, 3) do
    ref = make_animation_ref( animations )
    entry = {{tick_callback, nil}, args, nil}
    {Map.put(animations, ref, entry), ref}
  end

  def make( %{} = animations, args, tick_callback, stop_callback ) 
  when is_function(tick_callback, 3) and is_function(stop_callback, 3) do
    ref = make_animation_ref( animations )
    entry = {{tick_callback, stop_callback}, args, nil}
    {Map.put(animations, ref, entry), ref}
  end

  #--------------------------------------------------------
  def make!( animations, args, module_or_tick_callbacks )

  def make!( %{} = animations, args, module ) when is_atom(module) do
    ref = make_animation_ref( animations )
    entry = {module, args, nil}
    Map.put(animations, ref, entry)
  end

  def make!( %{} = animations, args, tick_callback ) when is_function(tick_callback, 3) do
    ref = make_animation_ref( animations )
    entry = {{tick_callback, nil}, args, nil}
    Map.put(animations, ref, entry)
  end

  def make!( %{} = animations, args, tick_callback, stop_callback ) 
  when is_function(tick_callback, 3) and is_function(stop_callback, 3) do
    ref = make_animation_ref( animations )
    entry = {{tick_callback, stop_callback}, args, nil}
    Map.put(animations, ref, entry)
  end

  #--------------------------------------------------------
  @doc """
  Tick all the animations in the list against the graph

  Returns {list, graph}
  """
  def tick( %{} = animations, %Graph{} = graph ) do
    # get the time before entering the loop, so it is consistent across
    # multiple animation steps
    current_time = :os.system_time(:milli_seconds)

    # enumerate the elements and run each
    Utilities.Enum.filter_map_reduce(animations, graph, fn
      {ref, {actions, args, start_time}}, g_acc ->

        start_time = case start_time do
          nil -> current_time
          time -> time
        end
        elapsed_time = current_time - start_time

        case tick_animation( g_acc, elapsed_time, actions, args ) do
          {:continue, %Graph{} = graph_out, args_out} ->
            {true, {ref, {actions, args_out, current_time}}, graph_out }

          {:stop, %Graph{} = graph_out} ->
            {:ok, graph_out} = stop_animation(graph_out, elapsed_time, actions, args)
            {false, graph_out}
        end
    end)
  end

  #--------------------------------------------------------
  @doc """
  Stop an animation and remove it from the list. Gives it
  an opportunity to transform the graph one last time.
  """
  def stop(%Graph{} = graph, %{} = animations, {:animation, _} = ref ) do
    current_time = :os.system_time(:milli_seconds)

    # pop the animation element
    case Map.pop(animations, ref) do
      {nil, _} ->
        {graph, animations}

      {{actions, args, start_time}, animations} ->
        start_time = case start_time do
          nil -> current_time
          time -> time
        end
        elapsed_time = current_time - start_time
        # Give it a chance to transform the graph once more
        {:ok, graph} = stop_animation(graph, elapsed_time, actions, args)
        {graph, animations}
    end
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


  #============================================================================
  # internal utilities

  # not using make_ref here because I want to be able to build up the animation
  # map during compile time. make_ref only works during runtime. This is less
  # elegent but allows it to be pre-compiled.
  defp make_animation_ref( animations ) do
    r = :rand.uniform(0xFFFFFFF)
    case Map.has_key?(animations, r) do
      true -> make_animation_ref( animations )
      false -> {:animation, r}
    end
  end

end









































