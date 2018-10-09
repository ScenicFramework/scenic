#
#  Created by Boyd Multerer on 2017-11-05.
#  Rewritten: 3/25/2018
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Input do
  @moduledoc """
  The main helpers and organizers for input.

  *Resizing is temporarily not supported.*
  """

  alias Scenic.Scene
  alias Scenic.ViewPort.Context
  alias Scenic.ViewPort
  alias Scenic.Primitive
  alias Scenic.Math
  alias Scenic.Math.Matrix

  require Logger

  # import IEx

  @type t ::
          {:codepoint, {codepoint :: String.t(), mods :: integer}}
          | {:key, {key :: String.t(), :press | :release | :repeat, mods :: integer}}
          | {:cursor_button,
             {:left | :center | :right, :press | :release, mods :: integer,
              position :: Math.point()}}
          | {:cursor_scroll, {offset :: Math.point(), position :: Math.point()}}
          | {:cursor_pos, position :: Math.point()}
          | {:viewport_enter, position :: Math.point()}
          | {:viewport_exit, position :: Math.point()}

  @type class ::
          :codepoint
          | :key
          | :cursor_button
          | :cursor_scroll
          | :cursor_pos
          | :viewport_enter
          | :viewport_exit

  # ============================================================================
  # input capture

  # --------------------------------------------------------
  # capture a type of input
  def handle_cast(
        {:capture_input, graph_key, input_types},
        %{input_captures: captures} = state
      ) do
    captures =
      Enum.reduce(input_types, captures, fn input_type, ic ->
        Map.put(ic, input_type, graph_key)
      end)

    {:noreply, %{state | input_captures: captures}}
  end

  # --------------------------------------------------------
  # release a captured type of input
  def handle_cast(
        {:release_input, input_types},
        %{input_captures: captures} = state
      ) do
    captures =
      Enum.reduce(input_types, captures, fn input_type, ic ->
        Map.delete(ic, input_type)
      end)

    {:noreply, %{state | input_captures: captures}}
  end

  # ============================================================================
  # reshape

  # the viewport_reshape control input is a special case that needs to be
  # handled outside the normal input system.
  # This affects the size of the drivers, the viewport and more

  # #--------------------------------------------------------
  # # do nothing if the size isn't actually changing
  # def handle_cast( {:input, {:viewport_reshape, new_size}}, %{size: old_size} = state )
  # when new_size == old_size do
  #   {:noreply, state}
  # end

  # #--------------------------------------------------------
  # # the size is changing
  # def handle_cast( {:input, {:viewport_reshape, new_size}}, state )  do

  #   # set the new size into the viewport on the way out
  #   {:noreply, %{state | size: new_size}}
  # end

  # ============================================================================
  # input handling

  # --------------------------------------------------------
  # ignore input until a graph_key has been set
  def handle_cast({:input, _}, %{master_graph_key: nil} = state) do
    {:noreply, state}
  end

  # --------------------------------------------------------
  # Input handling is enough of a beast to put move it into its own section below
  # bottom of this file.
  def handle_cast(
        {:input, {input_type, _} = input_event},
        %{input_captures: input_captures} = state
      ) do
    case Map.get(input_captures, input_type) do
      nil ->
        # regular input handling
        do_handle_input(input_event, state)

      context ->
        # captive input handling
        do_handle_captured_input(input_event, context, state)
    end
  end

  # ============================================================================
  # input continuation
  # a scene has captured the input, processed it, and sent it back to be handled
  # via the normal non-captured path.

  # --------------------------------------------------------
  # ignore input until a graph_key has been set
  def handle_cast({:continue_input, _}, %{master_graph_key: nil} = state) do
    {:noreply, state}
  end

  # --------------------------------------------------------
  # Input handling is enough of a beast to put move it into its own section below
  # bottom of this file.
  def handle_cast({:continue_input, input}, state) do
    do_handle_input(input, state)
  end

  # ============================================================================
  # captured input handling
  # mostly events get sent straight to the capturing scene. Common events that
  # have an x,y point, get transformed into the scene's requested coordinate space.

  defp do_handle_captured_input(event, context, state)

  #  defp do_handle_captured_input( _, nil, _, state ), do: {:noreply, state}
  #  defp do_handle_captured_input( _, _, nil, state ), do: {:noreply, state}

  # --------------------------------------------------------
  defp do_handle_captured_input(
         {:cursor_button, {button, action, mods, global_pos}} = input,
         context,
         state
       ) do
    {uid, id, point} = find_by_captured_point(global_pos, context, state[:max_depth])

    Scene.cast(
      context.graph_key,
      {
        :input,
        {:cursor_button, {button, action, mods, point}},
        %{context | uid: uid, id: id, raw_input: input}
      }
    )

    {:noreply, state}
  end

  # --------------------------------------------------------
  defp do_handle_captured_input(
         {:cursor_scroll, {offset, global_pos}} = input,
         context,
         %{max_depth: max_depth} = state
       ) do
    {uid, id, point} = find_by_captured_point(global_pos, context, max_depth)

    Scene.cast(
      context.graph_key,
      {
        :input,
        {:cursor_scroll, {offset, point}},
        %{context | uid: uid, id: id, raw_input: input}
      }
    )

    {:noreply, state}
  end

  # --------------------------------------------------------
  # cursor_enter is only sent to the root graph_key
  # defp do_handle_captured_input(
  #        {:cursor_enter, global_pos} = input,
  #        context,
  #        %{max_depth: max_depth} = state
  #      ) do
  #   {uid, id, point} = find_by_captured_point(global_pos, context, max_depth)

  #   Scene.cast(
  #     context.graph_key,
  #     {
  #       :input,
  #       {:cursor_enter, point},
  #       %{context | uid: uid, id: id, raw_input: input}
  #     }
  #   )

  #   {:noreply, state}
  # end

  # # --------------------------------------------------------
  # # cursor_exit is only sent to the root graph_key
  # defp do_handle_captured_input(
  #        {:cursor_exit, global_pos} = input,
  #        context,
  #        %{max_depth: max_depth} = state
  #      ) do
  #   {uid, id, point} = find_by_captured_point(global_pos, context, max_depth)

  #   Scene.cast(
  #     context.graph_key,
  #     {
  #       :input,
  #       {:cursor_enter, point},
  #       %{context | uid: uid, id: id, raw_input: input}
  #     }
  #   )

  #   {:noreply, state}
  # end

  # --------------------------------------------------------
  # cursor_enter is only sent to the root graph_key
  defp do_handle_captured_input(
         {:cursor_pos, global_pos} = input,
         context,
         %{max_depth: max_depth} = state
       ) do
    case find_by_captured_point(global_pos, context, max_depth) do
      {nil, _, point} ->
        # no uid found. let the capturing scene handle the raw position
        # we already know the root scene has identity transforms
        state = send_exit_message(state)

        Scene.cast(
          context.graph_key,
          {
            :input,
            {:cursor_pos, point},
            %{context | uid: nil, id: nil, raw_input: input}
          }
        )

        {:noreply, state}

      {uid, id, point} ->
        # get the graph key, so we know what scene to send the event to
        state = send_enter_message(uid, id, context.graph_key, state)

        Scene.cast(
          context.graph_key,
          {
            :input,
            {:cursor_pos, point},
            %{context | uid: uid, id: id, raw_input: input}
          }
        )

        {:noreply, state}
    end
  end

  # --------------------------------------------------------
  # all events that don't need a point transformed
  defp do_handle_captured_input(input, context, state) do
    Scene.cast(
      context.graph_key,
      {:input, input, %{context | uid: nil, id: nil, raw_input: input}}
    )

    {:noreply, state}
  end

  # ============================================================================
  # regular input handling

  # note. if at any time a scene wants to collect all the raw input and avoid
  # this filtering mechanism, it can register directly for the input

  defp do_handle_input(event, state)

  # --------------------------------------------------------
  # text codepoint input is only sent to the scene with the input focus.
  # If no scene has focus, then send the codepoint to the root scene
  defp do_handle_input({:codepoint, _} = msg, %{root_graph_key: root_key} = state) do
    Scene.cast(
      root_key,
      {:input, msg, Context.build(%{viewport: self(), graph_key: root_key, raw_input: msg})}
    )

    {:noreply, state}
  end

  # --------------------------------------------------------
  # key press input is only sent to the scene with the input focus.
  # If no scene has focus, then send the codepoint to the root scene
  defp do_handle_input({:key, _} = msg, %{root_graph_key: root_key} = state) do
    Scene.cast(
      root_key,
      {:input, msg, Context.build(%{viewport: self(), graph_key: root_key, raw_input: msg})}
    )

    {:noreply, state}
  end

  # --------------------------------------------------------
  # key press input is only sent to the scene with the input focus.
  # If no scene has focus, then send the codepoint to the root scene
  defp do_handle_input(
         {:cursor_button, {button, action, mods, global_pos}} = msg,
         # %{root_graph_key: root_key} = state
         state
       ) do
    case find_by_screen_point(global_pos, state) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        # Scene.cast(
        #   root_key,
        #   {
        #     :input,
        #     msg,
        #     Context.build(%{
        #       viewport: self(),
        #       graph_key: root_key,
        #       raw_input: msg
        #     })
        #   }
        # )
        # no uid found. do nothing
        :ok

      {point, {uid, id, graph_key}, {tx, inv_tx}} ->
        Scene.cast(
          graph_key,
          {
            :input,
            {:cursor_button, {button, action, mods, point}},
            Context.build(%{
              viewport: self(),
              graph_key: graph_key,
              uid: uid,
              id: id,
              tx: tx,
              inverse_tx: inv_tx,
              raw_input: msg
            })
          }
        )
    end

    {:noreply, state}
  end

  # --------------------------------------------------------
  # key press input is only sent to the scene with the input focus.
  # If no scene has focus, then send the codepoint to the root scene
  defp do_handle_input(
         {:cursor_scroll, {offset, global_pos}} = msg,
         # %{root_graph_key: root_key} = state
         state
       ) do
    case find_by_screen_point(global_pos, state) do
      nil ->
        # no uid found. let the root scene handle the click
        # we already know the root scene has identity transforms
        # Scene.cast(
        #   root_key,
        #   {:input, msg,
        #    Context.build(%{
        #      viewport: self(),
        #      graph_key: root_key,
        #      raw_input: msg
        #    })}
        # )
        # no uid found. do nothing
        :ok

      {point, {uid, id, graph_key}, {tx, inv_tx}} ->
        # get the graph key, so we know what scene to send the event to
        Scene.cast(
          graph_key,
          {
            :input,
            {:cursor_scroll, {offset, point}},
            Context.build(%{
              viewport: self(),
              graph_key: graph_key,
              uid: uid,
              id: id,
              tx: tx,
              inverse_tx: inv_tx,
              raw_input: msg
            })
          }
        )
    end

    {:noreply, state}
  end

  # --------------------------------------------------------
  # cursor_enter is only sent to the root graph_key
  defp do_handle_input(
         {:cursor_pos, global_pos} = msg,
         # %{root_graph_key: root_key} = state
         state
       ) do
    state =
      case find_by_screen_point(global_pos, state) do
        nil ->
          send_exit_message(state)
          # no uid found. do nothing
          state

        {point, {uid, id, graph_key}, _} ->
          # get the graph key, so we know what graph_key to send the event to
          state = send_enter_message(uid, id, graph_key, state)

          Scene.cast(
            graph_key,
            {
              :input,
              {:cursor_pos, point},
              Context.build(%{
                viewport: self(),
                graph_key: graph_key,
                uid: uid,
                id: id,
                raw_input: msg
              })
            }
          )

          state
      end

    {:noreply, state}
  end

  # --------------------------------------------------------
  # cursor_enter is only sent to the root graph_key so no need to transform it
  defp do_handle_input({:viewport_enter, _} = msg, %{root_graph_key: root_key} = state) do
    Scene.cast(
      root_key,
      {
        :input,
        msg,
        Context.build(%{viewport: self(), graph_key: root_key, raw_input: msg})
      }
    )

    {:noreply, state}
  end

  # --------------------------------------------------------
  # cursor_enter is only sent to the root graph_key so no need to transform it
  defp do_handle_input({:viewport_exit, _} = msg, %{root_graph_key: root_key} = state) do
    Scene.cast(
      root_key,
      {
        :input,
        msg,
        Context.build(%{viewport: self(), graph_key: root_key, raw_input: msg})
      }
    )

    {:noreply, state}
  end

  # --------------------------------------------------------
  # Any other input (non-standard, generated, etc) get sent to the root graph_key
  defp do_handle_input(msg, %{root_graph_key: root_key} = state) do
    Scene.cast(
      root_key,
      {
        :input,
        msg,
        Context.build(%{viewport: self(), graph_key: root_key, raw_input: msg})
      }
    )

    {:noreply, state}
  end

  # ============================================================================
  # regular input helper utilties

  defp send_exit_message(%{hover_primitve: nil} = state), do: state

  defp send_exit_message(%{hover_primitve: {uid, graph_key}} = state) do
    Scene.cast(
      graph_key,
      {
        :input,
        {:cursor_exit, uid},
        Context.build(%{viewport: self(), uid: uid, graph_key: graph_key})
      }
    )

    %{state | hover_primitve: nil}
  end

  defp send_enter_message(uid, id, graph_key, %{hover_primitve: hover_primitve} = state) do
    # first, send the previous hover_primitve an exit message
    state =
      case hover_primitve do
        nil ->
          # no previous hover_primitive set. do not send an exit message
          state

        {^uid, ^graph_key} ->
          # stil in the same hover_primitive. do not send an exit message
          state

        _ ->
          # do send the exit message
          send_exit_message(state)
      end

    # send the new hover_primitve an enter message
    state =
      case state.hover_primitve do
        nil ->
          # yes. setting a new one. send it.
          Scene.cast(
            graph_key,
            {
              :input,
              {:cursor_enter, uid},
              Context.build(%{viewport: self(), uid: uid, id: id, graph_key: graph_key})
            }
          )

          %{state | hover_primitve: {uid, graph_key}}

        _ ->
          # not setting a new one. do nothing.
          state
      end

    state
  end

  # --------------------------------------------------------
  # find the indicated primitive in a single graph. use the incoming parent
  # transforms from the context
  # {returns {uid, id, transformed_point}}
  defp find_by_captured_point(point, context, max_depth) do
    # project the point by that inverse matrix to get the local point
    point = Matrix.project_vector(context.inverse_tx, point)

    with {:ok, graph} <- ViewPort.Tables.get_graph(context.graph_key) do
      do_find_by_captured_point(
        point,
        0,
        graph,
        Matrix.identity(),
        Matrix.identity(),
        max_depth
      )
      |> case do
        {uid, id, point} -> {uid, id, point}
        nil -> {nil, nil, point}
      end
    else
      _ -> {nil, nil, point}
    end
  end

  defp do_find_by_captured_point(point, _, _, _, _, 0) do
    Logger.error("do_find_by_captured_point max depth")
    {nil, nil, point}
  end

  defp do_find_by_captured_point(point, _, nil, _, _, _) do
    Logger.warn("do_find_by_captured_point nil graph")
    {nil, nil, point}
  end

  defp do_find_by_captured_point(point, uid, graph, parent_tx, parent_inv_tx, depth) do
    # get the primitive to test
    case Map.get(graph, uid) do
      # do nothing if the primitive is hidden
      %{styles: %{hidden: true}} ->
        nil

      # if this is a group, then traverse the members backwards
      # backwards is important as the goal is to find the LAST item drawn
      # that is under the point in question
      %{data: {Primitive.Group, ids}} = p ->
        {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)

        ids
        |> Enum.reverse()
        |> Enum.find_value(fn uid ->
          do_find_by_captured_point(point, uid, graph, tx, inv_tx, depth - 1)
        end)

      # This is a regular primitive, test to see if it is hit
      %{data: {mod, data}} = p ->
        {_, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)

        # project the point by that inverse matrix to get the local point
        local_point = Matrix.project_vector(inv_tx, point)

        # test if the point is in the primitive
        if mod.contains_point?(data, local_point) do
          {uid, p[:id], point}
        end
    end
  end

  # --------------------------------------------------------
  # find the indicated primitive in the graph given a point in screen coordinates.
  # to do this, we need to project the point into primitive local coordinates by
  # projecting it with the primitive's inverse final matrix.
  #
  # Since the last primitive drawn is always on top, we should walk the tree
  # backwards and return the first hit we find. We could just reduct the whole
  # thing and return the last one found (that was my first try), but this is
  # more efficient as we can stop as soon as we find the first one.
  defp find_by_screen_point({x, y}, %{master_graph_key: root_key, max_depth: depth}) do
    identity = {Matrix.identity(), Matrix.identity()}

    with {:ok, graph} <- ViewPort.Tables.get_graph(root_key) do
      do_find_by_screen_point(x, y, 0, root_key, graph, identity, identity, depth)
    end
  end

  defp do_find_by_screen_point(_, _, _, _, _, _, _, 0) do
    Logger.error("do_find_by_screen_point max depth")
    nil
  end

  defp do_find_by_screen_point(_, _, _, _, nil, _, _, _) do
    # for whatever reason, the graph hasn't been put yet. just return nil
    nil
  end

  defp do_find_by_screen_point(
         x,
         y,
         uid,
         graph_key,
         graph,
         {parent_tx, parent_inv_tx},
         {graph_tx, graph_inv_tx},
         depth
       ) do
    # get the primitive to test
    case graph[uid] do
      # do nothing if the primitive is hidden
      %{styles: %{hidden: true}} ->
        nil

      # if this is a group, then traverse the members backwards
      # backwards is important as the goal is to find the LAST item drawn
      # that is under the point in question
      %{data: {Primitive.Group, ids}} = p ->
        {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)

        ids
        |> Enum.reverse()
        |> Enum.find_value(fn uid ->
          do_find_by_screen_point(
            x,
            y,
            uid,
            graph_key,
            graph,
            {tx, inv_tx},
            {graph_tx, graph_inv_tx},
            depth - 1
          )
        end)

      # if this is a SceneRef, then traverse into the next graph
      %{data: {Primitive.SceneRef, ref_key}} = p ->
        {tx, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)

        with {:ok, graph} <- ViewPort.Tables.get_graph(ref_key) do
          do_find_by_screen_point(x, y, 0, ref_key, graph, {tx, inv_tx}, {tx, inv_tx}, depth - 1)
        else
          _ -> nil
        end

      # This is a regular primitive, test to see if it is hit
      %{data: {mod, data}} = p ->
        {_, inv_tx} = calc_transforms(p, parent_tx, parent_inv_tx)

        # project the point by that inverse matrix to get the local point
        local_point = Matrix.project_vector(inv_tx, {x, y})

        # test if the point is in the primitive
        if mod.contains_point?(data, local_point) do
          id = p[:id]
          # Return the point in graph coordinates. Local was good for the hit test
          # but graph coords makes more sense for the graph_key logic
          graph_point = Matrix.project_vector(graph_inv_tx, {x, y})
          {graph_point, {uid, id, graph_key}, {graph_tx, graph_inv_tx}}
        end
    end
  end

  defp calc_transforms(p, parent_tx, parent_inv_tx) do
    p
    |> Map.get(:transforms, nil)
    |> Primitive.Transform.calculate_local()
    |> case do
      nil ->
        # No local transform. This will often be the case.
        {parent_tx, parent_inv_tx}

      tx ->
        # there was a local transform. multiply it into the parent
        # then also calculate a new inverse transform
        tx = Matrix.mul(parent_tx, tx)
        inv_tx = Matrix.invert(tx)
        {tx, inv_tx}
    end
  end
end
