#
#  Created by Boyd Multerer on 2018-11-18
#  Rewritten by Boyd Multerer on 2021-05-16
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

# re-writing it for version 0.11 to take advantage of the new scene struct
# and be more end-to-end in style

defmodule Scenic.Component.Input.DropdownTest do
  use ExUnit.Case, async: false
  doctest Scenic.Component.Input.Dropdown

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort.Input

  # import IEx

  @press_in {:cursor_button, {0, :press, 0, {20, 20}}}
  @release_in {:cursor_button, {0, :release, 0, {20, 20}}}

  @press_a {:cursor_button, {0, :press, 0, {20, 50}}}
  @release_a {:cursor_button, {0, :release, 0, {20, 50}}}

  @press_b {:cursor_button, {0, :press, 0, {20, 80}}}
  @release_b {:cursor_button, {0, :release, 0, {20, 80}}}

  @press_out {:cursor_button, {0, :press, 0, {1000, 1000}}}
  @release_out {:cursor_button, {0, :release, 0, {1000, 1000}}}

  defmodule TestScene do
    use Scenic.Scene
    import Scenic.Components

    def graph() do
      Graph.build()
      |> dropdown({[{"Option One", 1}, {"Option Two", 2}], 2}, id: :dropdown)
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

    out
    |> Map.put(:scene, scene)
    |> Map.put(:comp_pid, pid)
  end

  defp force_sync(vp_pid, scene_pid) do
    :_pong_ = GenServer.call(vp_pid, :_ping_)
    :_pong_ = GenServer.call(scene_pid, :_ping_)
    :_pong_ = GenServer.call(vp_pid, :_ping_)
  end

  test "press_in and release_a sends the event", %{vp: vp, comp_pid: comp_pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, comp_pid)
    Input.send(vp, @release_a)

    assert_receive({:fwd_event, {:value_changed, :dropdown, 1}}, 100)
  end

  test "press_in/release_in/press_in does nothing", %{vp: vp, comp_pid: comp_pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, comp_pid)
    Input.send(vp, @release_in)
    force_sync(vp.pid, comp_pid)
    Input.send(vp, @press_in)

    refute_receive(_, 10)
  end

  test "press_in and release_b sends the event", %{vp: vp, comp_pid: comp_pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, comp_pid)
    Input.send(vp, @release_b)

    assert_receive({:fwd_event, {:value_changed, :dropdown, 2}}, 100)
  end

  test "ignores non-main button clicks", %{vp: vp} do
    Input.send(vp, {:cursor_button, {1, :press, 0, {20, 20}}})
    Input.send(vp, {:cursor_button, {2, :press, 0, {20, 20}}})
    refute_receive(_, 10)
  end

  test "open press_a sends the event", %{vp: vp, comp_pid: comp_pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, comp_pid)
    Input.send(vp, @release_in)
    force_sync(vp.pid, comp_pid)
    Input.send(vp, @press_a)
    assert_receive({:fwd_event, {:value_changed, :dropdown, 1}}, 100)
  end

  test "open press_b sends the event", %{vp: vp, comp_pid: comp_pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, comp_pid)
    Input.send(vp, @release_in)
    force_sync(vp.pid, comp_pid)
    Input.send(vp, @press_b)
    assert_receive({:fwd_event, {:value_changed, :dropdown, 2}}, 100)
  end

  test "Press in and release out does not send the event", %{vp: vp, comp_pid: comp_pid} do
    Input.send(vp, @press_in)
    force_sync(vp.pid, comp_pid)
    Input.send(vp, @release_out)

    refute_receive(_, 10)
  end

  test "Press out and release in does not send the event", %{vp: vp, comp_pid: comp_pid} do
    Input.send(vp, @press_out)
    force_sync(vp.pid, comp_pid)
    Input.send(vp, @release_in)

    refute_receive(_, 10)
  end

  test "implements get/put", %{scene: scene} do
    assert Scene.get_child(scene, :dropdown) == [2]
    assert Scene.put_child(scene, :dropdown, 1) == :ok
    assert Scene.get_child(scene, :dropdown) == [1]
  end

  test "implements fetch/update", %{scene: scene} do
    assert Scene.fetch_child(scene, :dropdown) ==
             {:ok, [{[{"Option One", 1}, {"Option Two", 2}], 2}]}

    %Scene{} = scene = Scene.update_child(scene, :dropdown, {[{"mod One", 1}, {"mod Two", 2}], 1})
    assert Scene.fetch_child(scene, :dropdown) == {:ok, [{[{"mod One", 1}, {"mod Two", 2}], 1}]}
    assert Scene.get_child(scene, :dropdown) == [1]
  end

  test "bounds works with defaults" do
    graph =
      Graph.build()
      |> Scenic.Components.dropdown({[{"Option One", 1}, {"Option Two", 2}], 2}, id: :dd)

    {0.0, 0.0, r, b} = Graph.bounds(graph)
    assert r > 157 && r < 158
    assert b > 38 && b < 39
  end
end
