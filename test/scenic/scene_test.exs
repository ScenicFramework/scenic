#
#  re-re-Created by Boyd Multerer May 2018.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#
#

defmodule Scenic.SceneTest do
  use ExUnit.Case, async: false
  doctest Scenic.Scene

  alias Scenic.ViewPort
  alias Scenic.Scene
  alias Scenic.Script
  import Scenic.Components

  @root_id ViewPort.root_id()

  # import IEx

  defmodule TestSceneNoKids do
    use Scenic.Scene, has_children: false

    @impl Scenic.Scene
    def init(scene, pid, _opts) do
      request_input(scene, :codepoint)
      Process.send(pid, {:up, scene}, [])
      scene = assign(scene, pid: pid)
      {:ok, scene}
    end

    @impl Scenic.Scene
    def handle_input(input, id, %{assigns: %{pid: pid}} = scene) do
      send(pid, {:input_test, input, id})
      {:noreply, scene}
    end

    @impl Scenic.Scene
    def handle_event(event, id, %{assigns: %{pid: pid}} = scene) do
      send(pid, {:event_test, event, id})
      {:noreply, scene}
    end

    @impl GenServer
    def handle_info(msg, %{assigns: %{pid: pid}} = scene) do
      send(pid, {:info_test, msg})
      {:noreply, scene}
    end

    @impl GenServer
    def handle_cast(msg, %{assigns: %{pid: pid}} = scene) do
      send(pid, {:cast_test, msg})
      {:noreply, scene}
    end

    @impl GenServer
    def handle_call(msg, _from, scene) do
      {:reply, {:call_test, msg}, scene}
    end
  end

  defmodule TestSceneKids do
    use Scenic.Scene

    @impl Scenic.Scene
    def init(scene, pid, _opts) do
      request_input(scene, :codepoint)
      Process.send(pid, {:up, scene}, [])
      scene = assign(scene, pid: pid)
      {:ok, scene}
    end
  end

  @codepoint {:codepoint, {"k", 0}}

  setup do
    out = Scenic.Test.ViewPort.start({TestSceneNoKids, self()})

    # wait for a signal that the scene is up before proceeding
    {:ok, scene} =
      receive do
        {:up, scene} -> {:ok, scene}
      end

    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    Map.put(out, :scene, scene)
  end

  # ---------------------------------------------------------------------------

  test "Scene handles input", %{vp: vp} do
    ViewPort.input(vp, @codepoint)
    assert_receive({:input_test, @codepoint, nil}, 200)
  end

  test "Scene handles events", %{scene: scene} do
    self = self()
    send(scene.pid, {:_event, {:event, 123}, self})
    assert_receive({:event_test, {:event, 123}, ^self}, 200)
  end

  test "Scene handles info", %{scene: scene} do
    Process.send(scene.pid, :custom_info, [])
    assert_receive({:info_test, :custom_info}, 200)
  end

  test "Scene handles cast", %{scene: scene} do
    GenServer.cast(scene.pid, :custom_cast)
    assert_receive({:cast_test, :custom_cast}, 200)
  end

  test "Scene handles call", %{scene: scene} do
    assert GenServer.call(scene.pid, :custom_call) == {:call_test, :custom_call}
  end

  # ---------------------------------------------------------------------------
  # basic scene struct manipulation

  test "Scene struct looks right", %{scene: scene} do
    %Scene{
      viewport: vp,
      pid: pid,
      module: module,
      theme: theme,
      parent: parent,
      children: children,
      child_supervisor: child_supervisor,
      assigns: assigns,
      supervisor: supervisor,
      stop_pid: stop_pid
    } = scene

    %ViewPort{} = vp
    assert is_pid(pid)
    assert module == TestSceneNoKids
    assert theme == :dark
    assert is_pid(parent)
    assert children == nil
    assert child_supervisor == nil
    assert assigns == %{}
    assert is_pid(supervisor)
    assert is_pid(stop_pid)
  end

  test "Scene struct looks right with kids" do
    Scenic.Test.ViewPort.start({TestSceneKids, self()})

    {:ok, scene} =
      receive do
        {:up, scene} -> {:ok, scene}
      end

    %Scene{
      viewport: vp,
      pid: pid,
      module: module,
      theme: theme,
      parent: parent,
      children: children,
      child_supervisor: child_supervisor,
      assigns: assigns,
      supervisor: supervisor,
      stop_pid: stop_pid
    } = scene

    %ViewPort{} = vp
    assert is_pid(pid)
    assert module == TestSceneKids
    assert theme == :dark
    assert is_pid(parent)
    %{} = children
    assert is_pid(child_supervisor)
    assert assigns == %{}
    assert is_pid(supervisor)
    assert is_pid(stop_pid)
  end

  test "assign assigns one value to the scene", %{scene: scene} do
    assert scene.assigns == %{}
    scene = Scene.assign(scene, :test, "abc")
    assert scene.assigns == %{test: "abc"}
  end

  test "assign assigns multiple values in a list", %{scene: scene} do
    assert scene.assigns == %{}

    scene =
      Scene.assign(scene,
        one: 1,
        two: 2,
        three: "three"
      )

    assert scene.assigns == %{one: 1, two: 2, three: "three"}
  end

  test "get gets a value from assigns - works like map", %{scene: scene} do
    scene =
      Scene.assign(scene,
        one: 1,
        two: 2,
        three: "three"
      )

    assert scene.assigns == %{one: 1, two: 2, three: "three"}

    assert Scene.get(scene, :one) == 1
    assert Scene.get(scene, :missing) == nil
    assert Scene.get(scene, :missing, "default") == "default"
  end

  test "fetch gets a value from assigns - works like map", %{scene: scene} do
    scene =
      Scene.assign(scene,
        one: 1,
        two: 2,
        three: "three"
      )

    assert scene.assigns == %{one: 1, two: 2, three: "three"}

    assert Scene.fetch(scene, :one) == {:ok, 1}
    assert Scene.fetch(scene, :missing) == :error
  end

  test "parent returns the parent pid", %{scene: scene} do
    assert Scene.parent(scene) == {:ok, scene.parent}
  end

  test "children returns an error if no children was specified", %{scene: scene} do
    assert Scene.children(scene) == {:error, :no_children}
  end

  test "children returns a list of id/pid pairs", %{scene: scene} do
    scene = Map.put(scene, :children, %{make_ref() => {nil, self(), :self, nil}})
    assert Scene.children(scene) == {:ok, [{:self, self()}]}
  end

  test "child returns an error if no children was specified", %{scene: scene} do
    assert Scene.child(scene, :abc) == {:error, :no_children}
  end

  test "children/child works" do
    Scenic.Test.ViewPort.start({TestSceneKids, self()})

    {:ok, scene} =
      receive do
        {:up, scene} -> {:ok, scene}
      end

    # no children pushed yet
    assert Scene.child(scene, :abc) == {:ok, []}

    # push a graph with components
    graph =
      Scenic.Graph.build()
      |> button("Button A", id: :button_a)
      |> button("Button B", id: :button_b)
      |> button("Button C0", id: :button_c)
      |> button("Button C1", id: :button_c)

    scene = Scene.push_graph(scene, graph)

    # children should work
    {:ok, kids} = Scene.children(scene)
    kids = Enum.sort(kids)

    [
      button_a: pid_a,
      button_b: pid_b,
      button_c: pid_c0,
      button_c: pid_c1
    ] = kids

    assert is_pid(pid_a)
    assert is_pid(pid_b)
    assert is_pid(pid_c0)
    assert is_pid(pid_c1)

    # child should work
    assert Scene.child(scene, :button_a) == {:ok, [pid_a]}
    assert Scene.child(scene, :button_b) == {:ok, [pid_b]}
    {:ok, cs} = Scene.child(scene, :button_c)
    assert cs == [pid_c0, pid_c1] || cs == [pid_c1, pid_c0]
  end

  # ---------------------------------------------------------------------------
  # sending messages

  test "send_parent_event works", %{scene: scene} do
    scene = Map.put(scene, :parent, self())

    :ok = Scene.send_parent_event(scene, :test_event)
    assert_receive({:_event, :test_event, sending_scene}, 100)
    assert sending_scene == scene.pid
  end

  test "send_parent works", %{scene: scene} do
    scene = Map.put(scene, :parent, self())

    :ok = Scene.send_parent(scene, :test_msg)
    assert_receive(:test_msg, 100)
  end

  test "cast_parent works", %{scene: scene} do
    scene = Map.put(scene, :parent, self())

    :ok = Scene.cast_parent(scene, :test_msg)
    assert_receive({:"$gen_cast", :test_msg}, 100)
  end

  test "send_children works", %{scene: scene} do
    scene = Map.put(scene, :children, %{make_ref() => {nil, self(), :self, nil}})

    :ok = Scene.send_children(scene, :test_msg)
    assert_receive(:test_msg, 100)
  end

  test "cast_children works", %{scene: scene} do
    scene = Map.put(scene, :children, %{make_ref() => {nil, self(), :self, nil}})

    :ok = Scene.cast_children(scene, :test_msg)
    assert_receive({:"$gen_cast", :test_msg}, 100)
  end

  # ---------------------------------------------------------------------------
  # stop the scene

  test "stop gracefully stops a scene", %{scene: scene} do
    assert Process.alive?(scene.pid)
    :ok = Scene.stop(scene)
    refute Process.alive?(scene.pid)
  end

  # ---------------------------------------------------------------------------
  # input

  test "fetch_requests works", %{scene: scene} do
    Scenic.Scene.request_input(scene, :cursor_button)

    assert Scene.fetch_requests(scene) == {:ok, [:cursor_button, :codepoint]}

    # request input from outside the scene
    :ok = ViewPort.Input.request(scene.viewport, :cursor_pos)

    # should only show input form the scene even though this is the caller
    assert Scene.fetch_requests(scene) == {:ok, [:cursor_button, :codepoint]}
  end

  test "request_input works", %{scene: scene} do
    Scenic.Scene.request_input(scene, :cursor_button)

    assert Scene.fetch_requests(scene) ==
             {:ok, [:cursor_button, :codepoint]}

    :ok = Scene.request_input(scene, :cursor_pos)

    assert Scene.fetch_requests(scene) ==
             {:ok, [:cursor_pos, :cursor_button, :codepoint]}
  end

  test "unrequest_input works", %{scene: scene} do
    Scenic.Scene.request_input(scene, :cursor_button)

    assert Scene.fetch_requests(scene) == {:ok, [:cursor_button, :codepoint]}

    :ok = Scene.unrequest_input(scene, :codepoint)
    assert Scene.fetch_requests(scene) == {:ok, [:cursor_button]}
  end

  test "fetch_captures works", %{scene: scene} do
    assert Scene.capture_input(scene, :key) == :ok
    assert Scene.fetch_captures(scene) == {:ok, [:key]}

    # request input from outside the scene
    :ok = ViewPort.Input.capture(scene.viewport, :cursor_pos)

    # should only show input form the scene even though this is the caller
    assert Scene.fetch_captures(scene) == {:ok, [:key]}
  end

  test "capture_input works", %{scene: scene} do
    assert Scene.fetch_captures(scene) == {:ok, []}

    :ok = Scene.capture_input(scene, :cursor_pos)
    assert Scene.fetch_captures(scene) == {:ok, [:cursor_pos]}
  end

  test "release_input works", %{scene: scene} do
    assert Scene.capture_input(scene, :cursor_pos) == :ok
    assert Scene.fetch_captures(scene) == {:ok, [:cursor_pos]}

    :ok = Scene.release_input(scene, :cursor_pos)
    assert Scene.fetch_captures(scene) == {:ok, []}
  end

  # ---------------------------------------------------------------------------
  # push

  test "push_script pushes into the ViewPort's script table", %{vp: vp, scene: scene} do
    assert ViewPort.all_script_ids(vp) == [@root_id]

    script =
      Script.start()
      |> Script.draw_triangle(0, 1, 2, 3, 4, 5, :stroke)
      |> Script.finish()

    Scene.push_script(scene, script, "test_script")

    assert ViewPort.all_script_ids(vp) |> Enum.sort() == [@root_id, "test_script"]
  end

  test "push_graph pushes into the ViewPort's script table", %{vp: vp, scene: scene} do
    assert ViewPort.all_script_ids(vp) == [@root_id]

    graph =
      Scenic.Graph.build()
      |> Scenic.Primitives.rect({100, 200}, fill: :red)

    Scene.push_graph(scene, graph)

    assert ViewPort.all_script_ids(vp) |> Enum.sort() == [ViewPort.main_id(), @root_id]
  end
end
