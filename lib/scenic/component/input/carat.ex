#
#  Created by Boyd Multerer August 6, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#


defmodule Scenic.Component.Input.Carat do
  use Scenic.Component, has_children: false
  alias Scenic.Graph
  alias Scenic.Primitive.Style.Paint.Color

  import Scenic.Primitives, only: [
    {:line, 3}, {:update_opts,2}
  ]

  @width                  2
  @inset_v                4

  # carat blink speed in hertz
  @carat_hz               1.5
  @carat_ms               trunc(@carat_hz * 500)

  #============================================================================
  # setup

  #--------------------------------------------------------
  def info() do
    "#{IO.ANSI.red()}Carat data must be: {height, color}" <>
    IO.ANSI.yellow() <>
    "\r\n" <>
    IO.ANSI.default_color()
  end

  #--------------------------------------------------------
  def verify( {height, color} = data ) when
  is_number(height) and height > 0 do
    case Color.verify( color ) do
      true -> {:ok, data}
      _ -> :invalid_data
    end
  end
  def verify( _ ), do: :invalid_data

  #--------------------------------------------------------
  def init( {height, color}, _args ) do
    # build the graph, initially not showing
    graph = Graph.build()
    |> line(
      {{0,@inset_v},{0,height - @inset_v}},
      stroke: {@width, color}, hidden: true, id: :carat
      )
    |> push_graph()

    state = %{
      graph: graph,
      hidden: false,
      timer: nil,
      focused: false
    }

    {:ok, state}
  end

  #--------------------------------------------------------
  def handle_cast(:gain_focus, %{graph: graph, timer: nil} = state ) do
    # turn on the carat
    graph = graph
    |> Graph.modify( :carat, &update_opts(&1, hidden: false) )
    |> push_graph()

    # start the timer
    {:ok, timer} = :timer.send_interval(@carat_ms, :blink)

    {:noreply, %{state | graph: graph, hidden: false, timer: timer, focused: true}}
  end

  #--------------------------------------------------------
  def handle_cast(:lose_focus, %{graph: graph, timer: timer} = state ) do
    # hide the carat
    graph = graph
    |> Graph.modify( :carat, &update_opts(&1, hidden: true) )
    |> push_graph()

    # stop the timer
    case timer do
      nil -> :ok
      timer -> :timer.cancel(timer)
    end

    {:noreply, %{state | graph: graph, hidden: true, timer: nil, focused: false}}
  end

  #--------------------------------------------------------
  def handle_cast(:reset_carat,
    %{graph: graph, timer: timer, focused: true} = state
  ) do
    # show the carat
    graph = graph
    |> Graph.modify( :carat, &update_opts(&1, hidden: false) )
    |> push_graph()

    # stop the timer
    if timer, do: :timer.cancel(timer)

    # restart the timer
    {:ok, timer} = :timer.send_interval(@carat_ms, :blink)

    {:noreply, %{state | graph: graph, hidden: false, timer: timer}}
  end

  #--------------------------------------------------------
  # throw away unknown messages
  def handle_cast(_,state), do: {:noreply, state}

  #--------------------------------------------------------
  def handle_info(:blink, %{graph: graph, hidden: hidden} = state) do
    # invert the hidden flag
    hidden = !hidden

    graph = graph
    |> Graph.modify( :carat, &update_opts(&1, hidden: hidden) )
    |> push_graph()

    {:noreply, %{state | graph: graph, hidden: hidden}}
  end

end











