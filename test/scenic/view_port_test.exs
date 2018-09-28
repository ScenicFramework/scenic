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

  defmodule TestViewPort do
    use GenServer
    def init(_), do: {:ok, :test_driver_state}
    def handle_call( :query_info, _, state ) do
      {:reply, {:ok, :test_info}, state}
    end    
  end

  @driver_config %{
        module: TestDriver,
        name: :test_driver,
        opts: [title: "test title"]
      }

  @config %{
    name: :dyanmic_viewport,
    size: {700, 600},
    opts: [font: :roboto_slab, font_size: 30, scale: 1.0],
    default_scene: {TestSceneOne, nil},
    drivers: [ @driver_config ]
  }

  import IEx

  setup do
    {:ok, tables} = Tables.start_link(nil)
    on_exit(fn -> Process.exit(tables, :normal) end)
    %{tables: tables}
  end

  # ============================================================================
  # internal test callbacks
  def handle_call( :query_info, _, state ) do
    {:reply, {:ok, :test_info}, state}
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

  test "info calls back into the viewport" do
    {:ok, pid} = GenServer.start(TestViewPort, nil)
    {:ok, :test_info} = ViewPort.info( pid )
    Process.exit(pid, :shutdown)
  end

  test "set_root casts named scene into the viewport" do
    ViewPort.set_root( self(), :named_scene_no_args )
    assert_received( {:"$gen_cast", {:set_root, :named_scene_no_args, nil}} )

    ViewPort.set_root( self(), :named_scene_yes_args, 123 )
    assert_received( {:"$gen_cast", {:set_root, :named_scene_yes_args, 123}} )
  end

  test "set_root casts dynamic scene into the viewport" do
    ViewPort.set_root( self(), {TestSceneOne, 456} )
    assert_received( {:"$gen_cast", {:set_root, {TestSceneOne, 456}, nil}} )
    ViewPort.set_root( self(), {TestSceneOne, 456}, 789 )
    assert_received( {:"$gen_cast", {:set_root, {TestSceneOne, 456}, 789}} )
  end

  test "request root casts request root for self" do
    self = self()
    ViewPort.request_root( self )
    assert_received( {:"$gen_cast", {:request_root, ^self}} )
  end

  test "request root casts request root for other" do
    {:ok, agent} = Agent.start(fn -> 1 + 1 end)
    ViewPort.request_root( self(), agent )
    assert_received( {:"$gen_cast", {:request_root, ^agent}} )
    Agent.stop(agent)
  end

  test "reshape casts request to viewport" do
    ViewPort.reshape( self(), {12, 13} )
    assert_received( {:"$gen_cast", {:reshape, {12, 13}}} )
  end

  test "capture_input casts request to viewport" do
    context = %ViewPort.Context{viewport: self()}
    ViewPort.capture_input( context, :key )
    assert_received( {:"$gen_cast", {:capture_input, ^context, [:key]}} )
    
    ViewPort.capture_input( context, [:key, :codepoint] )
    assert_received( {:"$gen_cast", {:capture_input, ^context, [:key, :codepoint]}} )
  end

  test "driver_cast casts request to viewport" do
    ViewPort.driver_cast( self(), :msg )
    assert_received( {:"$gen_cast", {:driver_cast, :msg}} )
  end

  # ============================================================================
  # internal startup

  test "child_spec works" do
    spec = ViewPort.child_spec(:args)
    assert is_reference( spec.id )
    assert spec.start == {ViewPort, :start_link, [:args]}
  end

  test "start_link works with no name" do
    {:ok, pid} = ViewPort.start_link({:vp_sup, %{@config | name: nil}})
    assert is_pid(pid)
    Process.exit(pid, :shutdown)
  end

  test "start_link works with name" do
    {:ok, pid} = ViewPort.start_link({:vp_sup, @config})
    assert is_pid(pid)
    assert Process.whereis(:dyanmic_viewport) == pid
    Process.exit(pid, :shutdown)
  end

  test "init casts to self with :delayed_init" do
    ViewPort.init( {:vp_sup, :config} )
    assert_received( {:"$gen_cast", {:delayed_init, :vp_sup, :config}} )
  end

  # ============================================================================
  # handle_call

  test "handle_call :start_driver" do
    {:ok, dyn_sup} = DynamicSupervisor.start_link(strategy: :one_for_one, name: @viewports)

    {:ok, vp_pid} = ViewPort.start(%{@config | drivers: []})
    Process.sleep(100)

    # Call it the proper way
    {:ok, driver_pid} = GenServer.call(vp_pid, {:start_driver, @driver_config})
    assert is_pid(driver_pid)

    # cleanup
    DynamicSupervisor.stop(dyn_sup, :normal)
  end

  test "handle_call :query_info" do
    {:reply, {:ok, info}, _} = ViewPort.handle_call(
      :query_info,
      :from,
      %{
          driver_registry: :driver_registry,
          root_config: :root_config,
          root_scene_pid: :root_scene_pid,
          root_graph_key: :root_graph_key,
          size: :size
        })
    assert info.drivers == :driver_registry
    assert info.root_graph == :root_graph_key
    assert info.root_scene_pid == :root_scene_pid
    assert info.root_config == :root_config
    assert info.size == :size
  end

  # ============================================================================
  # handle_cast

  test "handle_cast :delated_init"

  test "handle_cast :set_root"

  test "handle_cast :dyn_root_up" do
    ref = make_ref()
    {:noreply, state} = ViewPort.handle_cast(
      { :dyn_root_up, ref, self() },
      %{
        root_graph_key: {:graph, ref, nil},
        root_scene_pid: nil,
        dynamic_root_pid: nil
      }
    )
    assert state.root_scene_pid == self()
    assert state.dynamic_root_pid == self()
  end

  test "handle_cast :dyn_root_up ignores stale messages" do
    assert ViewPort.handle_cast({:dyn_root_up,nil,nil}, :state) == 
      {:noreply, :state}
  end

  test "handle_cast :stop_driver stops a dynamic driver" do
    # setup
    {:ok, dyn_sup} = DynamicSupervisor.start_link(strategy: :one_for_one, name: @viewports)
    {:ok, driver_pid} = DynamicSupervisor.start_child(dyn_sup, {Scenic.ViewPort.Driver, {self(), {1,2}, @driver_config}} )

    # the call
    {:noreply, state} = ViewPort.handle_cast(
      {:stop_driver, driver_pid},
      %{
        drivers: [driver_pid],
        driver_registry: %{driver_pid => 1},
        dynamic_supervisor: dyn_sup
      }
    )
    refute Enum.member?(state.drivers, driver_pid)
    refute Map.get(state.driver_registry, driver_pid)
    assert DynamicSupervisor.which_children(dyn_sup) == []

    #cleanup
    DynamicSupervisor.stop(dyn_sup, :normal)
  end

  test "handle_cast :driver_cast"

  test "handle_cast :driver_ready" do
    {:noreply, state} = ViewPort.handle_cast(
      {:driver_ready, self()},
      %{
        drivers: [],
        master_graph_key: :master_graph_key
      }
    )
    assert state.drivers == [self()]
    assert_received( {:"$gen_cast", {:set_root, :master_graph_key}} )
  end

  test "handle_cast :request_root" do
    {:noreply, _} = ViewPort.handle_cast(
      {:request_root, self()},
      %{ master_graph_key: :master_graph_key }
    )
    assert_received( {:"$gen_cast", {:set_root, :master_graph_key}} )
  end

  test "handle_cast :driver_register" do
    info = %ViewPort.Driver.Info{pid: self()}
    {:noreply, state} = ViewPort.handle_cast(
      {:driver_register, info},
      %{ driver_registry: %{} }
    )
    assert state.driver_registry[self()] == info
  end

  test "handle_cast :user_close"
  # take a look at the architecture. Maybe add a handle_close
  # callback with a default that just shuts it down. This allows
  # the viewport to cancel or cleanup or whatever


end





































