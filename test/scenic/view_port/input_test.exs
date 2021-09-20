#
#  Created by Boyd Multerer on 2021-02-07.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.ViewPort.InputTest do
  use ExUnit.Case, async: false
  doctest Scenic.ViewPort.Input

  alias Scenic.ViewPort
  alias Scenic.ViewPort.Input

  # import IEx

  defmodule TestInputScene do
    use Scenic.Scene

    def init(scene, pid, _) do
      Process.send(pid, {:test_up, scene}, [])
      {:ok, assign(scene, :pid, pid)}
    end

    def handle_call(:ping, _from, scene) do
      {:reply, :pong, scene}
    end

    # def handle_input( input, %{assigns: %{pid: pid}} = scene ) do
    #   Process.send( pid, {:test_input, input}, [] )
    # end
  end

  setup do
    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    # start and return the test ViewPort
    out = Scenic.Test.ViewPort.start({TestInputScene, self()})

    # wait for a signal that the scene is up before proceeding
    {:ok, scene} =
      receive do
        {:test_up, scene} -> {:ok, scene}
      end

    Map.put(out, :scene, scene)
  end

  test "Test that capture/release/list_captures work", %{vp: vp} do
    assert Input.fetch_captures(vp) == {:ok, []}

    :ok = Input.capture(vp, :cursor_pos)
    assert Input.fetch_captures(vp) == {:ok, [:cursor_pos]}

    :ok = Input.capture(vp, [:key, :codepoint])
    assert Input.fetch_captures(vp) == {:ok, [:key, :cursor_pos, :codepoint]}

    :ok = Input.release(vp, :key)
    assert Input.fetch_captures(vp) == {:ok, [:cursor_pos, :codepoint]}

    :ok = Input.release(vp, :all)
    assert Input.fetch_captures(vp) == {:ok, []}
  end

  test "list_captures and list_captures! work", %{vp: vp} do
    assert Input.fetch_captures(vp) == {:ok, []}
    assert Input.fetch_captures!(vp) == {:ok, []}

    Agent.start(fn ->
      :ok = Input.capture(vp, [:codepoint])
    end)

    assert Input.fetch_captures(vp) == {:ok, []}
    assert Input.fetch_captures!(vp) == {:ok, [:codepoint]}

    :ok = Input.capture(vp, :cursor_pos)
    assert Input.fetch_captures(vp) == {:ok, [:cursor_pos]}
    assert Input.fetch_captures!(vp) == {:ok, [:codepoint, :cursor_pos]}
  end

  test "captures are cleaned up when the owning process stops", %{vp: vp} do
    # set up a capture
    :ok = Input.capture(vp, [:codepoint])
    assert Input.fetch_captures!(vp) == {:ok, [:codepoint]}

    # fake indicate this process went down
    Process.send(vp.pid, {:DOWN, make_ref(), :process, self(), :test}, [])

    assert Input.fetch_captures!(vp) == {:ok, []}
  end

  test "Test that request/unrequest/list_requests work", %{vp: vp} do
    assert Input.fetch_requests(vp) == {:ok, []}

    :ok = Input.request(vp, :cursor_pos)
    assert Input.fetch_requests(vp) == {:ok, [:cursor_pos]}

    :ok = Input.request(vp, [:key, :codepoint])
    assert Input.fetch_requests(vp) == {:ok, [:key, :cursor_pos, :codepoint]}

    :ok = Input.unrequest(vp, :key)
    assert Input.fetch_requests(vp) == {:ok, [:cursor_pos, :codepoint]}

    :ok = Input.unrequest(vp, :all)
    assert Input.fetch_requests(vp) == {:ok, []}
  end

  test "fetch_requests and fetch_requests! work", %{vp: vp} do
    assert Input.fetch_requests(vp) == {:ok, []}
    assert Input.fetch_requests!(vp) == {:ok, []}

    Agent.start(fn ->
      :ok = Input.request(vp, [:codepoint])
    end)

    assert Input.fetch_captures(vp) == {:ok, []}
    assert Input.fetch_requests!(vp) == {:ok, [:codepoint]}

    :ok = Input.request(vp, :cursor_pos)
    assert Input.fetch_requests(vp) == {:ok, [:cursor_pos]}
    assert Input.fetch_requests!(vp) == {:ok, [:codepoint, :cursor_pos]}
  end

  test "requests are cleaned up with the owning process stops", %{vp: vp, scene: scene} do
    :ok = Input.request(vp, :cursor_pos)
    Scenic.Scene.request_input(scene, :codepoint)
    assert Input.fetch_requests!(vp) == {:ok, [:codepoint, :cursor_pos]}
    Scenic.Scene.stop(scene)
    assert Input.fetch_requests!(vp) == {:ok, [:cursor_pos]}
  end

  # ----------------
  # input: [types]

  test "adding or removing input types from a graph pushes those requests to drivers",
       %{vp: vp, scene: scene} do
    # make like a driver
    GenServer.cast(vp.pid, {:register_driver, self()})
    assert Input.fetch_requests!(vp) == {:ok, []}

    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({10, 20}, input: [:cursor_button, :cursor_scroll, :cursor_pos])

    Scenic.Scene.push_graph(scene, graph)

    assert_receive(
      {:_request_input_, [:cursor_button, :cursor_pos, :cursor_scroll]},
      100
    )

    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({10, 20})

    Scenic.Scene.push_graph(scene, graph)
    assert_receive({:_request_input_, []}, 100)
  end

  test ":cursor_button only the input listed in a input style is requested", %{
    vp: vp,
    scene: scene
  } do
    # make like a driver
    GenServer.cast(vp.pid, {:register_driver, self()})
    assert Input.fetch_requests!(vp) == {:ok, []}

    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({10, 20}, input: :cursor_button)

    Scenic.Scene.push_graph(scene, graph)

    assert_receive({:_request_input_, [:cursor_button]}, 100)
  end

  test ":cursor_scroll only the input listed in a input style is requested", %{
    vp: vp,
    scene: scene
  } do
    # make like a driver
    GenServer.cast(vp.pid, {:register_driver, self()})
    assert Input.fetch_requests!(vp) == {:ok, []}

    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({10, 20}, input: :cursor_scroll)

    Scenic.Scene.push_graph(scene, graph)

    assert_receive({:_request_input_, [:cursor_scroll]}, 100)
  end

  test ":cursor_pos only the input listed in a input style is requested", %{vp: vp, scene: scene} do
    # make like a driver
    GenServer.cast(vp.pid, {:register_driver, self()})
    assert Input.fetch_requests!(vp) == {:ok, []}

    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({10, 20}, input: :cursor_pos)

    Scenic.Scene.push_graph(scene, graph)

    assert_receive({:_request_input_, [:cursor_pos]}, 100)
  end

  test ":cursor_button only is the only cursor input type sent", %{vp: vp, scene: scene} do
    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({100, 200}, id: :test, input: :cursor_button)

    Scenic.Scene.push_graph(scene, graph)

    # Send a cursor_button input through. We should receive this one
    input = {:cursor_button, {:button_left, 1, [], {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :test}, 100)

    # should NOT receive the other positional inputs
    input = {:cursor_scroll, {{1.0, 2.0}, {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    refute_receive({:_input, ^input, ^input, :test}, 100)

    input = {:cursor_pos, {10.0, 20.0}}
    Scenic.ViewPort.Input.send(vp, input)
    refute_receive({:_input, ^input, ^input, :test}, 100)
  end

  test ":cursor_scroll only is the only cursor input type sent", %{vp: vp, scene: scene} do
    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({100, 200}, id: :test, input: :cursor_scroll)

    Scenic.Scene.push_graph(scene, graph)

    # Send a cursor_button input through. We should receive this one
    input = {:cursor_scroll, {{1.0, 2.0}, {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :test}, 100)

    # should NOT receive the other positional inputs
    input = {:cursor_button, {:button_left, 1, [], {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    refute_receive({:_input, ^input, ^input, :test}, 100)

    input = {:cursor_pos, {10.0, 20.0}}
    Scenic.ViewPort.Input.send(vp, input)
    refute_receive({:_input, ^input, ^input, :test}, 100)
  end

  test ":cursor_pos only is the only cursor input type sent", %{vp: vp, scene: scene} do
    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({100, 200}, id: :test, input: :cursor_pos)

    Scenic.Scene.push_graph(scene, graph)

    # Send a cursor_button input through. We should receive this one
    input = {:cursor_pos, {10.0, 20.0}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :test}, 100)

    # should NOT receive the other positional inputs
    input = {:cursor_button, {:button_left, 1, [], {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    refute_receive({:_input, ^input, ^input, :test}, 100)

    input = {:cursor_scroll, {{1.0, 2.0}, {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    refute_receive({:_input, ^input, ^input, :test}, 100)
  end

  test "positional inputs fall through to the correct primitive", %{vp: vp, scene: scene} do
    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({100, 200}, id: :btn, input: :cursor_button)
      |> Scenic.Primitives.rect({100, 200}, id: :scl, input: :cursor_scroll)
      |> Scenic.Primitives.rect({100, 200}, id: :pos, input: :cursor_pos)

    Scenic.Scene.push_graph(scene, graph)

    # Send a cursor_button input through. We should receive this one
    input = {:cursor_button, {:button_left, 1, [], {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :btn}, 100)

    input = {:cursor_scroll, {{1.0, 2.0}, {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :scl}, 100)

    input = {:cursor_pos, {10.0, 20.0}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :pos}, 100)

    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({100, 200}, id: :pos, input: :cursor_pos)
      |> Scenic.Primitives.rect({100, 200}, id: :btn, input: :cursor_button)
      |> Scenic.Primitives.rect({100, 200}, id: :scl, input: :cursor_scroll)

    Scenic.Scene.push_graph(scene, graph)

    input = {:cursor_button, {:button_left, 1, [], {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :btn}, 100)
    input = {:cursor_scroll, {{1.0, 2.0}, {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :scl}, 100)
    input = {:cursor_pos, {10.0, 20.0}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :pos}, 100)

    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({100, 200}, id: :scl, input: :cursor_scroll)
      |> Scenic.Primitives.rect({100, 200}, id: :pos, input: :cursor_pos)
      |> Scenic.Primitives.rect({100, 200}, id: :btn, input: :cursor_button)

    Scenic.Scene.push_graph(scene, graph)

    input = {:cursor_button, {:button_left, 1, [], {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :btn}, 100)
    input = {:cursor_scroll, {{1.0, 2.0}, {10.0, 20.0}}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :scl}, 100)
    input = {:cursor_pos, {10.0, 20.0}}
    Scenic.ViewPort.Input.send(vp, input)
    assert_receive({:_input, ^input, ^input, :pos}, 100)
  end

  # ----------------
  # specific input types

  test "cursor_scroll request works", %{vp: vp} do
    assert Input.fetch_captures!(vp) == {:ok, []}
    assert Input.fetch_requests(vp) == {:ok, []}

    :ok = Input.request(vp, :cursor_scroll)
    assert Input.fetch_requests(vp) == {:ok, [:cursor_scroll]}

    assert Input.send(vp, {:cursor_scroll, {{1, 2}, {3, 4}}}) == :ok

    assert_receive(
      {:_input, {:cursor_scroll, {{1, 2}, {3, 4}}}, {:cursor_scroll, {{1, 2}, {3, 4}}}, nil},
      100
    )
  end

  test "cursor_scroll capture works", %{vp: vp} do
    assert Input.fetch_captures(vp) == {:ok, []}
    assert Input.fetch_requests(vp) == {:ok, []}

    :ok = Input.capture(vp, :cursor_scroll)
    assert Input.fetch_captures(vp) == {:ok, [:cursor_scroll]}

    assert Input.send(vp, {:cursor_scroll, {{1, 2}, {3, 4}}}) == :ok

    assert_receive(
      {:_input, {:cursor_scroll, {{1, 2}, {3, 4}}}, {:cursor_scroll, {{1, 2}, {3, 4}}}, nil},
      100
    )
  end

  test "cursor_pos request works", %{vp: vp} do
    assert Input.fetch_captures!(vp) == {:ok, []}
    assert Input.fetch_requests(vp) == {:ok, []}

    :ok = Input.request(vp, :cursor_pos)
    assert Input.fetch_requests(vp) == {:ok, [:cursor_pos]}

    assert Input.send(vp, {:cursor_pos, {1, 2}}) == :ok

    assert_receive(
      {:_input, {:cursor_pos, {1, 2}}, {:cursor_pos, {1, 2}}, nil},
      100
    )
  end

  test "cursor_pos capture works", %{vp: vp} do
    assert Input.fetch_captures(vp) == {:ok, []}
    assert Input.fetch_requests(vp) == {:ok, []}

    :ok = Input.capture(vp, :cursor_pos)
    assert Input.fetch_captures(vp) == {:ok, [:cursor_pos]}

    assert Input.send(vp, {:cursor_pos, {1, 2}}) == :ok

    assert_receive(
      {:_input, {:cursor_pos, {1, 2}}, {:cursor_pos, {1, 2}}, nil},
      100
    )
  end

  # ----------------
  # drivers are sent input updates

  test "drivers are sent requested input updates", %{vp: vp} do
    assert Input.fetch_requests!(vp) == {:ok, []}
    :ok = Input.request(vp, :cursor_button)

    GenServer.cast(vp.pid, {:register_driver, self()})
    assert_receive({:_request_input_, [:cursor_button]}, 100)

    # should NOT get an update when the same thing is requested again
    :ok = Input.request(vp, :cursor_button)
    refute_receive({:_request_input_, _}, 20)

    # should get an update when something new is requested
    :ok = Input.request(vp, :cursor_pos)
    assert_receive({:_request_input_, [:cursor_button, :cursor_pos]}, 100)

    # should get an update when something is removed
    :ok = Input.unrequest(vp, :cursor_pos)
    assert_receive({:_request_input_, [:cursor_button]}, 100)
  end

  test "drivers are sent requested input updates when a scene goes down", %{vp: vp, scene: scene} do
    Scenic.Scene.request_input(scene, :cursor_button)

    assert Input.fetch_requests!(vp) == {:ok, [:cursor_button]}

    GenServer.cast(vp.pid, {:register_driver, self()})
    assert_receive({:_request_input_, [:cursor_button]}, 100)

    Scenic.Scene.stop(scene)

    # should get an update the owning scene goes down
    assert_receive({:_request_input_, []}, 100)
  end

  test "drivers are sent captured input updates", %{vp: vp, scene: scene} do
    Scenic.Scene.request_input(scene, :cursor_button)

    assert Input.fetch_captures!(vp) == {:ok, []}
    assert Input.fetch_requests!(vp) == {:ok, [:cursor_button]}

    GenServer.cast(vp.pid, {:register_driver, self()})
    assert_receive({:_request_input_, [:cursor_button]}, 100)

    # should NOT get an update when the same thing is captured
    :ok = Input.capture(vp, :cursor_button)
    refute_receive({:_request_input_, _}, 20)

    # should get an update when something new is requested
    :ok = Input.capture(vp, :cursor_pos)
    assert_receive({:_request_input_, [:cursor_button, :cursor_pos]}, 100)

    # should get an update when something is removed
    :ok = Input.release(vp, :all)
    assert_receive({:_request_input_, [:cursor_button]}, 100)
  end

  test "drivers are sent captured input updates when a scene goes down", %{vp: vp, scene: scene} do
    Scenic.Scene.request_input(scene, :cursor_button)

    assert Input.fetch_requests!(vp) == {:ok, [:cursor_button]}
    self = self()
    # have to have an agent do the capture so that it comes from a different pid than this
    # test, which is pretending to be a driver...
    {:ok, agent} =
      Agent.start(fn ->
        GenServer.cast(vp.pid, {:register_scene, self(), :agent, nil})
        :ok = Input.capture(vp, :cursor_pos)
        send(self, :sync)
      end)

    receive do
      :sync -> :ok
    end

    GenServer.call(vp.pid, :_ping_)

    GenServer.cast(vp.pid, {:register_driver, self()})
    assert_receive({:_request_input_, [:cursor_button, :cursor_pos]}, 100)

    # stop the agent
    Agent.stop(agent)

    # should get an update when the owning pid goes down
    # calling fetch_requests! makes sure the vp has processed the agent DOWN message
    assert Input.fetch_requests!(vp) == {:ok, [:cursor_button]}
    assert_receive({:_request_input_, [:cursor_button]}, 100)
  end

  # ----------------
  # actual input is routed to listeners

  @codepoint {:codepoint, {"k", []}}

  test "receives requested input", %{vp: vp} do
    :ok = Input.request(vp, :codepoint)
    :ok = Input.send(vp, @codepoint)
    assert_receive({:_input, @codepoint, @codepoint, nil}, 100)
  end

  test "receives continued input", %{vp: vp} do
    :ok = Input.request(vp, :codepoint)
    GenServer.cast(vp.pid, {:continue_input, @codepoint})
    assert_receive({:_input, @codepoint, @codepoint, nil}, 100)
  end

  test "ViewPort.input equivalent to ViewPort.Input.send", %{vp: vp} do
    :ok = Input.request(vp, :codepoint)
    :ok = ViewPort.input(vp, @codepoint)
    assert_receive({:_input, @codepoint, @codepoint, nil}, 100)
  end
end
