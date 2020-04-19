#
#  Created by Boyd Multerer on 2018-09-18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.Input.SliderTest do
  use ExUnit.Case, async: false
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Graph
  # alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Component.Input.Slider

  @extents {0, 100}
  @initial_value 2
  @data {@extents, @initial_value}

  @state %{
    graph: Graph.build(),
    value: @initial_value,
    extents: @extents,
    width: 300,
    id: :test_id,
    tracking: false
  }

  # ============================================================================
  # info

  test "info works" do
    assert is_bitstring(Slider.info(:bad_data))
    assert Slider.info(:bad_data) =~ ":bad_data"
  end

  # ============================================================================
  # verify

  test "verify passes valid data" do
    assert Slider.verify({{0, 100}, 10}) == {:ok, {{0, 100}, 10}}
    assert Slider.verify({{0.1, 100.3}, 10.4}) == {:ok, {{0.1, 100.3}, 10.4}}

    assert Slider.verify({[:red, :green, :blue], :green}) ==
             {:ok, {[:red, :green, :blue], :green}}
  end

  test "verify fails invalid data" do
    assert Slider.verify(:banana) == :invalid_data
    assert Slider.verify({{0, 100}, 101}) == :invalid_data
    assert Slider.verify({{0, 100}, -1}) == :invalid_data
    assert Slider.verify({{100, 0}, 10}) == :invalid_data

    assert Slider.verify({{0.1, 100.2}, 101.0}) == :invalid_data
    assert Slider.verify({{0.4, 100.2}, 0.1}) == :invalid_data
    assert Slider.verify({{100.2, 0.4}, 10.1}) == :invalid_data

    # mixed integer and float
    assert Slider.verify({{0, 100.1}, 10}) == :invalid_data
    assert Slider.verify({{0.1, 100}, 10}) == :invalid_data
    assert Slider.verify({{0, 100}, 10.3}) == :invalid_data

    # list where initial is not in list
    assert Slider.verify({[:red, :green, :blue], :yellow}) == :invalid_data
  end

  # ============================================================================
  # init

  test "init works with simple data" do
    {:ok, state, push: graph} = Slider.init(@data, styles: %{}, id: :test_id)
    %Graph{} = state.graph
    assert state.graph == graph
    assert state.value == @initial_value
    assert state.extents == @extents
    assert state.id == :test_id
    assert state.tracking == false
  end

  # ============================================================================
  # handle_input

  test "handle_input {:cursor_button, :press - integer" do
    self = self()
    context = %ViewPort.Context{viewport: self}
    Process.put(:parent_pid, self)

    {:noreply, state, push: graph} =
      Slider.handle_input({:cursor_button, {:left, :press, nil, {103, 0}}}, context, %{
        @state
        | tracking: false
      })

    assert state.tracking
    assert state.value != @state.value

    # confirm the input was captured
    assert_receive({:"$gen_cast", {:capture_input, ^context, [:cursor_button, :cursor_pos]}})
    assert state.graph == graph
  end

  test "handle_input {:cursor_button, :press - float" do
    self = self()
    context = %ViewPort.Context{viewport: self}
    Process.put(:parent_pid, self)

    orig_value = 2.0
    extents = {0.0, 100.0}
    state = %{@state | value: orig_value, extents: extents}

    {:noreply, state, push: graph} =
      Slider.handle_input({:cursor_button, {:left, :press, nil, {103, 0}}}, context, %{
        state
        | tracking: false
      })

    assert state.tracking
    assert state.value != orig_value

    # confirm the input was captured
    assert_receive({:"$gen_cast", {:capture_input, ^context, [:cursor_button, :cursor_pos]}})
    assert state.graph == graph

    # confirm the value change was sent
    assert_receive({:"$gen_cast", {:event, {:value_changed, :test_id, pos}, ^self}})
    assert pos > 34
    assert pos < 35
  end

  test "handle_input {:cursor_button, :press - list" do
    self = self()
    context = %ViewPort.Context{viewport: self}
    Process.put(:parent_pid, self)

    orig_value = :yellow
    extents = [:red, :yellow, :purple, :blue, :orange]
    state = %{@state | value: orig_value, extents: extents}

    {:noreply, state, push: graph} =
      Slider.handle_input({:cursor_button, {:left, :press, nil, {203, 0}}}, context, %{
        state
        | tracking: false
      })

    assert state.tracking
    assert state.value != orig_value

    # confirm the input was captured
    assert_receive({:"$gen_cast", {:capture_input, ^context, [:cursor_button, :cursor_pos]}})
    assert state.graph == graph

    # confirm the value change was sent
    assert_receive({:"$gen_cast", {:event, {:value_changed, :test_id, :blue}, ^self}})

    # below min
    {:noreply, state, push: _} =
      Slider.handle_input({:cursor_button, {:left, :press, nil, {-203, 0}}}, context, %{
        state
        | tracking: false
      })

    assert_receive({:"$gen_cast", {:event, {:value_changed, :test_id, :red}, ^self}})

    # above max
    {:noreply, _, push: _} =
      Slider.handle_input({:cursor_button, {:left, :press, nil, {1203, 0}}}, context, %{
        state
        | tracking: false
      })

    assert_receive({:"$gen_cast", {:event, {:value_changed, :test_id, :orange}, ^self}})
  end

  test "handle_input {:cursor_button, :press, far left" do
    self = self()
    context = %ViewPort.Context{viewport: self}
    Process.put(:parent_pid, self)

    {:noreply, state, push: graph} =
      Slider.handle_input({:cursor_button, {:left, :press, nil, {-103, 0}}}, context, %{
        @state
        | tracking: false
      })

    assert state.tracking
    assert state.value == 0
    assert state.graph == graph
  end

  test "handle_input {:cursor_button, :press, far right" do
    self = self()
    context = %ViewPort.Context{viewport: self}
    Process.put(:parent_pid, self)

    {:noreply, state, push: graph} =
      Slider.handle_input({:cursor_button, {:left, :press, nil, {1003, 0}}}, context, %{
        @state
        | tracking: false
      })

    assert state.tracking
    assert state.value == 100
    assert state.graph == graph
  end

  test "handle_input {:cursor_button, :release" do
    self = self()
    context = %ViewPort.Context{viewport: self}
    Process.put(:parent_pid, self)

    {:noreply, state, push: graph} =
      Slider.handle_input({:cursor_button, {:left, :release, nil, {13, 0}}}, context, %{
        @state
        | tracking: true
      })

    refute state.tracking
    assert state.graph == graph

    # confirm the input was released
    assert_receive({:"$gen_cast", {:release_input, [:cursor_button, :cursor_pos]}})

    # confirm the value change was not sent
    refute_receive({:"$gen_cast", {:event, {:value_changed, _, _}, _}})
  end

  test "handle_input {:cursor_pos," do
    self = self()
    context = %ViewPort.Context{viewport: self}
    Process.put(:parent_pid, self)

    {:noreply, state, push: graph} =
      Slider.handle_input({:cursor_pos, {103, 0}}, context, %{
        @state
        | tracking: true
      })

    assert state.tracking
    assert state.value != @state.value

    assert state.graph == graph

    # confirm the value change was sent
    assert_receive({:"$gen_cast", {:event, {:value_changed, :test_id, 34}, ^self}})
  end
end
