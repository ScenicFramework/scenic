#
#  Created by Boyd Multerer on 2018-09-18.
#  Rewritten by Boyd Multerer on 2021-05-23
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Component.Input.RadioGroupTest do
  use ExUnit.Case, async: false
  doctest Scenic.Component.Input.RadioGroup

  alias Scenic.Scene
  alias Scenic.ViewPort.Input

  # import IEx

  @press_a {:cursor_button, {0, :press, 0, {10, 10}}}
  @release_a {:cursor_button, {0, :release, 0, {10, 10}}}

  @press_b {:cursor_button, {0, :press, 0, {10, 34}}}
  @release_b {:cursor_button, {0, :release, 0, {10, 34}}}

  @press_c {:cursor_button, {0, :press, 0, {10, 58}}}
  @release_c {:cursor_button, {0, :release, 0, {10, 58}}}

  @press_out {:cursor_button, {0, :press, 0, {1000, 1000}}}
  @release_out {:cursor_button, {0, :release, 0, {1000, 1000}}}

  defmodule TestScene do
    use Scenic.Scene
    import Scenic.Components

    def graph() do
      Scenic.Graph.build()
      |> radio_group(
        {
          [
            {"Radio A", :radio_a},
            {"Radio B", :radio_b},
            {"Radio C", :radio_c}
          ],
          :radio_b
        },
        id: :radio_group
      )
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

    # make sure the group component is up
    {:ok, [{_id, group_pid}]} = Scene.children(scene)
    :_pong_ = GenServer.call(group_pid, :_ping_)

    # we know there are 3 child scenes, but need to find them
    [sup | _] =
      group_pid
      |> Process.info()
      |> get_in([:dictionary, :"$ancestors"])

    [_, {DynamicSupervisor, kid_sup, _, _}] = Supervisor.which_children(sup)

    # ping each child, forcing sync until they are up
    btn_pids =
      kid_sup
      |> Supervisor.which_children()
      |> Enum.map(fn {_, pid, :worker, [Scenic.Scene]} -> pid end)

    Enum.each(btn_pids, &GenServer.call(&1, :_ping_))

    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    out
    |> Map.put(:scene, scene)
    |> Map.put(:group_pid, group_pid)
    |> Map.put(:btn_pids, btn_pids)
  end

  defp force_sync(vp, group_pid, btn_pids) do
    :_pong_ = GenServer.call(vp.pid, :_ping_)
    Enum.each(btn_pids, &GenServer.call(&1, :_ping_))
    :_pong_ = GenServer.call(group_pid, :_ping_)
  end

  test "Press in and release in A sends the event", %{vp: vp} do
    Input.send(vp, @press_a)
    Input.send(vp, @release_a)
    assert_receive({:fwd_event, {:value_changed, :radio_group, :radio_a}}, 200)
  end

  test "Press in A and release out does not send the event", %{vp: vp} do
    Input.send(vp, @press_a)
    Input.send(vp, @release_out)
    refute_receive(_, 10)
  end

  test "Press out and release in A does not send the event", %{vp: vp} do
    Input.send(vp, @press_out)
    Input.send(vp, @release_a)
    refute_receive(_, 10)
  end

  test "Can press/release the various buttons", %{
    vp: vp,
    group_pid: group_pid,
    btn_pids: btn_pids
  } do
    Input.send(vp, @press_a)
    force_sync(vp, group_pid, btn_pids)
    Input.send(vp, @release_a)
    force_sync(vp, group_pid, btn_pids)
    assert_receive({:fwd_event, {:value_changed, :radio_group, :radio_a}}, 200)

    Input.send(vp, @press_c)
    force_sync(vp, group_pid, btn_pids)
    Input.send(vp, @release_c)
    force_sync(vp, group_pid, btn_pids)
    assert_receive({:fwd_event, {:value_changed, :radio_group, :radio_c}}, 200)

    Input.send(vp, @press_b)
    force_sync(vp, group_pid, btn_pids)
    Input.send(vp, @release_b)
    force_sync(vp, group_pid, btn_pids)
    assert_receive({:fwd_event, {:value_changed, :radio_group, :radio_b}}, 200)

    Input.send(vp, @press_a)
    force_sync(vp, group_pid, btn_pids)
    Input.send(vp, @release_a)
    force_sync(vp, group_pid, btn_pids)
    assert_receive({:fwd_event, {:value_changed, :radio_group, :radio_a}}, 200)
  end

  test "ignores non-main button clicks", %{vp: vp} do
    Input.send(vp, {:cursor_button, {1, :press, 0, {10, 10}}})
    Input.send(vp, {:cursor_button, {2, :press, 0, {10, 10}}})
    refute_receive(_, 10)
  end

  test "implements fetch", %{scene: scene} do
    assert Scene.child_value(scene, :radio_group) == {:ok, [:radio_b]}
  end
end
