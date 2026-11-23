#
#  Created by Boyd Multerer on 2021-02-07.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.ViewPort.InputTest do
  use Scenic.Test.DataCase, async: false
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

    def handle_input(_, _, scene) do
      {:noreply, scene}
    end
  end

  defmodule TestScissorComponent do
    use Scenic.Component

    @impl Scenic.Component
    def validate(pid) when is_pid(pid), do: {:ok, pid}

    @impl Scenic.Scene
    def init(scene, pid, _opts) do
      graph =
        Scenic.Graph.build()
        |> Scenic.Primitives.rect({80, 80},
          id: :child_rect,
          input: [:cursor_button, :cursor_pos, :cursor_scroll]
        )

      scene =
        scene
        |> assign(:pid, pid)
        |> push_graph(graph)

      Process.send(pid, {:scissor_child_up, scene}, [])
      {:ok, scene}
    end

    @impl Scenic.Scene
    def handle_input(input, id, %{assigns: %{pid: pid}} = scene) do
      send(pid, {:child_input, input, id})
      {:noreply, scene}
    end
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
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([])}

    :ok = Input.capture(vp, :cursor_pos)
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([:cursor_pos])}

    :ok = Input.capture(vp, [:key, :codepoint])
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([:key, :cursor_pos, :codepoint])}

    :ok = Input.release(vp, :key)
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([:cursor_pos, :codepoint])}

    :ok = Input.release(vp, :all)
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([])}
  end

  test "list_captures and list_captures! work", %{vp: vp} do
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([])}
    assert Input.fetch_captures!(vp) ~> {:ok, sorted_list([])}

    Agent.start(fn ->
      :ok = Input.capture(vp, [:codepoint])
    end)

    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([])}
    assert Input.fetch_captures!(vp) ~> {:ok, sorted_list([:codepoint])}

    :ok = Input.capture(vp, :cursor_pos)
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([:cursor_pos])}
    assert Input.fetch_captures!(vp) ~> {:ok, sorted_list([:codepoint, :cursor_pos])}
  end

  test "captures are cleaned up when the owning process stops", %{vp: vp} do
    # set up a capture
    :ok = Input.capture(vp, [:codepoint])
    assert Input.fetch_captures!(vp) ~> {:ok, sorted_list([:codepoint])}

    # fake indicate this process went down
    Process.send(vp.pid, {:DOWN, make_ref(), :process, self(), :test}, [])

    assert Input.fetch_captures!(vp) ~> {:ok, sorted_list([])}
  end

  test "Test that request/unrequest/list_requests work", %{vp: vp} do
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([])}

    :ok = Input.request(vp, :cursor_pos)
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([:cursor_pos])}

    :ok = Input.request(vp, [:key, :codepoint])
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([:key, :cursor_pos, :codepoint])}

    :ok = Input.unrequest(vp, :key)
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([:cursor_pos, :codepoint])}

    :ok = Input.unrequest(vp, :all)
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([])}
  end

  test "fetch_requests and fetch_requests! work", %{vp: vp} do
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([])}
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([])}

    Agent.start(fn ->
      :ok = Input.request(vp, [:codepoint])
    end)

    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([])}
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([:codepoint])}

    :ok = Input.request(vp, :cursor_pos)
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([:cursor_pos])}
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([:codepoint, :cursor_pos])}
  end

  test "requests are cleaned up with the owning process stops", %{vp: vp, scene: scene} do
    :ok = Input.request(vp, :cursor_pos)
    Scenic.Scene.request_input(scene, :codepoint)
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([:codepoint, :cursor_pos])}
    Scenic.Scene.stop(scene)
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([:cursor_pos])}
  end

  # ----------------
  # input: [types]

  test "adding or removing input types from a graph pushes those requests to drivers",
       %{vp: vp, scene: scene} do
    # make like a driver
    GenServer.cast(vp.pid, {:register_driver, self()})
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([])}

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

  test "positional hits and inputs respect both group and root scissors", %{
    vp: vp,
    scene: scene
  } do
    GenServer.cast(vp.pid, {:register_driver, self()})
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([])}

    graph =
      Scenic.Graph.build(scissor: {40, 40})
      |> Scenic.Primitives.group(
        fn graph ->
          Scenic.Primitives.rect(graph, {80, 80},
            id: :test,
            input: [:cursor_button, :cursor_pos, :cursor_scroll]
          )
        end,
        scissor: {20, 60},
        translate: {10, 0}
      )

    Scenic.Scene.push_graph(scene, graph)

    # input types inside scissored groups are still registered with drivers
    assert_receive(
      {:_request_input_, [:cursor_button, :cursor_pos, :cursor_scroll]},
      100
    )

    # point inside both root scissor {40, 40} and translated group scissor {10..30, 0..60}
    assert {:ok, _, :test} = ViewPort.find_point(vp, {15, 10})

    for input <- [
          {:cursor_button, {:button_left, 1, [], {15.0, 10.0}}},
          {:cursor_pos, {15.0, 10.0}},
          {:cursor_scroll, {{1.0, 2.0}, {15.0, 10.0}}}
        ] do
      assert :ok = Input.send(vp, input)
      assert_receive({:_input, ^input, ^input, :test}, 100)
    end

    # clipped by group scissor (x = 35 is outside x in [10, 30])
    assert {:error, :not_found} = ViewPort.find_point(vp, {35, 10})

    # clipped by root scissor (y = 50 is outside y in [0, 40])
    assert {:error, :not_found} = ViewPort.find_point(vp, {15, 50})

    for clipped_point <- [{35.0, 10.0}, {15.0, 50.0}],
        input <- [
          {:cursor_button, {:button_left, 1, [], clipped_point}},
          {:cursor_pos, clipped_point},
          {:cursor_scroll, {{1.0, 2.0}, clipped_point}}
        ] do
      assert :ok = Input.send(vp, input)
      refute_receive({:_input, _, _, :test}, 20)
    end
  end

  test "scissored leaf primitives clip hits to their scissor bounds", %{vp: vp, scene: scene} do
    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({100, 100},
        id: :leaf,
        input: :cursor_button,
        scissor: {30, 20},
        translate: {10, 15}
      )

    Scenic.Scene.push_graph(scene, graph)

    assert {:ok, _, :leaf} = ViewPort.find_point(vp, {25, 25})
    assert {:error, :not_found} = ViewPort.find_point(vp, {50, 25})
    assert {:error, :not_found} = ViewPort.find_point(vp, {25, 45})

    inside = {:cursor_button, {:button_left, 1, [], {25.0, 25.0}}}
    assert :ok = Input.send(vp, inside)
    assert_receive({:_input, ^inside, ^inside, :leaf}, 100)

    outside = {:cursor_button, {:button_left, 1, [], {50.0, 25.0}}}
    assert :ok = Input.send(vp, outside)
    refute_receive({:_input, _, _, :leaf}, 20)
  end

  test "clipped scissored group falls through to underlying sibling and intersects nested scissors",
       %{vp: vp, scene: scene} do
    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({100, 100}, id: :under, input: :cursor_button)
      |> Scenic.Primitives.group(
        fn graph ->
          Scenic.Primitives.group(
            graph,
            fn inner ->
              Scenic.Primitives.rect(inner, {80, 80}, id: :over, input: :cursor_button)
            end,
            scissor: {30, 30},
            translate: {10, 10}
          )
        end,
        scissor: {30, 30},
        translate: {10, 10}
      )

    Scenic.Scene.push_graph(scene, graph)

    # outer scissor: [10..40, 10..40], inner scissor: [20..50, 20..50]
    # intersection is [20..40, 20..40]
    assert {:ok, _, :over} = ViewPort.find_point(vp, {30, 30})
    # inside outer scissor but outside inner scissor -> falls through to :under
    assert {:ok, _, :under} = ViewPort.find_point(vp, {15, 15})
    # inside inner scissor but outside outer scissor -> falls through to :under
    assert {:ok, _, :under} = ViewPort.find_point(vp, {45, 45})

    clipped = {:cursor_button, {:button_left, 1, [], {45.0, 45.0}}}
    assert :ok = Input.send(vp, clipped)
    assert_receive({:_input, ^clipped, ^clipped, :under}, 100)
  end

  test "components inside scissored groups and scissored components resolve transforms and clip hits",
       %{vp: vp, scene: scene} do
    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.group(
        fn graph ->
          TestScissorComponent.add_to_graph(graph, self(),
            id: :child_comp,
            scissor: {30, 60},
            translate: {10, 10}
          )
        end,
        scissor: {50, 30},
        translate: {20, 20}
      )

    Scenic.Scene.push_graph(scene, graph)

    child_scene =
      receive do
        {:scissor_child_up, child_scene} -> child_scene
      after
        200 -> flunk("expected TestScissorComponent to initialize")
      end

    :_pong_ = GenServer.call(vp.pid, :_ping_)

    # Scene.fetch_transform still resolves the component inside the scissored group
    assert {:ok, tx} = Scenic.Scene.fetch_transform(child_scene)
    assert tx == Scenic.Math.Matrix.build_translation({30, 30})

    # parent scissor: [20..70, 20..50], component scissor: [30..60, 30..90]
    # intersection: [30..60, 30..50]
    child_pid = child_scene.pid
    assert {:ok, ^child_pid, :child_rect} = ViewPort.find_point(vp, {40, 40})
    # outside component scissor (x = 65 > 60), inside parent scissor
    assert {:error, :not_found} = ViewPort.find_point(vp, {65, 40})
    # outside parent scissor (y = 60 > 50), inside component scissor
    assert {:error, :not_found} = ViewPort.find_point(vp, {40, 60})

    # inside both scissors -> delivered with local coordinates ({40 - 30, 40 - 30})
    assert :ok = Input.send(vp, {:cursor_button, {:button_left, 1, [], {40.0, 40.0}}})

    assert_receive(
      {:child_input, {:cursor_button, {:button_left, 1, [], {10.0, 10.0}}}, :child_rect},
      100
    )

    # outside parent scissor -> clipped
    assert :ok = Input.send(vp, {:cursor_button, {:button_left, 1, [], {40.0, 60.0}}})
    refute_receive({:child_input, _, _}, 20)
  end

  test ":cursor_button only the input listed in a input style is requested", %{
    vp: vp,
    scene: scene
  } do
    # make like a driver
    GenServer.cast(vp.pid, {:register_driver, self()})
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([])}

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
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([])}

    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({10, 20}, input: :cursor_scroll)

    Scenic.Scene.push_graph(scene, graph)

    assert_receive({:_request_input_, [:cursor_scroll]}, 100)
  end

  test ":cursor_pos only the input listed in a input style is requested", %{vp: vp, scene: scene} do
    # make like a driver
    GenServer.cast(vp.pid, {:register_driver, self()})
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([])}

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

  test "cursor_button capture delivers when no scene transform is available", %{vp: vp} do
    # The test process deliberately is not a scene in the viewport graph, so
    # its local transform cannot be resolved. Capture still promises delivery;
    # drag owners rely on receiving button-up to release their capture.
    :ok = Input.capture(vp, :cursor_button)
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([:cursor_button])}

    input = {:cursor_button, {:button_left, 0, [], {310, 420}}}
    assert Input.send(vp, input) == :ok

    assert_receive(
      {:_input, {:cursor_button, {:button_left, 0, [], {310, 420}}}, ^input, nil},
      100
    )
  end

  test "cursor_scroll request works", %{vp: vp} do
    assert Input.fetch_captures!(vp) ~> {:ok, sorted_list([])}
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([])}

    :ok = Input.request(vp, :cursor_scroll)
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([:cursor_scroll])}

    assert Input.send(vp, {:cursor_scroll, {{1, 2}, {3, 4}}}) == :ok

    assert_receive(
      {:_input, {:cursor_scroll, {{1, 2}, {3, 4}}}, {:cursor_scroll, {{1, 2}, {3, 4}}}, nil},
      100
    )
  end

  test "cursor_scroll capture works", %{vp: vp} do
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([])}
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([])}

    :ok = Input.capture(vp, :cursor_scroll)
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([:cursor_scroll])}

    assert Input.send(vp, {:cursor_scroll, {{1, 2}, {3, 4}}}) == :ok

    assert_receive(
      {:_input, {:cursor_scroll, {{1, 2}, {3, 4}}}, {:cursor_scroll, {{1, 2}, {3, 4}}}, nil},
      100
    )
  end

  test "cursor_pos request works", %{vp: vp} do
    assert Input.fetch_captures!(vp) ~> {:ok, sorted_list([])}
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([])}

    :ok = Input.request(vp, :cursor_pos)
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([:cursor_pos])}

    assert Input.send(vp, {:cursor_pos, {1, 2}}) == :ok

    assert_receive(
      {:_input, {:cursor_pos, {1, 2}}, {:cursor_pos, {1, 2}}, nil},
      100
    )
  end

  test "cursor_pos capture works", %{vp: vp} do
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([])}
    assert Input.fetch_requests(vp) ~> {:ok, sorted_list([])}

    :ok = Input.capture(vp, :cursor_pos)
    assert Input.fetch_captures(vp) ~> {:ok, sorted_list([:cursor_pos])}

    assert Input.send(vp, {:cursor_pos, {1, 2}}) == :ok

    assert_receive(
      {:_input, {:cursor_pos, {1, 2}}, {:cursor_pos, {1, 2}}, nil},
      100
    )
  end

  # ----------------
  # drivers are sent input updates

  test "drivers are sent requested input updates", %{vp: vp} do
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([])}
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

    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([:cursor_button])}

    GenServer.cast(vp.pid, {:register_driver, self()})
    assert_receive({:_request_input_, [:cursor_button]}, 100)

    Scenic.Scene.stop(scene)

    # should get an update the owning scene goes down
    assert_receive({:_request_input_, []}, 100)
  end

  test "drivers are sent captured input updates", %{vp: vp, scene: scene} do
    Scenic.Scene.request_input(scene, :cursor_button)

    assert Input.fetch_captures!(vp) ~> {:ok, sorted_list([])}
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([:cursor_button])}

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

    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([:cursor_button])}
    self = self()
    # have to have an agent do the capture so that it comes from a different pid than this
    # test, which is pretending to be a driver...
    {:ok, agent} =
      Agent.start(fn ->
        GenServer.cast(vp.pid, {:register_scene, self(), :agent, nil, nil})
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
    assert Input.fetch_requests!(vp) ~> {:ok, sorted_list([:cursor_button])}
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
