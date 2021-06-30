#
#  Created by Boyd Multerer on 2018-07-15
#  Rewritten by Boyd Multerer on 2021-05-16
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

# re-writing it for version 0.11 to take advantage of the new scene struct
# and be more end-to-end in style

defmodule Scenic.SceneTxTest do
  use ExUnit.Case, async: false

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.ViewPort
  alias Scenic.Math.Matrix

# import IEx
  
  @expected_n0 Matrix.build_translation( {20, 30} )
  @expected_n1 [
      Matrix.build_translation( {20, 30} ),
      Matrix.build_translation( {100, 200} ),
    ]
    |> Matrix.mul()


  defmodule Nested1 do
    use Scenic.Component
    import Scenic.Primitives

    @impl Scenic.Component
    def validate(pid) when is_pid(pid), do: {:ok, pid}

    @impl Scenic.Scene
    def init(scene, pid, _opts) do
      graph = Graph.build()
        |> rect( {10,10}, id: :n1_rect, input: true )

      # request xy inputs
      request_input( scene, [:cursor_pos])

      scene =
        scene
        |> assign( pid: pid )
        |> push_graph( graph )

      Process.send( pid, {:nested_1, scene}, [] )
      {:ok, scene}
    end

    @impl Scenic.Scene
    # def handle_input(input, %{assigns: %{pid: pid}} = scene) do
    def handle_input(input, id, scene) do
      send(scene.assigns.pid, {:n1_input, input, id})
      {:noreply, scene}
    end
  end

  defmodule Nested0 do
    use Scenic.Component
    import Scenic.Primitives

    @impl Scenic.Component
    def validate(pid) when is_pid(pid), do: {:ok, pid}

    @impl Scenic.Scene
    def init(scene, pid, _opts) do
      graph = Graph.build()
        |> Nested1.add_to_graph( pid, id: :nested_1, t: {100, 200})
        |> rect( {10,10}, id: :n0_rect, input: true )

      request_input( scene, [:cursor_pos])

      scene =
        scene
        |> assign( pid: pid )
        |> push_graph( graph )

      Process.send( pid, {:nested_0, scene}, [] )
      {:ok, scene}
    end

    @impl Scenic.Scene
    # def handle_input(input, %{assigns: %{pid: pid}} = scene) do
    def handle_input(input, id, scene) do
      send(scene.assigns.pid, {:n0_input, input, id})
      {:noreply, scene}
    end
  end

  defmodule MainScene do
    use Scenic.Scene
    import Scenic.Primitives

    @impl Scenic.Scene
    def init(scene, pid, _opts) do
      graph = Graph.build()
        |> rect( {10,10}, id: :main_rect, input: true )
        |> Nested0.add_to_graph( pid, id: :nested_0, t: {20,30} )

      scene =
        scene
        |> assign( pid: pid )
        |> push_graph( graph )
      Process.send( pid, {:main, scene}, [] )
      {:ok, scene}
    end
  end

  setup do
    out = Scenic.Test.ViewPort.start({MainScene, self()})
    # wait for a signal that the scene is up before proceeding
    {:ok, main} = receive do {:main, scene} -> {:ok, scene} end
    {:ok, nested_0} = receive do {:nested_0, scene} -> {:ok, scene} end
    {:ok, nested_1} = receive do {:nested_1, scene} -> {:ok, scene} end
    :_pong_ = GenServer.call( out.vp.pid, :_ping_ )

    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    out
    |> Map.put( :main, main )
    |> Map.put( :nested_0, nested_0 )
    |> Map.put( :nested_1, nested_1 )
  end

  test "fetch_transform works", %{nested_0: nested_0, nested_1: nested_1} do
    assert Scene.fetch_transform( nested_0 ) == {:ok, @expected_n0}
    assert Scene.fetch_transform( nested_1 ) == {:ok, @expected_n1}

    bad_scene = Map.put( nested_0, :id, :bad_scene )
    assert Scene.fetch_transform( bad_scene ) == {:error, :not_found}
  end

  test "get_transform works", %{nested_0: nested_0, nested_1: nested_1} do
    assert Scene.get_transform( nested_0 ) == @expected_n0
    assert Scene.get_transform( nested_1 ) == @expected_n1

    bad_scene = Map.put( nested_0, :id, :bad_scene )
    assert Scene.get_transform( bad_scene ) == Matrix.identity()
  end

  test "global_to_local works", %{nested_0: nested_0, nested_1: nested_1} do
    assert Scene.global_to_local( nested_0, {25.0, 35.0} ) == {5.0, 5.0}
    assert Scene.global_to_local( nested_1, {125.0, 235.0} ) == {5.0, 5.0}
  end

  test "local_to_global works", %{nested_0: nested_0, nested_1: nested_1} do
    assert Scene.local_to_global( nested_0, {5.0, 5.0} ) == {25.0, 35.0}
    assert Scene.local_to_global( nested_1, {5.0, 5.0} ) == {125.0, 235.0}
  end

  test "ViewPort.find_point works", %{vp: vp, main: main, nested_0: nested_0, nested_1: nested_1} do
    assert ViewPort.find_point(vp, {15.0, 25.0}) == { :error, :not_found }
    assert ViewPort.find_point(vp, {5.0, 5.0}) == { :ok, main.pid, :main_rect }
    assert ViewPort.find_point(vp, {25.0, 35.0}) == { :ok, nested_0.pid, :n0_rect }
    assert ViewPort.find_point(vp, {125.0, 235.0}) == { :ok, nested_1.pid, :n1_rect }
  end

  test "requested cursor_button input is delivered and transformed to the requesting scene", %{vp: vp} do
    :ok = ViewPort.Input.send(vp, {:cursor_button, {0, :press, 0, {25.0, 35.0}}})
    assert_receive( {:n0_input, {:cursor_button, {0, :press, 0, {5.0, 5.0}}}, :n0_rect}, 200 )
    refute_receive( {:n1_input, {:cursor_button, {0, :press, 0, {-95.0, -195.0}}}, nil}, 20 )

    :ok = ViewPort.Input.send(vp, {:cursor_button, {0, :press, 0, {125.0, 235.0}}})
    refute_receive( {:n0_input, {:cursor_button, {0, :press, 0, {105.0, 205.0}}}, nil}, 20 )
    assert_receive( {:n1_input, {:cursor_button, {0, :press, 0, {5.0, 5.0}}}, :n1_rect}, 200 )
  end

  test "requested cursor_pos input is delivered and transformed to the requesting scene", %{vp: vp} do
    :ok = ViewPort.Input.send(vp, {:cursor_pos, {25.0, 35.0}})
    assert_receive( {:n0_input, {:cursor_pos, {5.0, 5.0}}, :n0_rect}, 200 )
    refute_receive( {:n1_input, {:cursor_pos, {-95.0, -195.0}}, nil}, 20 )

    :ok = ViewPort.Input.send(vp, {:cursor_pos, {125.0, 235.0}})
    refute_receive( {:n0_input, {:cursor_pos, {105.0, 205.0}}, nil}, 20 )
    assert_receive( {:n1_input, {:cursor_pos, {5.0, 5.0}}, :n1_rect}, 200 )
  end

end