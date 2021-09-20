#
#  Created by Boyd Multerer on 2018-09-18.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Component.Input.SliderNumericTest do
  use ExUnit.Case, async: false
  doctest Scenic.Component.Input.Slider

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort.Input
  alias Scenic.Component

  # import IEx

  @press {:cursor_button, {:btn_left, 1, [], {14, 10}}}
  @release {:cursor_button, {:btn_left, 0, [], {14, 10}}}

  @pos_0 {:cursor_pos, {58, 10}}
  @pos_1 {:cursor_pos, {100, 10}}
  @pos_2 {:cursor_pos, {142, 10}}
  @pos_3 {:cursor_pos, {186, 10}}

  @pos_before {:cursor_pos, {-10, 10}}
  @pos_after {:cursor_pos, {500, 10}}

  defmodule TestScene do
    use Scenic.Scene
    import Scenic.Components

    def graph() do
      Graph.build()
      |> slider({{0, 100}, 20}, id: :slider_num)
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
    {:ok, [pid]} = Scene.child(scene, :slider_num)
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

  test "validate passes numeric extents and initial value" do
    data = {{10, 20}, 15}
    assert Component.Input.Slider.validate(data) == {:ok, data}
  end

  test "validate rejects initial value below the min" do
    {:error, msg} = Component.Input.Slider.validate({{10, 20}, 5})
    assert msg =~ "is below the min"
  end

  test "validate rejects initial value above the max" do
    {:error, msg} = Component.Input.Slider.validate({{10, 20}, 25})
    assert msg =~ "is above the max"
  end

  test "validate rejects min above the max" do
    {:error, msg} = Component.Input.Slider.validate({{20, 10}, 15})
    assert msg =~ "above the max"
  end

  test "press/release moves the slider and sends a message but pressing again in the same spot does not",
       %{vp: vp, pid: pid} do
    Input.send(vp, @press)
    force_sync(vp.pid, pid)
    assert_receive({:fwd_event, {:value_changed, :slider_num, 5}}, 100)
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
    assert_receive({:fwd_event, {:value_changed, :slider_num, 5}}, 100)

    Input.send(vp, @pos_0)
    assert_receive({:fwd_event, {:value_changed, :slider_num, 19}}, 100)

    Input.send(vp, @pos_1)
    assert_receive({:fwd_event, {:value_changed, :slider_num, 33}}, 100)

    Input.send(vp, @pos_2)
    assert_receive({:fwd_event, {:value_changed, :slider_num, 47}}, 100)

    Input.send(vp, @pos_3)
    assert_receive({:fwd_event, {:value_changed, :slider_num, 62}}, 100)
  end

  test "positions pin to the front and end of the slider", %{vp: vp, pid: pid} do
    Input.send(vp, @press)
    force_sync(vp.pid, pid)
    assert_receive({:fwd_event, {:value_changed, :slider_num, 5}}, 100)

    Input.send(vp, @pos_before)
    assert_receive({:fwd_event, {:value_changed, :slider_num, 0}}, 100)

    Input.send(vp, @pos_after)
    assert_receive({:fwd_event, {:value_changed, :slider_num, 100}}, 100)
  end

  test "ignores non-main button clicks", %{vp: vp} do
    Input.send(vp, {:cursor_button, {1, :press, 0, {14, 10}}})
    Input.send(vp, {:cursor_button, {2, :press, 0, {14, 10}}})
    refute_receive(_, 10)
  end

  test "implements get/put", %{scene: scene} do
    assert Scene.get_child(scene, :slider_num) == [20]
    assert Scene.put_child(scene, :slider_num, 30) == :ok
    assert Scene.get_child(scene, :slider_num) == [30]
  end

  test "implements fetch/update", %{scene: scene} do
    assert Scene.fetch_child(scene, :slider_num) == {:ok, [{{0, 100}, 20}]}
    %Scene{} = scene = Scene.update_child(scene, :slider_num, {{10, 110}, 30})
    assert Scene.fetch_child(scene, :slider_num) == {:ok, [{{10, 110}, 30}]}
    assert Scene.get_child(scene, :slider_num) == [30]
  end

  test "bounds works with defaults" do
    graph =
      Scenic.Graph.build()
      |> Scenic.Components.slider({{0, 100}, 20}, id: :sn)

    {0.0, 0.0, 300.0, 18.0} = Scenic.Graph.bounds(graph)
  end

  test "bounds works with overrides" do
    graph =
      Graph.build()
      |> Scenic.Components.slider({{0, 100}, 20}, id: :sn, width: 400)

    assert Graph.bounds(graph) == {0.0, 0.0, 400.0, 18.0}
  end
end
