#
#  Created by Boyd Multerer 2018-08-06.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
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
  alias Scenic.Primitive.Style.Theme

  @width 2
  @inset_v 4

  # caret blink speed in hertz
  @caret_hz 0.5
  @caret_ms trunc(1000 / @caret_hz / 2)

  # ============================================================================
  # setup

  # --------------------------------------------------------
  @impl Scenic.Component
  def validate(height) when is_number(height) and height >= 0 do
    {:ok, height}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Caret specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a Caret is the height of the caret line.
      This height must be >= 0#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def init(scene, height, opts) do
    color =
      case opts[:color] do
        nil ->
          opts[:theme]
          |> Theme.normalize()
          |> Map.get(:highlight)

        c ->
          c
      end

    # build the graph, initially not showing
    # the height and the color are variable, which means it can't be
    # built at compile time
    graph =
      Graph.build()
      |> line(
        {{0, @inset_v}, {0, height - @inset_v}},
        stroke: {@width, color},
        hidden: true,
        id: :caret
      )

    scene =
      scene
      |> assign(
        graph: graph,
        hidden: true,
        timer: nil,
        focused: false
      )
      |> push_graph(graph)

    {:ok, scene}
  end

  # --------------------------------------------------------
  @doc false
  @impl GenServer
  def handle_cast(:start_caret, %{assigns: %{graph: graph, timer: nil}} = scene) do
    # start the timer
    {:ok, timer} = :timer.send_interval(@caret_ms, :blink)

    # show the caret
    graph = Graph.modify(graph, :caret, &update_opts(&1, hidden: false))

    scene =
      scene
      |> assign(graph: graph, hidden: false, timer: timer, focused: true)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  def handle_cast(:stop_caret, %{assigns: %{graph: graph, timer: timer}} = scene) do
    # hide the caret
    graph = Graph.modify(graph, :caret, &update_opts(&1, hidden: true))

    # stop the timer
    case timer do
      nil -> :ok
      timer -> :timer.cancel(timer)
    end

    scene =
      scene
      |> assign(graph: graph, hidden: true, timer: nil, focused: false)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  def handle_cast(
        :reset_caret,
        %{assigns: %{graph: graph, timer: timer, focused: true}} = scene
      ) do
    # show the caret
    graph = Graph.modify(graph, :caret, &update_opts(&1, hidden: false))

    # stop the timer
    if timer, do: :timer.cancel(timer)
    # restart the timer
    {:ok, timer} = :timer.send_interval(@caret_ms, :blink)

    scene =
      scene
      |> assign(graph: graph, hidden: false, timer: timer)
      |> push_graph(graph)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # throw away unknown messages
  # def handle_cast(_, scene), do: {:noreply, scene}

  # --------------------------------------------------------
  @doc false
  @impl GenServer
  def handle_info(:blink, %{assigns: %{graph: graph, hidden: hidden}} = scene) do
    graph = Graph.modify(graph, :caret, &update_opts(&1, hidden: !hidden))

    scene =
      scene
      |> assign(graph: graph, hidden: !hidden)
      |> push_graph(graph)

    {:noreply, scene}
  end
end
