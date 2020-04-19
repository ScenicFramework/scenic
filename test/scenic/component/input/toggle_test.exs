#
#  Created by Eric Watson on 2018-09-18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.Input.ToggleTest do
  use ExUnit.Case, async: false
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Component.Input.Toggle

  @state %Toggle.State{
    graph: Graph.build(),
    theme: Primitive.Style.Theme.preset(:primary),
    pressed?: false,
    contained?: false,
    on?: false,
    id: :test_id
  }

  # ============================================================================
  # info

  test "info works" do
    assert is_bitstring(Toggle.info(:bad_data))
    assert Toggle.info(:bad_data) =~ ":bad_data"
  end

  # ============================================================================
  # verify

  test "verify passes valid data" do
    assert Toggle.verify(true) == {:ok, true}
    assert Toggle.verify(false) == {:ok, false}
  end

  test "verify fails invalid data" do
    assert Toggle.verify(:banana) == :invalid_data
  end

  # ============================================================================
  # init

  test "init works with simple data" do
    {:ok, state, push: graph} = Toggle.init(false, styles: %{}, id: :test_id)
    %Graph{} = state.graph
    assert is_map(state.theme)
    assert state.contained? == false
    assert state.pressed? == false
    assert state.on? == false
    assert state.id == :test_id
    assert state.graph == graph

    {:ok, state, push: graph} = Toggle.init(true, styles: %{}, id: :test_id)
    assert state.on? == true
    assert state.graph == graph
  end

  # ============================================================================
  # handle_input

  test "handle_input {:cursor_enter, _uid} sets contained" do
    {:noreply, state, push: graph} =
      Toggle.handle_input({:cursor_enter, 1}, %{}, %{@state | pressed?: true})

    assert state.contained?
    assert state.graph == graph
  end

  test "handle_input {:cursor_exit, _uid} clears contained" do
    {:noreply, state, push: graph} =
      Toggle.handle_input({:cursor_exit, 1}, %{}, %{@state | pressed?: true})

    refute state.contained?
    assert state.graph == graph
  end

  test "handle_input {:cursor_button, :press" do
    context = %ViewPort.Context{viewport: self()}

    {:noreply, state, push: graph} =
      Toggle.handle_input({:cursor_button, {:left, :press, nil, nil}}, context, %{
        @state
        | pressed?: false,
          contained?: true
      })

    assert state.pressed?
    refute state.on?

    # confirm the input was captured
    assert_receive({:"$gen_cast", {:capture_input, ^context, [:cursor_button, :cursor_pos]}})
    assert state.graph == graph
  end

  test "handle_input {:cursor_button, :release when off" do
    context = %ViewPort.Context{viewport: self()}

    {:noreply, state, push: graph} =
      Toggle.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | pressed?: true,
          contained?: true
      })

    refute state.pressed?
    assert state.on?

    # confirm the input was released
    assert_receive({:"$gen_cast", {:release_input, [:cursor_button, :cursor_pos]}})
    assert state.graph == graph
  end

  test "handle_input {:cursor_button, :release when on" do
    context = %ViewPort.Context{viewport: self()}

    {:noreply, state, push: graph} =
      Toggle.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | on?: true,
          pressed?: true,
          contained?: true
      })

    refute state.pressed?
    refute state.on?

    # confirm the input was released
    assert_receive({:"$gen_cast", {:release_input, [:cursor_button, :cursor_pos]}})
    assert state.graph == graph
  end

  test "handle_input {:cursor_button, :release sends a message if contained" do
    self = self()
    Process.put(:parent_pid, self)
    context = %ViewPort.Context{viewport: self()}

    {:noreply, state, push: graph} =
      Toggle.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | pressed?: true,
          contained?: true
      })

    assert state.graph == graph

    # confirm the event was sent
    assert_receive({:"$gen_cast", {:event, {:value_changed, :test_id, true}, ^self}})
  end

  test "handle_input does nothing on unknown input" do
    context = %ViewPort.Context{viewport: self()}
    {:noreply, state} = Toggle.handle_input(:unknown, context, @state)
    assert state == @state
  end
end
