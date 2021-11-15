#
#  re-Created by Boyd Multerer May 2018.
#  re-re-Created by Boyd Multerer 2021-03-02.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.ViewPortTest do
  use ExUnit.Case, async: false
  doctest Scenic.ViewPort

  alias Scenic.ViewPort

  # @viewports :scenic_viewports

  # @main ViewPort.root_id()
  # @root "__root__"

  @root_id ViewPort.root_id()
  @main_id ViewPort.main_id()

  @simple_graph_red Scenic.Graph.build()
                    |> Scenic.Primitives.rect({200, 100}, fill: :red)
  defp simple_graph_red(), do: @simple_graph_red

  @simple_graph_green Scenic.Graph.build()
                      |> Scenic.Primitives.rect({200, 100}, fill: :green)
  defp simple_graph_green(), do: @simple_graph_green

  defmodule TestSceneRed do
    use Scenic.Scene

    def init(scene, pid, _) do
      graph =
        Scenic.Graph.build()
        |> Scenic.Primitives.rect({200, 100}, fill: :red, id: :rect, input: :cursor_button)

      scene =
        scene
        |> assign(pid: pid)
        |> push_graph(graph)

      Process.send(pid, :test_red_up, [])
      {:ok, scene}
    end

    def handle_input(input, id, %{assigns: %{pid: pid}} = scene) do
      GenServer.cast(pid, {:red_input, input, id})
      {:noreply, scene}
    end

    def handle_event(event, %{assigns: %{pid: pid}} = scene) do
      GenServer.cast(pid, {:red_event, event})
      {:noreply, scene}
    end
  end

  defmodule TestSceneGreen do
    use Scenic.Scene

    def init(scene, pid, _) do
      graph =
        Scenic.Graph.build()
        |> Scenic.Primitives.rect({200, 100}, fill: :green)

      scene =
        scene
        |> assign(pid: pid)
        |> push_graph(graph)

      Process.send(pid, :green_up, [])
      {:ok, scene}
    end
  end

  defmodule TestDriver do
    use Scenic.Driver

    def validate_opts(opts), do: {:ok, opts}
    def init(driver, _), do: {:ok, driver}

    def put_scripts(_ids, driver), do: {:ok, driver}
    def del_scripts(_ids, driver), do: {:ok, driver}
    def request_input(_input, driver), do: {:ok, driver}
    def reset_scene(driver), do: {:ok, driver}
    def clear_color(_color, driver), do: {:ok, driver}

    def handle_info(_, driver), do: {:noreply, driver}
    def handle_cast(_, driver), do: {:noreply, driver}
  end

  @driver_config [
    module: TestDriver,
    name: :test_driver,
    opts: [title: "test title"]
  ]

  setup do
    out = Scenic.Test.ViewPort.start({TestSceneRed, self()})

    # wait for a signal that the scene is up before proceeding
    receive do
      :test_red_up -> :ok
    end

    # needed to give time for the pid and vp to close
    on_exit(fn -> Process.sleep(1) end)

    out
  end

  test "root_id returns the root script id" do
    assert ViewPort.root_id() == "_root_"
  end

  test "main_id returns the main script id" do
    assert ViewPort.main_id() == "_main_"
  end

  # ============================================================================

  test "Driver accepts keyword options" do
    {:ok, %ViewPort{}} =
      ViewPort.start(
        name: :dyanmic_viewport,
        size: {700, 600},
        opts: [font: :roboto, font_size: 30, scale: 1.4],
        default_scene: {TestSceneGreen, self()},
        drivers: [@driver_config]
      )
  end

  test "Driver accepts map options" do
    {:ok, %ViewPort{}} =
      ViewPort.start(%{
        name: :dyanmic_viewport,
        size: {700, 600},
        opts: [font: :roboto, font_size: 30, scale: 1.4],
        default_scene: {TestSceneGreen, self()},
        drivers: [@driver_config]
      })
  end

  # ---------------------------------------------------------------------------
  # client api - start / stop / info

  test "start and stop dynamic viewport" do
    # start the viewport
    {:ok, %ViewPort{} = vp} =
      ViewPort.start(
        name: :dyanmic_viewport,
        size: {700, 600},
        opts: [font: :roboto, font_size: 30, scale: 1.4],
        default_scene: {TestSceneGreen, self()},
        drivers: [@driver_config]
      )

    assert_receive :green_up, 40

    # show the vp is running
    assert Process.alive?(vp.pid)

    # stop the vp
    ViewPort.stop(vp)

    # show the vp is NOT running
    refute Process.alive?(vp.pid)
  end

  test "start rejects invalid config" do
    assert_raise RuntimeError, fn ->
      ViewPort.start(invalid: 123)
    end
  end

  test "info gets an info record from just a pid", %{vp: vp} do
    assert ViewPort.info(vp.pid) == {:ok, vp}
  end

  # ---------------------------------------------------------------------------
  # client api - scripts

  test "put_script adds a script, auto registering the name. get_script returns it", %{
    vp: vp
  } do
    {:error, :not_found} = ViewPort.get_script(vp, "test_name")
    {:ok, "test_name"} = ViewPort.put_script(vp, "test_name", [1, 2, 3])
    assert ViewPort.get_script(vp, "test_name") == {:ok, [1, 2, 3]}
  end

  test "put_script replaces an existing script", %{vp: vp} do
    {:ok, "test_name"} = ViewPort.put_script(vp, "test_name", [1, 2, 3])
    assert ViewPort.get_script(vp, "test_name") == {:ok, [1, 2, 3]}
    {:ok, "test_name"} = ViewPort.put_script(vp, "test_name", [4, 5, 6])
    assert ViewPort.get_script(vp, "test_name") == {:ok, [4, 5, 6]}
  end

  test "get_script gets by id", %{vp: vp} do
    {:ok, "test_name"} = ViewPort.put_script(vp, "test_name", [1, 2, 3])
    assert ViewPort.get_script(vp, "test_name") == {:ok, [1, 2, 3]}
  end

  test "get_script_by_name gets by name", %{vp: vp} do
    {:ok, "test_name"} = ViewPort.put_script(vp, "test_name", [1, 2, 3])
    assert ViewPort.get_script(vp, "test_name") == {:ok, [1, 2, 3]}
  end

  test "del_script deletes scripts by name", %{vp: vp} do
    {:ok, "test_name"} = ViewPort.put_script(vp, "test_name", [1, 2, 3])
    :ok = ViewPort.del_script(vp, "test_name")
    Process.sleep(10)
    assert ViewPort.get_script(vp, "test_name") == {:error, :not_found}
  end

  test "del_script does nothing if script is not there", %{vp: vp} do
    :ok = ViewPort.del_script(vp, "unknown_name")
  end

  test "all_script_ids gets a list of script ids", %{vp: vp} do
    assert ViewPort.all_script_ids(vp) |> Enum.sort() == [@main_id, @root_id]
    {:ok, "test_name"} = ViewPort.put_script(vp, "test_name", [1, 2, 3])
    assert ViewPort.all_script_ids(vp) |> Enum.sort() == [@main_id, @root_id, "test_name"]
  end

  # ---------------------------------------------------------------------------
  # client api - graphs

  @simple_graph Scenic.Graph.build()
                |> Scenic.Primitives.rect({200, 100}, fill: :green)
  defp simple_graph(), do: @simple_graph

  test "put_graph compiles a graph and stores it's script", %{vp: vp} do
    assert ViewPort.get_script(vp, "test_graph") == {:error, :not_found}
    assert ViewPort.put_graph(vp, "test_graph", simple_graph()) == {:ok, "test_graph"}
    {:ok, _} = ViewPort.get_script(vp, "test_graph")

    # get the script and compare against one compiled
    {:ok, script} = Scenic.Graph.Compiler.compile(simple_graph())
    assert ViewPort.get_script(vp, "test_graph") == {:ok, script}
  end

  test "del_graph deletes existing graphs", %{vp: vp} do
    assert ViewPort.get_script(vp, "test_graph") == {:error, :not_found}
    assert ViewPort.put_graph(vp, "test_graph", simple_graph()) == {:ok, "test_graph"}
    {:ok, _} = ViewPort.get_script(vp, "test_graph")
    assert ViewPort.all_script_ids(vp) |> Enum.sort() == [@main_id, @root_id, "test_graph"]
  end

  # ---------------------------------------------------------------------------
  # client api - root and theme

  # set the root - this should stop the current scene and start a new one
  # we confirm this by examining the stored scripts in slot 1, which is the root scene
  test "set_root changes the running scene", %{vp: vp} do
    # first, prove that the red scene is running as the default
    {:ok, red_script} = Scenic.Graph.Compiler.compile(simple_graph_red())
    assert ViewPort.get_script(vp, @main_id) == {:ok, red_script}

    # set the green scene as the root
    assert ViewPort.set_root(vp, TestSceneGreen, self()) == :ok
    assert_receive :green_up, 40

    # prove the green scene is now running
    {:ok, green_script} = Scenic.Graph.Compiler.compile(simple_graph_green())
    assert ViewPort.get_script(vp, @main_id) == {:ok, green_script}
  end

  # set the theme - this should restart the current scene
  test "set_theme works", %{vp: vp} do
    assert ViewPort.set_theme(vp, {:scenic, :dark}) == :ok
  end

  # ---------------------------------------------------------------------------

  test "multiple VPs work at the same time without stepping on each other", %{vp: vp_0} do
    # there is one vp up. Start another
    {:ok, %ViewPort{} = vp_1} =
      ViewPort.start(
        size: {700, 600},
        opts: [font: :roboto, font_size: 30, scale: 1.4],
        default_scene: {TestSceneGreen, self()},
        drivers: [@driver_config]
      )

    assert_receive :green_up, 40

    # confirm the script ids are at the start
    assert ViewPort.all_script_ids(vp_0) |> Enum.sort() == [@main_id, @root_id]
    assert ViewPort.all_script_ids(vp_1) |> Enum.sort() == [@main_id, @root_id]

    # the scripts themselves should be different...
    assert ViewPort.get_script(vp_0, @root_id) != ViewPort.get_script(vp_1, @root_id)
  end
end
