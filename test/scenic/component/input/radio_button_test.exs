#
#  Created by Boyd Multerer on 2018-09-18.
#  Rewritten by Boyd Multerer on 2021-05-23
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Component.Input.RadioButtonTest do
  use ExUnit.Case, async: false
  doctest Scenic.Component.Input.RadioButton

  alias Scenic.Scene
  alias Scenic.ViewPort.Input
  alias Scenic.Component.Input.RadioButton

  # import IEx

  @press_in {:cursor_button, {:btn_left, 1, [], {20, 2}}}
  @release_in {:cursor_button, {:btn_left, 0, [], {20, 2}}}

  @press_out {:cursor_button, {:btn_left, 1, [], {1000, 1000}}}
  @release_out {:cursor_button, {:btn_left, 0, [], {1000, 1000}}}

  defmodule TestScene do
    use Scenic.Scene

    def graph() do
      Scenic.Graph.build()
      |> RadioButton.add_to_graph({"Radio Button", :radio_button, false}, id: :btn)
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

    # make sure the component is up
    {:ok, [{_id, pid}]} = Scene.children(scene)
    :_pong_ = GenServer.call(pid, :_ping_)

    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    Map.put(out, :scene, scene)
  end

  test "Press in and release in sends the event", %{vp: vp} do
    Input.send(vp, @press_in)
    Input.send(vp, @release_in)
    assert_receive({:fwd_event, {:click, :radio_button}}, 200)
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
    assert Scene.get_child(scene, :btn) == [false]
    assert Scene.put_child(scene, :btn, true) == :ok
    assert Scene.get_child(scene, :btn) == [true]
  end

  test "implements fetch/update", %{scene: scene} do
    assert Scene.fetch_child(scene, :btn) == {:ok, [{"Radio Button", :radio_button, false}]}
    %Scene{} = scene = Scene.update_child(scene, :btn, {"RadioMod", :radio_mod, true})
    assert Scene.fetch_child(scene, :btn) == {:ok, [{"RadioMod", :radio_mod, true}]}
    assert Scene.get_child(scene, :btn) == [true]
  end

  test "bounds works with defaults" do
    graph =
      Scenic.Graph.build()
      |> RadioButton.add_to_graph({"Radio Button", :rb, false}, id: :btn)

    {0.0, 0.0, r, b} = Scenic.Graph.bounds(graph)
    assert r > 140 && r < 141
    assert b > 23 && b < 24
  end
end
