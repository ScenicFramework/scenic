#
#  Created by Boyd Multerer on 2018-11-18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.Input.DropdownTest do
  use ExUnit.Case, async: false
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Component.Input.Dropdown

  @items [{"a", 1}, {"b", 2}]
  @initial_item 2
  @data {@items, @initial_item}

  @state %{
    graph: Graph.build(),
    selected_id: @initial_item,
    theme: Primitive.Style.Theme.preset(:primary),
    id: :test_id,
    down: false,
    hover_id: nil,
    items: @items,
    drop_time: 0,
    rotate_caret: 0
  }

  @button_id :__dropbox_btn__

  # ============================================================================
  # info

  test "info works" do
    assert is_bitstring(Dropdown.info(:bad_data))
    assert Dropdown.info(:bad_data) =~ ":bad_data"
  end

  # ============================================================================
  # verify

  test "verify passes valid data" do
    assert Dropdown.verify(@data) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Dropdown.verify(:banana) == :invalid_data

    # invalid item in list
    data = {[{:a, 1}, {"b", 2}], 2}
    assert Dropdown.verify(data) == :invalid_data

    # selected is not in list
    data = {[{"a", 1}, {"b", 2}], 3}
    assert Dropdown.verify(data) == :invalid_data
  end

  # ============================================================================
  # init

  test "init works with simple data" do
    {:ok, state, push: graph} = Dropdown.init(@data, styles: %{}, id: :test_id)
    %Graph{} = state.graph
    assert state.graph == graph
    assert state.selected_id == @initial_item
    assert is_map(state.theme)
    assert state.down == false
    assert state.hover_id == nil
    assert state.items == @items
    assert state.id == :test_id
  end

  # ============================================================================
  # handle_input - up

  test "handle_input {:cursor_enter, _uid} - up" do
    {:noreply, state} =
      Dropdown.handle_input({:cursor_enter, 1}, %{id: 123}, %{@state | down: false})

    assert state.hover_id == 123
  end

  test "handle_input {:cursor_exit, _uid} - up" do
    {:noreply, state} =
      Dropdown.handle_input({:cursor_exit, 1}, %{id: 123}, %{@state | down: false})

    assert state.hover_id == nil
  end

  test "handle_input {:cursor_button, :press - up" do
    context = %ViewPort.Context{viewport: self(), id: @button_id}

    {:noreply, state, push: graph} =
      Dropdown.handle_input({:cursor_button, {:left, :press, nil, nil}}, context, %{
        @state
        | down: false
      })

    assert state.down == true
    assert is_integer(state.drop_time) && state.drop_time > 0

    # confirm the input was captured
    assert_receive({:"$gen_cast", {:capture_input, ^context, [:cursor_button, :cursor_pos]}})

    assert state.graph == graph
  end

  # ============================================================================
  # handle_input - down

  test "handle_input {:cursor_enter, _uid} - down" do
    context = %ViewPort.Context{viewport: self(), id: 1}

    {:noreply, state, push: graph} =
      Dropdown.handle_input({:cursor_enter, 1}, context, %{@state | down: true})

    assert state.hover_id == 1

    assert state.graph == graph
  end

  test "handle_input {:cursor_exit, _uid} - down" do
    context = %ViewPort.Context{viewport: self(), id: 1}

    {:noreply, state, push: graph} =
      Dropdown.handle_input({:cursor_exit, 1}, context, %{@state | down: true})

    assert state.hover_id == nil

    assert state.graph == graph
  end

  # mouse down outside menu
  test "handle_input {:cursor_button, :press nil - down" do
    context = %ViewPort.Context{viewport: self(), id: nil}

    {:noreply, state, push: graph} =
      Dropdown.handle_input({:cursor_button, {:left, :press, nil, nil}}, context, %{
        @state
        | down: true
      })

    assert state.down == false

    # confirm the input was released
    assert_receive({:"$gen_cast", {:release_input, [:cursor_button, :cursor_pos]}})

    assert state.graph == graph
  end

  # mouse down inside button - slow
  test "handle_input {:cursor_button, :press button - down - slow - should close" do
    context = %ViewPort.Context{viewport: self(), id: @button_id}

    {:noreply, state, push: graph} =
      Dropdown.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | down: true
      })

    assert state.down == false

    # confirm the input was released
    assert_receive({:"$gen_cast", {:release_input, [:cursor_button, :cursor_pos]}})

    assert state.graph == graph
  end

  # mouse down inside button - fast
  test "handle_input {:cursor_button, :press button - down - fast - should stay down" do
    context = %ViewPort.Context{viewport: self(), id: @button_id}

    {:noreply, state} =
      Dropdown.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | down: true,
          drop_time: :os.system_time(:milli_seconds)
      })

    assert state.down == true

    # confirm the input was not released
    refute_receive({:"$gen_cast", {:release_input, [:cursor_button, :cursor_pos]}})
  end

  # mouse released outside dropdown space
  test "handle_input {:cursor_button, :release button - outside menu" do
    context = %ViewPort.Context{viewport: self(), id: nil}

    {:noreply, state, push: graph} =
      Dropdown.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | down: true,
          drop_time: :os.system_time(:milli_seconds)
      })

    assert state.down == false
    assert state.selected_id == @initial_item

    # confirm the input was released
    assert_receive({:"$gen_cast", {:release_input, [:cursor_button, :cursor_pos]}})

    # confirm the value change was not sent
    refute_receive({:"$gen_cast", {:event, {:value_changed, _, _}, _}})

    assert state.graph == graph
  end

  # mouse released inside dropdown space
  test "handle_input {:cursor_button, :release button - inside menu" do
    self = self()
    Process.put(:parent_pid, self)
    context = %ViewPort.Context{viewport: self, id: 1}

    {:noreply, state, push: graph} =
      Dropdown.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | down: true
      })

    assert state.down == false
    assert state.selected_id == 1

    # confirm the input was released
    assert_receive({:"$gen_cast", {:release_input, [:cursor_button, :cursor_pos]}})

    # confirm the value change was not sent
    assert_receive({:"$gen_cast", {:event, {:value_changed, :test_id, 1}, ^self}})

    assert state.graph == graph
  end

  test "handle_input does nothing on unknown input" do
    context = %ViewPort.Context{viewport: self()}
    {:noreply, state} = Dropdown.handle_input(:unknown, context, @state)
    assert state == @state
  end
end
