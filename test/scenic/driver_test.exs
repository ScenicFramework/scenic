#
#  Created by Boyd Multerer 1/9/2021.
#  Copyright 2021 Kry10 Limited
#

defmodule Scenic.DriverTest do
  use ExUnit.Case, async: false
  doctest Scenic.Driver

  alias Scenic.Driver
  alias Scenic.ViewPort

  @codepoint_input_k {:codepoint, {"k", []}}
  @codepoint_input_l {:codepoint, {"l", []}}
  @cursor_pos_input {:cursor_pos, {10.0, 20.0}}
  @cursor_pos_input_1 {:cursor_pos, {11.0, 21.0}}

  @input_limiter :_input_limiter_expired_

  @put_scripts ViewPort.msg_put_scripts()
  @request_input ViewPort.msg_request_input()
  @del_scripts ViewPort.msg_del_scripts()
  @reset_scene ViewPort.msg_reset_scene()
  @gate_start ViewPort.msg_gate_start()
  @gate_complete ViewPort.msg_gate_complete()

  defmodule TestScene do
    use Scenic.Scene

    def init(scene, pid, _) do
      graph =
        Scenic.Graph.build()
        |> Scenic.Primitives.circle(100, fill: :red, id: :circ, input: :cursor_button)

      scene =
        scene
        |> assign(pid: pid)
        |> push_graph(graph)

      Process.send(pid, {:scene_up, self()}, [])
      {:ok, scene}
    end
  end

  defmodule TestDriver do
    use Scenic.Driver

    def validate_opts(opts), do: {:ok, opts}

    def init(driver, opts) do
      send(self(), {:init, opts})
      {:ok, driver}
    end

    def handle_continue(msg, %Driver{} = driver) do
      send(self(), {:handle_continue, msg})
      {:noreply, driver}
    end

    def handle_info(msg, %Driver{} = driver) do
      send(self(), {:handle_info, msg})
      {:noreply, driver}
    end

    def handle_cast(msg, %Driver{} = driver) do
      send(self(), {:handle_cast, msg})
      {:noreply, driver}
    end

    def handle_call(msg, _, %Driver{} = driver) do
      send(self(), {:handle_call, msg})
      {:reply, :ok, driver}
    end

    def update_scene(ids, driver) do
      send(self(), {:update_scene, ids})
      {:ok, driver}
    end

    def del_scripts(ids, driver) do
      send(self(), {:del_scripts, ids})
      {:ok, driver}
    end

    def request_input(input, driver) do
      send(self(), {:request_input, input})
      {:ok, driver}
    end

    def reset_scene(driver) do
      send(self(), :reset_scene)
      {:ok, driver}
    end

    def clear_color(color, driver) do
      send(self(), {:clear_color, color})
      {:ok, driver}
    end
  end

  # setup do
  #   # start the viewport with a scene. no driver yet
  #   out = Scenic.Test.ViewPort.start({TestScene, self()})

  #   # wait for a signal that the scene is up before proceeding
  #   scene_pid = receive do
  #     {:scene_up, pid} -> pid
  #   end

  #   # add the driver
  #   {:ok, vp} = Map.fetch(out, :vp)
  #   driver_config = [ module: TestDriver, pid: self() ]
  #   {:ok, driver_pid} = ViewPort.start_driver(vp, driver_config)

  #   # wait for a signal that the driver is up before proceeding
  #   receive do
  #     :driver_up -> :ok
  #   end

  #   # needed to give time for the pid and vp to close
  #   on_exit(fn -> Process.sleep(1) end)

  #   out
  #   |> Map.put( :scene, scene_pid )
  #   |> Map.put( :driver, driver_pid )
  # end

  # test "test setup works", setup do
  #   %Scenic.ViewPort{} = setup.vp
  #   assert is_pid( setup.supervisor )
  #   assert is_pid( setup.scene )
  #   assert is_pid( setup.driver )
  # end

  # ============================================================================
  # client access APIs

  test "get works" do
    driver = %Driver{assigns: %{abc: 123}}
    assert Driver.get(driver, :abc) == 123
  end

  test "get returns nil for missing values" do
    driver = %Driver{assigns: %{abc: 123}}
    assert Driver.get(driver, :def) == nil
  end

  test "get returns supplied default for missing values" do
    driver = %Driver{assigns: %{abc: 123}}
    assert Driver.get(driver, :def, 456) == 456
  end

  test "fetch works" do
    driver = %Driver{assigns: %{abc: 123}}
    assert Driver.fetch(driver, :abc) == {:ok, 123}
  end

  test "fetch returns :error for missing values" do
    driver = %Driver{assigns: %{abc: 123}}
    assert Driver.fetch(driver, :def) == :error
  end

  test "assign assigns single value" do
    driver =
      %Driver{}
      |> Driver.assign(:abc, 123)

    assert Driver.fetch(driver, :abc) == {:ok, 123}
  end

  test "assign assigns list of values" do
    driver =
      %Driver{}
      |> Driver.assign(abc: 123, def: 456)

    assert Driver.fetch(driver, :abc) == {:ok, 123}
    assert Driver.fetch(driver, :def) == {:ok, 456}
  end

  test "assign_new assigns single value" do
    driver =
      %Driver{}
      |> Driver.assign_new(:abc, 123)

    assert Driver.fetch(driver, :abc) == {:ok, 123}
  end

  test "assign_new assigns list of values" do
    driver =
      %Driver{}
      |> Driver.assign_new(abc: 123, def: 456)

    assert Driver.fetch(driver, :abc) == {:ok, 123}
    assert Driver.fetch(driver, :def) == {:ok, 456}
  end

  test "assign_new ignores existing values" do
    driver =
      %Driver{assigns: %{abc: 123}}
      |> Driver.assign_new(abc: 789, def: 456)

    assert Driver.fetch(driver, :abc) == {:ok, 123}
    assert Driver.fetch(driver, :def) == {:ok, 456}
  end

  test "set_busy sets the busy flag" do
    driver = %Driver{}
    assert Map.get(driver, :busy) == false

    driver = Driver.set_busy(driver, true)
    assert Map.get(driver, :busy) == true
  end

  # ============================================================================
  # sending input

  test "send_input sends inputs right away if limit_ms is 0" do
    driver = %Driver{
      viewport: %ViewPort{pid: self()},
      limit_ms: 0,
      requested_inputs: [:cursor_pos]
    }

    assert Map.get(driver, :input_limited) == false
    assert Map.get(driver, :input_buffer) == %{}

    driver = Driver.send_input(driver, @cursor_pos_input)
    assert_receive({:"$gen_cast", {:input, {:cursor_pos, {10.0, 20.0}}}}, 200)
    assert Map.get(driver, :input_limited) == false
    assert Map.get(driver, :input_buffer) == %{}
  end

  test "send_input triggers limit if limit_ms is set" do
    driver = %Driver{
      viewport: %ViewPort{pid: self()},
      limit_ms: 1,
      requested_inputs: [:cursor_pos]
    }

    assert Map.get(driver, :input_limited) == false
    assert Map.get(driver, :input_buffer) == %{}

    driver = Driver.send_input(driver, @cursor_pos_input)
    driver = Driver.send_input(driver, @cursor_pos_input_1)
    assert_receive({:"$gen_cast", {:input, @cursor_pos_input}}, 200)
    assert Map.get(driver, :input_limited) == true
    assert Map.get(driver, :input_buffer) == %{cursor_pos: @cursor_pos_input_1}
    assert_receive(@input_limiter, 200)
  end

  test "send_input sets queued input if already limited" do
    driver = %Driver{
      input_limited: true,
      input_buffer: %{},
      requested_inputs: [:cursor_pos],
      limit_ms: 1
    }

    driver = Driver.send_input(driver, @cursor_pos_input)
    assert Map.get(driver, :input_limited)
    assert Map.get(driver, :input_buffer) == %{cursor_pos: @cursor_pos_input}

    driver = Driver.send_input(driver, @cursor_pos_input_1)
    assert Map.get(driver, :input_limited)
    assert Map.get(driver, :input_buffer) == %{cursor_pos: @cursor_pos_input_1}

    refute_receive({:"$gen_cast", {:input, _}}, 10)
  end

  test "send_input does not trigger limit for non-positional input" do
    driver = %Driver{
      viewport: %ViewPort{pid: self()},
      limit_ms: 1,
      requested_inputs: [:codepoint]
    }

    assert Map.get(driver, :input_limited) == false
    assert Map.get(driver, :input_buffer) == %{}

    driver = Driver.send_input(driver, @codepoint_input_k)
    driver = Driver.send_input(driver, @codepoint_input_l)
    assert_receive({:"$gen_cast", {:input, @codepoint_input_k}}, 200)
    assert_receive({:"$gen_cast", {:input, @codepoint_input_l}}, 200)
    assert Map.get(driver, :input_limited) == false
    assert Map.get(driver, :input_buffer) == %{}
  end

  test "send_input ignores inputs that aren't requested" do
    driver = %Driver{
      viewport: %ViewPort{pid: self()},
      limit_ms: 0,
      requested_inputs: []
    }

    assert Map.get(driver, :input_limited) == false
    assert Map.get(driver, :input_buffer) == %{}

    driver = Driver.send_input(driver, @cursor_pos_input)
    refute_receive({:"$gen_cast", {:input, _}}, 10)
    assert Map.get(driver, :input_limited) == false
    assert Map.get(driver, :input_buffer) == %{}

    driver = Driver.send_input(driver, @codepoint_input_k)
    refute_receive({:"$gen_cast", {:input, _}}, 10)
    assert Map.get(driver, :input_limited) == false
    assert Map.get(driver, :input_buffer) == %{}
  end

  # ============================================================================
  # Viewport Driver management

  test "can start and stop the driver via the api" do
    %{vp: vp} = Scenic.Test.ViewPort.start({TestScene, self()})

    # start the driver
    {:ok, driver} = ViewPort.start_driver(vp, module: TestDriver, pid: self())
    assert Process.alive?(driver)

    # stop the driver
    :ok = ViewPort.stop_driver(vp, driver)
    refute Process.alive?(driver)
  end

  # ============================================================================
  # handlers / callbacks

  test "handle_continue passes through" do
    driver = %Driver{module: TestDriver}
    assert Driver.handle_continue(:test_msg, driver) == {:noreply, driver}
    assert_receive({:handle_continue, :test_msg}, 200)
  end

  test "handle_info passes through" do
    driver = %Driver{module: TestDriver}
    assert Driver.handle_info(:test_msg, driver) == {:noreply, driver}
    assert_receive({:handle_info, :test_msg}, 200)
  end

  test "handle_cast passes through" do
    driver = %Driver{module: TestDriver}
    assert Driver.handle_cast(:test_msg, driver) == {:noreply, driver}
    assert_receive({:handle_cast, :test_msg}, 200)
  end

  test "handle_call passes through" do
    driver = %Driver{module: TestDriver}
    assert Driver.handle_call(:test_msg, 123, driver) == {:reply, :ok, driver}
    assert_receive({:handle_call, :test_msg}, 200)
  end

  test "put_scripts buffers and requests an update" do
    driver = %Driver{module: TestDriver, pid: self()}
    msg = {@put_scripts, [1, 2, 3]}
    {:noreply, driver} = Driver.handle_info(msg, driver)
    assert driver.dirty_ids == [[1, 2, 3]]
    assert_receive(:_do_update_, 200)
  end

  test "if limit_ms is 0, buffers and requests right away" do
    driver = %Driver{module: TestDriver, pid: self(), limit_ms: 0}
    {:noreply, driver} = Driver.handle_info({@put_scripts, [1, 2, 3]}, driver)
    {:noreply, driver} = Driver.handle_info({@put_scripts, [2, 3, 4]}, driver)
    {:noreply, driver} = Driver.handle_info({@put_scripts, [3, 5]}, driver)
    assert driver.update_requested == true
    assert driver.dirty_ids == [[3, 5], [2, 3, 4], [1, 2, 3]]
    assert_receive(:_do_update_, 200)
    refute_receive(:_do_update_, 10)
  end

  test "del_scripts works" do
    driver = %Driver{module: TestDriver}
    msg = {@del_scripts, [1, 2, 3]}
    assert Driver.handle_info(msg, driver) == {:noreply, driver}
    assert_receive({:del_scripts, [1, 2, 3]}, 200)
  end

  test "request_input works" do
    driver = %Driver{module: TestDriver}
    msg = {@request_input, [1, 2, 3]}
    {:noreply, driver} = Driver.handle_info(msg, driver)
    assert driver.requested_inputs == [1, 2, 3]
    assert_receive({:request_input, [1, 2, 3]}, 200)
  end

  test "reset_scene works" do
    driver = %Driver{module: TestDriver, dirty_ids: [1, 2, 3]}
    {:noreply, driver} = Driver.handle_info(@reset_scene, driver)
    assert driver.dirty_ids == ["_root_"]
    assert_receive(:reset_scene, 200)
  end

  test "marking the driver busy queues scripts" do
    driver = %Driver{module: TestDriver, limit_ms: 0, busy: true, pid: self()}
    {:noreply, driver} = Driver.handle_info({@put_scripts, [1, 2, 3]}, driver)
    {:noreply, driver} = Driver.handle_info({@put_scripts, [2, 3, 4]}, driver)
    {:noreply, driver} = Driver.handle_info({@put_scripts, [3, 5]}, driver)
    assert driver.dirty_ids == [[3, 5], [2, 3, 4], [1, 2, 3]]
    refute_receive({:put_scripts, _}, 10)
  end

  test "marking the driver gated queues scripts" do
    driver = %Driver{module: TestDriver, limit_ms: 0, gated: true, pid: self()}
    {:noreply, driver} = Driver.handle_info({@put_scripts, [1, 2, 3]}, driver)
    {:noreply, driver} = Driver.handle_info({@put_scripts, [2, 3, 4]}, driver)
    {:noreply, driver} = Driver.handle_info({@put_scripts, [3, 5]}, driver)
    assert driver.dirty_ids == [[3, 5], [2, 3, 4], [1, 2, 3]]
    refute_receive({:put_scripts, _}, 10)
  end

  test "the gate_start signal sets gated" do
    driver = %Driver{gated: false}
    {:noreply, driver} = Driver.handle_info(@gate_start, driver)
    assert driver.gated == true
  end

  test "the gate_complete signal clears gated" do
    driver = %Driver{gated: true}
    {:noreply, driver} = Driver.handle_info(@gate_complete, driver)
    assert driver.gated == false
  end

  test "the input_limiter signal sends buffered input and limits again" do
    driver = %Driver{
      module: TestDriver,
      limit_ms: 1,
      input_limited: true,
      viewport: %ViewPort{pid: self()},
      input_buffer: %{cursor_pos: @cursor_pos_input}
    }

    {:noreply, driver} = Driver.handle_info(@input_limiter, driver)
    assert Map.get(driver, :input_limited) == true
    assert Map.get(driver, :input_buffer) == %{}
    assert_receive({:"$gen_cast", {:input, @cursor_pos_input}}, 200)
    assert_receive(@input_limiter, 200)
  end

  test "the input_limiter resets if no buffered input" do
    driver = %Driver{
      module: TestDriver,
      limit_ms: 1,
      input_limited: true,
      viewport: %ViewPort{pid: self()},
      input_buffer: %{}
    }

    {:noreply, driver} = Driver.handle_info(@input_limiter, driver)
    assert Map.get(driver, :input_limited) == false
    assert Map.get(driver, :input_buffer) == %{}
    refute_receive(@input_limiter, 10)
  end
end
