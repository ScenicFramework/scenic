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
  alias Scenic.Component

  # import IEx

  @press_in     { :cursor_button, {0, :press, 0, {20, 2}} }
  @release_in   { :cursor_button, {0, :release, 0, {20, 2}} }

  @press_out    { :cursor_button, {0, :press, 0, {1000, 1000}} }
  @release_out  { :cursor_button, {0, :release, 0, {1000, 1000}} }


  defmodule TestScene do
    use Scenic.Scene

    def graph() do
      Scenic.Graph.build()
        |> RadioButton.add_to_graph( {"Radio Button", :radio_button, false}, id: :radio_button )
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
    # make sure the component is up
    {:ok, [{_id,pid}]} = Scene.children(scene)
    :_pong_ = GenServer.call( pid, :_ping_ )

    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    Map.put( out, :scene, scene )
  end


  test "Press in and release in sends the event", %{vp: vp} do
    Input.send( vp, @press_in )
    Input.send( vp, @release_in )
    assert_receive( {:fwd_event, {:click, :radio_button}}, 200)
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

  test "ignores non-main button clicks", %{vp: vp}  do
    Input.send( vp, { :cursor_button, {1, :press, 0, {20, 2}} } )
    Input.send( vp, { :cursor_button, {2, :press, 0, {20, 2}} } )
    refute_receive( _, 10)
  end

  test "implements put/fetch", %{scene: scene} do
    {:ok, [pid]} = Scene.child( scene, :radio_button )

    assert Component.fetch( pid ) == { :ok, false }
    assert Component.put( pid, true ) == :ok
    assert Component.fetch( pid ) == { :ok, true }
    assert Component.put( pid, :abc ) == {:error, :invalid}
    assert Component.fetch( pid ) == { :ok, true }
  end

end
