#
#  Created by Boyd Multerer on 2018-07-15
#  Rewritten by Boyd Multerer on 2021-05-16
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

# re-writing it for version 0.11 to take advantage of the new scene struct
# and be more end-to-end in style

defmodule Scenic.Component.ButtonTest do
  use ExUnit.Case, async: false
  doctest Scenic.Component.Button

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort.Input

# import IEx

  @press_in     { :cursor_button, {0, :press, 0, {20, 20}} }
  @release_in   { :cursor_button, {0, :release, 0, {20, 20}} }

  @press_out    { :cursor_button, {0, :press, 0, {1000, 1000}} }
  @release_out  { :cursor_button, {0, :release, 0, {1000, 1000}} }


  defmodule TestScene do
    use Scenic.Scene
    import Scenic.Components

    def graph() do
      Graph.build()
        |> button("Test Button", id: :test_btn)
    end

    @impl Scenic.Scene
    def init(scene, pid, _opts) do
      scene =
        scene
        |> assign( pid: pid )
        |> push_graph( graph() )
      Process.send( pid, {:up, scene}, [] )
      {:ok, scene}
    end

    @impl Scenic.Scene
    def handle_event( event, _from, %{assigns: %{pid: pid}} = scene ) do
      send( pid, {:fwd_event, event} )
      {:noreply, scene}
    end

  end

  setup do
    out = Scenic.Test.ViewPort.start({TestScene, self()})
    # wait for a signal that the scene is up before proceeding
    {:ok, scene} = receive do {:up, scene} -> {:ok, scene} end
    # make sure the button is up
    {:ok, [{_id,pid}]} = Scene.children(scene)
    :_pong_ = GenServer.call( pid, :_ping_ )

    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    out
  end
  
  test "validate passes valid data" do
    assert Scenic.Component.Button.validate("Text") == {:ok, "Text"}
  end

  test "validate rejects initial value outside the extents" do
    {:error, msg} = Scenic.Component.Button.validate(123)
    assert msg =~ "Invalid Button"
  end

  test "ignores non-main button clicks", %{vp: vp}  do
    Input.send( vp, { :cursor_button, {1, :press, 0, {20, 20}} } )
    Input.send( vp, { :cursor_button, {2, :press, 0, {20, 20}} } )
    refute_receive( _, 10)
  end

  test "Press in and release in sends the event", %{vp: vp} do
    Input.send( vp, @press_in )
    Input.send( vp, @release_in )
    assert_receive( {:fwd_event, {:click, :test_btn}}, 200)
  end

  test "Press in and release out does not send the event", %{vp: vp} do
    Input.send( vp, @press_in )
    Input.send( vp, @release_out )
    refute_receive( _, 10)
  end

  test "Press out and release in does not send the event", %{vp: vp} do
    Input.send( vp, @press_out )
    Input.send( vp, @release_in )
    refute_receive( _, 10)
  end

end
