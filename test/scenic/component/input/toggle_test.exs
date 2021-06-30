#
#  Created by Eric Watson on 2018-09-18.
#  Rewritten by Boyd Multerer on 2021-05-16
#

# re-writing it for version 0.11 to take advantage of the new scene struct
# and be more end-to-end in style

defmodule Scenic.Component.Input.ToggleTest do
  use ExUnit.Case, async: false
  doctest Scenic.Component.Input.Toggle

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort.Input
  alias Scenic.Component

  @press_in {:cursor_button, {0, :press, 0, {20, 10}}}
  @release_in {:cursor_button, {0, :release, 0, {20, 10}}}

  @press_out {:cursor_button, {0, :press, 0, {1000, 1000}}}
  @release_out {:cursor_button, {0, :release, 0, {1000, 1000}}}

  defmodule TestScene do
    use Scenic.Scene
    import Scenic.Components

    def graph() do
      Graph.build()
      |> toggle(false, id: :toggle)
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
    assert_receive({:fwd_event, {:value_changed, :toggle, true}}, 200)

    Input.send(vp, @press_in)
    Input.send(vp, @release_in)
    assert_receive({:fwd_event, {:value_changed, :toggle, false}}, 200)
  end

  test "Press in and release out does not send the event", %{vp: vp} do
    Input.send(vp, @press_in)
    Input.send(vp, @release_out)
    refute_receive(_, 20)
  end

  test "Press out and release in does not send the event", %{vp: vp} do
    Input.send(vp, @press_out)
    Input.send(vp, @release_in)
    refute_receive(_, 20)
  end

  test "ignores non-main button clicks", %{vp: vp} do
    Input.send(vp, {:cursor_button, {1, :press, 0, {20, 10}}})
    Input.send(vp, {:cursor_button, {2, :press, 0, {20, 10}}})
    assert Process.alive?(vp.pid)
  end

  test "implements put/fetch", %{scene: scene} do
    {:ok, [pid]} = Scene.child(scene, :toggle)

    assert Component.fetch(pid) == {:ok, false}
    assert Component.put(pid, true) == :ok
    assert Component.fetch(pid) == {:ok, true}
    assert Component.put(pid, :abc) == {:error, :invalid}
    assert Component.fetch(pid) == {:ok, true}
  end
end
