#
#  Created by Boyd Multerer on 2021-05-16
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Component.Input.SliderListTest do
  use ExUnit.Case, async: false
  doctest Scenic.Component.Input.Slider

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort.Input
  alias Scenic.Component

  # import IEx

  @press {:cursor_button, {0, :press, 0, {20, 10}}}
  @release {:cursor_button, {0, :release, 0, {20, 10}}}

  @pos_0 {:cursor_pos, {70, 10}}
  @pos_1 {:cursor_pos, {140, 10}}
  @pos_2 {:cursor_pos, {260, 10}}
  @pos_3 {:cursor_pos, {360, 10}}

  @pos_before {:cursor_pos, {-10, 10}}
  @pos_after {:cursor_pos, {500, 10}}

  defmodule TestScene do
    use Scenic.Scene
    import Scenic.Components

    def graph() do
      Graph.build()
      |> slider({[:a, :b, :c, :d, :e], :b}, id: :slider_list)
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
    {:ok, [pid]} = Scene.child(scene, :slider_list)
    :_pong_ = GenServer.call(pid, :_ping_)

    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    out
    |> Map.put(:scene, scene)
    |> Map.put(:pid, pid)
  end

  defp force_sync(vp_pid, scene_pid) do
    :_pong_ = GenServer.call(vp_pid, :_ping_)
    :_pong_ = GenServer.call(scene_pid, :_ping_)
    :_pong_ = GenServer.call(vp_pid, :_ping_)
  end

  test "validate passes list extents and initial value" do
    data = {[:a, :b, :c], :b}
    assert Component.Input.Slider.validate(data) == {:ok, data}
  end

  test "validate rejects initial value outside the extents" do
    {:error, msg} = Component.Input.Slider.validate({[:a, :b, :c], :d})
    assert msg =~ "not in"
  end

  test "press/release moves the slider and sends a message but pressing again in the same spot does not",
       %{vp: vp, pid: pid} do
    Input.send(vp, @press)
    force_sync(vp.pid, pid)
    assert_receive({:fwd_event, {:value_changed, :slider_list, :a}}, 100)
    Input.send(vp, @release)

    force_sync(vp.pid, pid)
    Input.send(vp, @press)
    force_sync(vp.pid, pid)
    Input.send(vp, @release)
    refute_receive(_, 10)
  end

  test "press & drag sends multiple messages", %{vp: vp, pid: pid} do
    Input.send(vp, @press)
    force_sync(vp.pid, pid)
    assert_receive({:fwd_event, {:value_changed, :slider_list, :a}}, 100)

    Input.send(vp, @pos_0)
    assert_receive({:fwd_event, {:value_changed, :slider_list, :b}}, 100)

    Input.send(vp, @pos_1)
    assert_receive({:fwd_event, {:value_changed, :slider_list, :c}}, 100)

    Input.send(vp, @pos_2)
    assert_receive({:fwd_event, {:value_changed, :slider_list, :d}}, 100)

    Input.send(vp, @pos_3)
    assert_receive({:fwd_event, {:value_changed, :slider_list, :e}}, 100)
  end

  test "positions pin to the front and end of the slider", %{vp: vp, pid: pid} do
    Input.send(vp, @press)
    force_sync(vp.pid, pid)
    assert_receive({:fwd_event, {:value_changed, :slider_list, :a}}, 100)

    Input.send(vp, @pos_0)
    assert_receive({:fwd_event, {:value_changed, :slider_list, :b}}, 100)

    Input.send(vp, @pos_before)
    assert_receive({:fwd_event, {:value_changed, :slider_list, :a}}, 100)

    Input.send(vp, @pos_after)
    assert_receive({:fwd_event, {:value_changed, :slider_list, :e}}, 100)
  end

  test "ignores non-main button clicks", %{vp: vp} do
    Input.send(vp, {:cursor_button, {1, :press, 0, {20, 10}}})
    Input.send(vp, {:cursor_button, {2, :press, 0, {20, 10}}})
    refute_receive(_, 10)
  end

  test "implements get/put", %{scene: scene} do
    assert Scene.get_child(scene, :slider_list) == [:b]
    assert Scene.put_child(scene, :slider_list, :c) == :ok
    assert Scene.get_child(scene, :slider_list) == [:c]
  end

  test "implements fetch/update", %{scene: scene} do
    assert Scene.fetch_child(scene, :slider_list) == {:ok, [{[:a, :b, :c, :d, :e], :b}]}
    %Scene{} = scene = Scene.update_child(scene, :slider_list, {[:aa, :bb, :cc, :dd, :ee], :ee})
    assert Scene.fetch_child(scene, :slider_list) == {:ok, [{[:aa, :bb, :cc, :dd, :ee], :ee}]}
    assert Scene.get_child(scene, :slider_list) == [:ee]
  end
end
