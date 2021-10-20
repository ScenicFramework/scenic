#
#  Created by Boyd Multerer on 2018-11-18
#  Rewritten by Boyd Multerer on 2021-05-16
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

# re-writing it for version 0.11 to take advantage of the new scene struct
# and be more end-to-end in style

defmodule Scenic.Component.Input.CheckboxTest do
  use ExUnit.Case, async: false
  doctest Scenic.Component.Input.Checkbox

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort.Input

  @press_in {:cursor_button, {:btn_left, 1, [], {20, 2}}}
  @release_in {:cursor_button, {:btn_left, 0, [], {20, 2}}}

  @press_out {:cursor_button, {:btn_left, 1, [], {1000, 1000}}}
  @release_out {:cursor_button, {:btn_left, 0, [], {1000, 1000}}}

  defmodule TestScene do
    use Scenic.Scene
    import Scenic.Components

    def graph() do
      Graph.build()
      |> checkbox({"Check Box", false}, id: :checkbox)
    end

    @impl Scenic.Scene
    def init(scene, pid, _opts) do
      scene =
        scene
        |> assign(pid: pid)
        |> push_graph(graph())

      Process.send(pid, {:up, scene}, [])
      {:ok, scene}
    end

    @impl Scenic.Scene
    def handle_event(event, _from, %{assigns: %{pid: pid}} = scene) do
      send(pid, {:fwd_event, event})
      {:noreply, scene}
    end
  end

  setup do
    out = Scenic.Test.ViewPort.start({TestScene, self()})
    # wait for a signal that the scene is up before proceeding
    {:ok, scene} =
      receive do
        {:up, scene} -> {:ok, scene}
      end

    # make sure the button is up
    {:ok, [{_id, pid}]} = Scene.children(scene)
    :_pong_ = GenServer.call(pid, :_ping_)

    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    Map.put(out, :scene, scene)
  end

  test "Press in and release in sends the event", %{vp: vp} do
    Input.send(vp, @press_in)
    Input.send(vp, @release_in)
    assert_receive({:fwd_event, {:value_changed, :checkbox, true}}, 200)

    Input.send(vp, @press_in)
    Input.send(vp, @release_in)
    assert_receive({:fwd_event, {:value_changed, :checkbox, false}}, 200)
  end

  test "Press in and release out does not send the event", %{vp: vp} do
    Input.send(vp, @press_in)
    Input.send(vp, @release_out)
    refute_receive(_, 10)
  end

  test "Press out and release in does not send the event", %{vp: vp} do
    Input.send(vp, @press_out)
    Input.send(vp, @release_in)
    refute_receive(_, 10)
  end

  test "ignores non-main button clicks", %{vp: vp} do
    Input.send(vp, {:cursor_button, {1, :press, 0, {20, 2}}})
    Input.send(vp, {:cursor_button, {2, :press, 0, {20, 2}}})
    refute_receive(_, 10)
  end

  test "implements get/put", %{scene: scene} do
    assert Scene.get_child(scene, :checkbox) == [false]
    assert Scene.put_child(scene, :checkbox, true) == :ok
    assert Scene.get_child(scene, :checkbox) == [true]
  end

  test "implements fetch/update", %{scene: scene} do
    assert Scene.fetch_child(scene, :checkbox) == {:ok, [{"Check Box", false}]}
    %Scene{} = scene = Scene.update_child(scene, :checkbox, {"Updated text", true})
    assert Scene.fetch_child(scene, :checkbox) == {:ok, [{"Updated text", true}]}
    assert Scene.get_child(scene, :checkbox) == [true]
  end

  test "bounds works with defaults" do
    graph =
      Graph.build()
      |> Scenic.Components.checkbox({"Test Checkbox", false})

    {0.0, 0.0, r, b} = Graph.bounds(graph)
    assert r > 157 && r < 158
    assert b > 23 && b < 24
  end
end
