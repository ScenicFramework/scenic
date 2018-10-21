#
#  Created by Boyd Multerer 2018-08-06.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.Input.Caret do
  @moduledoc """
  Add a blinking text-input caret to a graph.


  ## Data

  `{height, color}`

  * `height` - integer greater than zero
  * `color` - any [valid color](Scenic.Primitive.Style.Paint.Color.html).

  ## Usage

  The caret component is used by the TextField component and usually isn't accessed directly,
  although you are free to do so if it fits your needs. There is no short-cut helper
  function so you will need to add it to the graph manually.

  The following example adds a caret to a graph.

      graph
      |> Caret.add_to_graph({height, theme.text}, id: :caret)
  """
  use Scenic.Component, has_children: false

  import Scenic.Primitives,
    only: [
      {:line, 3},
      {:update_opts, 2}
    ]

  alias Scenic.Graph
  alias Scenic.Primitive.Style.Paint.Color

  @width 2
  @inset_v 4

  # caret blink speed in hertz
  @caret_hz 1.5
  @caret_ms trunc(@caret_hz * 500)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  @doc false
  def info(data) do
    """
    #{IO.ANSI.red()}Caret data must be: {height, color}
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """
  end

  # --------------------------------------------------------
  @doc false
  @spec verify(any()) :: :invalid_data | {:ok, {number(), any()}}
  def verify({height, color} = data)
      when is_number(height) and height > 0 do
    case Color.verify(color) do
      true -> {:ok, data}
      _ -> :invalid_data
    end
  end

  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  @doc false
  def init({height, color}, _opts) do
    # build the graph, initially not showing
    graph =
      Graph.build()
      |> line(
        {{0, @inset_v}, {0, height - @inset_v}},
        stroke: {@width, color},
        hidden: true,
        id: :caret
      )
      |> push_graph()

    state = %{
      graph: graph,
      hidden: true,
      timer: nil,
      focused: false
    }

    {:ok, state}
  end

  # --------------------------------------------------------
  @doc false
  def handle_cast(:start_caret, %{graph: graph, timer: nil} = state) do
    # turn on the caret
    graph =
      graph
      |> Graph.modify(:caret, &update_opts(&1, hidden: false))
      |> push_graph()

    # start the timer
    {:ok, timer} = :timer.send_interval(@caret_ms, :blink)

    {:noreply, %{state | graph: graph, hidden: false, timer: timer, focused: true}}
  end

  # --------------------------------------------------------
  def handle_cast(:stop_caret, %{graph: graph, timer: timer} = state) do
    # hide the caret
    graph =
      graph
      |> Graph.modify(:caret, &update_opts(&1, hidden: true))
      |> push_graph()

    # stop the timer
    case timer do
      nil -> :ok
      timer -> :timer.cancel(timer)
    end

    {:noreply, %{state | graph: graph, hidden: true, timer: nil, focused: false}}
  end

  # --------------------------------------------------------
  def handle_cast(
        :reset_caret,
        %{graph: graph, timer: timer, focused: true} = state
      ) do
    # show the caret
    graph =
      graph
      |> Graph.modify(:caret, &update_opts(&1, hidden: false))
      |> push_graph()

    # stop the timer
    if timer, do: :timer.cancel(timer)

    # restart the timer
    {:ok, timer} = :timer.send_interval(@caret_ms, :blink)

    {:noreply, %{state | graph: graph, hidden: false, timer: timer}}
  end

  # --------------------------------------------------------
  # throw away unknown messages
  def handle_cast(_, state), do: {:noreply, state}

  # --------------------------------------------------------
  @doc false
  def handle_info(:blink, %{graph: graph, hidden: hidden} = state) do
    # invert the hidden flag
    hidden = !hidden

    graph =
      graph
      |> Graph.modify(:caret, &update_opts(&1, hidden: hidden))
      |> push_graph()

    {:noreply, %{state | graph: graph, hidden: hidden}}
  end
end
