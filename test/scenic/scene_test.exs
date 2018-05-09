#
#  re-re-Created by Boyd Multerer on May 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
#

defmodule Scenic.SceneTest do
  use ExUnit.Case, async: false
  doctest Scenic
  alias Scenic.Scene

  #  import IEx

  @not_activated        :__not_activated__

  #============================================================================
  # faux scene module callbacks...

  def init( opts ) do
    assert opts == [1,2,3]
    {:ok, :init_state}
  end

  def handle_info( msg, state ) do
    GenServer.cast(self(), {:test_handle_info, msg, state})
    {:noreply, :handle_info_state}
  end

  def handle_set_root( vp, args, state ) do
    GenServer.cast(self(), {:test_set_root, vp, args, state})
    {:noreply, :set_root_state}
  end

  def handle_lose_root( vp, state ) do
    GenServer.cast(self(), {:test_lose_root, vp, state})
    {:noreply, :lose_root_state}
  end

  def handle_call( msg, from, state ) do
    GenServer.cast(self(), {:test_handle_call, msg, from, state})
    {:reply, :handle_call_reply, :handle_call_state}
  end

  def handle_input(event, context, state ) do
    GenServer.cast(self(), {:test_input, event, context, state})
    {:noreply, :input_state}
  end

  def handle_cast( msg, state ) do
    GenServer.cast(self(), {:test_handle_cast, msg, state})
    {:noreply, :handle_cast_state}
  end

  #============================================================================
  # child_spec
  # need a custom child_spec because there can easily be multiple scenes running at the same time
  # they are all really Scenic.Scene as the GenServer module, so need to use differnt ids

  test "child_spec uses the scene module and id - no args" do
    %{
      id:       id,
      start:    {Scene, :start_link, [__MODULE__, :args, []]},
      type:     :worker,
      restart:  :permanent,
      shutdown: 500
    } = Scene.child_spec({__MODULE__, :args, []})
    assert is_reference(id)
  end

  #============================================================================
  test "init stores the scene name in the process dictionary" do
    ref = make_ref()
    Scene.init( {__MODULE__, [1,2,3], [scene_ref: ref]} )
    # verify the process dictionary
    assert Process.get(:scene_ref) == ref
  end

  test "init stores the scene reference in the process dictionary" do
    Scene.init( {__MODULE__, [1,2,3], [name: :scene_name]} )
    # verify the process dictionary
    assert Process.get(:scene_ref) == :scene_name
  end

  test "init sends root_up message if vp_dynamic_root is set" do
    self = self()
    Scene.init( {__MODULE__, [1,2,3], [name: :scene_name, vp_dynamic_root: self]} )
    # verify the message
    assert_receive( {:"$gen_cast", {:dyn_root_up, :scene_name, ^self}} )
  end

  test "init does not send root_up message if vp_dynamic_root is clear" do
    Scene.init( {__MODULE__, [1,2,3], [name: :scene_name]} )
    # verify the message
    refute_receive( {:"$gen_cast", {:dyn_root_up, _, _}} )
  end

  test "init stores parent_pid in the process dictionary if set" do
    ref = make_ref()
    Scene.init( {__MODULE__, [1,2,3], [scene_ref: ref, parent: self()]} )
    # verify the process dictionary
    assert Process.get(:parent_pid) == self()
  end

  test "init stores nothing in the process dictionary if parent clear" do
    ref = make_ref()
    Scene.init( {__MODULE__, [1,2,3], [scene_ref: ref]} )
    # verify the process dictionary
    assert Process.get(:parent_pid) == nil
  end

  test "init sends self :after_init" do
    Scene.init( {__MODULE__, [1,2,3], [name: :scene_name]} )
    assert_receive( {:"$gen_cast", :after_init} )
  end
  test "init call mod.init and returns first round of state" do
    self = self()
    {:ok, %{
      raw_scene_refs: %{},      
      dyn_scene_pids: %{},
      dyn_scene_keys: %{},

      parent_pid: ^self,
      children: %{},

      scene_module: __MODULE__,

      scene_state: :init_state,
      scene_ref: :scene_name,
      supervisor_pid: nil,
      dynamic_children_pid: nil,
      activation: @not_activated
    }} = Scene.init( {__MODULE__, [1,2,3], [name: :scene_name, parent: self]} )
  end

  #============================================================================
  # handle_info
  
  test "handle_info sends unhandles messages to the module" do
    {:noreply, new_state} = assert Scene.handle_info(:abc, %{
      scene_module: __MODULE__,
      scene_state: :scene_state
    })
    assert new_state.scene_state == :handle_info_state

    assert_receive( {:"$gen_cast",
      {:test_handle_info, :abc, :scene_state}
    } )
  end


  #============================================================================
  # handle_call
  
  test "handle_call :set_root calls set_root on module" do
    vp = self()
    {:reply, resp, new_state} = assert Scene.handle_call(
      {:set_root, :args}, vp, %{
      scene_module: __MODULE__,
      scene_state: :scene_state,
      activation: nil
    })
    assert resp == :ok
    assert new_state.scene_state == :set_root_state
    assert new_state.activation == :args

    assert_receive( {:"$gen_cast",
      {:test_set_root, ^vp, :args, :scene_state}
    } )
  end

  test "handle_call :lose_root sends lose_root to the module" do
    vp = self()

    {:reply, resp, new_state} = assert Scene.handle_call(
      :lose_root, vp, %{
      scene_module: __MODULE__,
      scene_state: :scene_state,
      activation: :args
    })
    assert resp == :ok
    assert new_state.scene_state == :lose_root_state
    assert new_state.activation == @not_activated

    assert_receive( {:"$gen_cast",
      {:test_lose_root, ^vp, :scene_state}
    } )
  end

  test "handle_call sends unhandled messages to mod" do
    self = self()
    {:reply, resp, new_state} = assert Scene.handle_call(
      :other, self, %{
      scene_module: __MODULE__,
      scene_state: :scene_state,
    })
    assert resp == :handle_call_reply
    assert new_state.scene_state == :handle_call_state

    assert_receive( {:"$gen_cast",
      {:test_handle_call, :other, ^self, :scene_state}
    } )
  end

  #============================================================================
  # handle_cast

  test "handle_cast :set_root calls the mod set root handler" do
    vp = self()
    {:noreply, new_state} = assert Scene.handle_cast(
      {:set_root, :args, vp}, %{
      scene_module: __MODULE__,
      scene_state: :scene_state,
      activation: nil
    })
    assert new_state.scene_state == :set_root_state
    assert new_state.activation == :args

    assert_receive( {:"$gen_cast",
      {:test_set_root, ^vp, :args, :scene_state}
    } )
  end

  test "handle_cast :input calls the mod input handler" do
    context = %Scenic.ViewPort.Input.Context{
      viewport: self()
    }
    event = {:cursor_enter, 1}
    sc_state = :sc_state

    {:noreply, new_state} = assert Scene.handle_cast(
      {:input, event, context}, %{
      scene_module: __MODULE__,
      scene_state: sc_state,
      activation: nil
    })

    assert new_state.scene_state == :input_state
    assert_receive( {:"$gen_cast", {:test_input, ^event, ^context, ^sc_state}} )
  end

  test "handle_cast unknown calls the mod input handler" do
    {:noreply, new_state} = assert Scene.handle_cast(
      :other, %{
      scene_module: __MODULE__,
      scene_state: :scene_state,
      activation: nil
    })
    assert new_state.scene_state == :handle_cast_state
    assert_receive( {:"$gen_cast", {:test_handle_cast, :other, :scene_state}} )
  end

end

















