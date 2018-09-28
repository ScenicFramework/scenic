#
#  re-Created by Boyd Multerer May 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPortTest do
  use ExUnit.Case, async: false
  doctest Scenic.ViewPort
  alias Scenic.ViewPort
  alias Scenic.Scene
  alias Scenic.ViewPort.Tables

  @viewports :scenic_dyn_viewports

  defmodule TestSceneOne do
    use Scenic.Scene
    def init(_, _), do: {:ok, nil}
  end

  defmodule TestSceneTwo do
    use Scenic.Scene
    def init(_, _), do: {:ok, nil}
  end

  defmodule TestDriver do
    use Scenic.ViewPort.Driver
    def init(_, {_, _}, _), do: {:ok, :test_driver_state}
  end

  @config %{
    name: :dyanmic_viewport,
    size: {700, 600},
    opts: [font: :roboto_slab, font_size: 30, scale: 1.0],
    default_scene: {TestSceneOne, nil},
    drivers: [
      %{
        module: TestDriver,
        name: :test_driver,
        opts: [title: "test title"]
      }
    ]
  }

  import IEx

  setup do
    {:ok, tables} = Tables.start_link(nil)
    on_exit(fn -> Process.exit(tables, :normal) end)
    %{tables: tables}
  end

  # ============================================================================
  # client api

  test "start dynamic viewport" do
    {:ok, dyn_sup} = DynamicSupervisor.start_link(strategy: :one_for_one, name: @viewports)

    {:ok, vp_pid} = ViewPort.start(@config)
    Process.sleep(100)

    # get the launched supervisor
    [{:undefined, vp_sup, :supervisor, [ViewPort.Supervisor]}] =
      DynamicSupervisor.which_children(dyn_sup)

    # get the scene supervisor children
    # note that the match is pinned via ^vp_pid
    [
      {DynamicSupervisor, scenes_sup, :supervisor, [DynamicSupervisor]},
      {ViewPort.Driver.Supervisor, driver_sup, :supervisor, [ViewPort.Driver.Supervisor]},
      {_, ^vp_pid, :worker, [ViewPort]}
    ] = Supervisor.which_children(vp_sup)

    # confirm the dynamic scene was started
    [{:undefined, _, :supervisor, [Scene.Supervisor]}] =
      DynamicSupervisor.which_children(scenes_sup)

    # confirm the driver supervisor was started
    [{_, _, :worker, [ViewPort.Driver]}] = Supervisor.which_children(driver_sup)

    # cleanup
    DynamicSupervisor.stop(dyn_sup, :normal)
  end

  test "start rejects invalid config" do
    {:ok, dyn_sup} = DynamicSupervisor.start_link(strategy: :one_for_one, name: @viewports)

    assert_raise MatchError, fn ->
      ViewPort.start( %{@config | name: "invalid"} )
    end

    # cleanup
    DynamicSupervisor.stop(dyn_sup, :normal)
  end

  test "stop dynamic viewport" do
    {:ok, dyn_sup} = DynamicSupervisor.start_link(strategy: :one_for_one, name: @viewports)
    {:ok, vp_pid} = ViewPort.start(@config)
    # make sure it started
    [{:undefined, _, :supervisor, [ViewPort.Supervisor]}] =
      DynamicSupervisor.which_children(dyn_sup)

    # stop the ViewPort
    ViewPort.stop(vp_pid)

    # make sure it stopped
    assert DynamicSupervisor.which_children(dyn_sup) == []

    # cleanup
    DynamicSupervisor.stop(dyn_sup, :normal)
  end

  test "info calls back into the viewport"

  test "set_root casts named scene into the viewport"
  test "set_root casts dynamic scene into the viewport"

  test "request root casts request root for self"
  test "request root casts request root for other"
end
