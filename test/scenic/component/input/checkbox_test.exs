#
#  Created by Boyd Multerer on 2018-11-18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.Input.CheckboxTest do
  use ExUnit.Case, async: false
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Component.Input.Checkbox

  @state %{
    graph: Graph.build(),
    theme: Primitive.Style.Theme.preset(:primary),
    pressed: false,
    contained: false,
    checked: false,
    id: :test_id
  }

  # ============================================================================
  # info

  test "info works" do
    assert is_bitstring(Checkbox.info(:bad_data))
    assert Checkbox.info(:bad_data) =~ ":bad_data"
  end

  # ============================================================================
  # verify

  test "verify passes valid data" do
    assert Checkbox.verify({"Title", true}) == {:ok, {"Title", true}}
    assert Checkbox.verify({"Title", false}) == {:ok, {"Title", false}}
  end

  test "verify fails invalid data" do
    assert Checkbox.verify(:banana) == :invalid_data
  end

  # ============================================================================
  # init

  test "init works with simple data" do
    {:ok, state, push: graph} = Checkbox.init({"Title", false}, styles: %{}, id: :test_id)
    %Graph{} = state.graph
    assert graph == state.graph
    assert is_map(state.theme)
    assert state.contained == false
    assert state.pressed == false
    assert state.checked == false
    assert state.id == :test_id

    {:ok, state, push: graph} = Checkbox.init({"Title", true}, styles: %{}, id: :test_id)
    assert state.checked == true
    assert graph == state.graph
  end

  # ============================================================================
  # handle_input

  test "handle_input {:cursor_enter, _uid} sets contained" do
    {:noreply, state, push: graph} =
      Checkbox.handle_input({:cursor_enter, 1}, %{}, %{@state | pressed: true})

    assert state.contained
    assert graph == state.graph
  end

  test "handle_input {:cursor_exit, _uid} clears contained" do
    {:noreply, state, push: graph} =
      Checkbox.handle_input({:cursor_exit, 1}, %{}, %{@state | pressed: true})

    refute state.contained
    assert graph == state.graph
  end

  test "handle_input {:cursor_button, :press" do
    context = %ViewPort.Context{viewport: self()}

    {:noreply, state, push: graph} =
      Checkbox.handle_input({:cursor_button, {:left, :press, nil, nil}}, context, %{
        @state
        | pressed: false,
          contained: true
      })

    assert state.pressed

    # confirm the input was captured
    assert_receive({:"$gen_cast", {:capture_input, ^context, [:cursor_button, :cursor_pos]}})
    assert graph == state.graph
  end

  test "handle_input {:cursor_button, :release" do
    context = %ViewPort.Context{viewport: self()}

    {:noreply, state, push: graph} =
      Checkbox.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | pressed: true,
          contained: true
      })

    refute state.pressed

    # confirm the input was released
    assert_receive({:"$gen_cast", {:release_input, [:cursor_button, :cursor_pos]}})

    assert graph == state.graph
  end

  test "handle_input {:cursor_button, :release sends a message if contained" do
    self = self()
    Process.put(:parent_pid, self)
    context = %ViewPort.Context{viewport: self()}

    {:noreply, state, push: graph} =
      Checkbox.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | pressed: true,
          contained: true
      })

    assert graph == state.graph
  end

  test "handle_input does nothing on unknown input" do
    context = %ViewPort.Context{viewport: self()}
    {:noreply, state} = Checkbox.handle_input(:unknown, context, @state)
    assert state == @state
  end
end
