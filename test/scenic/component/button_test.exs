#
#  Created by Boyd Multerer on 2018-07-15.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.ButtonTest do
  use ExUnit.Case, async: false
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Component.Button

  @state %{
    graph: Graph.build(),
    theme: Primitive.Style.Theme.preset(:primary),
    pressed: false,
    contained: false,
    align: :center,
    id: :test_id
  }

  # ============================================================================
  # info

  test "info works" do
    assert is_bitstring(Button.info(:bad_data))
    assert Button.info(:bad_data) =~ ":bad_data"
  end

  # ============================================================================
  # verify

  test "verify passes valid data" do
    assert Button.verify("Button") == {:ok, "Button"}
  end

  test "verify fails invalid data" do
    assert Button.verify(:banana) == :invalid_data
  end

  # ============================================================================
  # init

  test "init works with simple data" do
    {:ok, state, push: graph} = Button.init("Button", styles: %{}, id: :button_id)
    %Graph{} = state.graph
    assert is_map(state.theme)
    assert state.contained == false
    assert state.pressed == false
    assert state.align == :center
    assert state.id == :button_id
    assert graph == state.graph
  end

  test "init works with various alignments" do
    {:ok, state, push: graph} = Button.init("Button", [])
    %Primitive{styles: %{text_align: :center}} = Graph.get!(state.graph, :title)
    assert graph == state.graph

    {:ok, state, push: graph} = Button.init("Button", styles: %{alignment: :left}, id: :button_id)
    %Primitive{styles: %{text_align: :left}} = Graph.get!(state.graph, :title)
    assert graph == state.graph

    {:ok, state, push: graph} =
      Button.init("Button", styles: %{alignment: :center}, id: :button_id)

    %Primitive{styles: %{text_align: :center}} = Graph.get!(state.graph, :title)
    assert graph == state.graph

    {:ok, state, push: graph} =
      Button.init("Button", styles: %{alignment: :right}, id: :button_id)

    %Primitive{styles: %{text_align: :right}} = Graph.get!(state.graph, :title)
    assert graph == state.graph
  end

  # ============================================================================
  # handle_input

  test "handle_input {:cursor_enter, _uid} sets contained" do
    {:noreply, state, push: graph} =
      Button.handle_input({:cursor_enter, 1}, %{}, %{@state | pressed: true})

    assert state.contained
    assert graph == state.graph
  end

  test "handle_input {:cursor_exit, _uid} clears contained" do
    {:noreply, state, push: graph} =
      Button.handle_input({:cursor_exit, 1}, %{}, %{@state | pressed: true})

    refute state.contained
    assert graph == state.graph
  end

  test "handle_input {:cursor_button, :press" do
    context = %ViewPort.Context{viewport: self()}

    {:noreply, state, push: graph} =
      Button.handle_input({:cursor_button, {:left, :press, nil, nil}}, context, %{
        @state
        | pressed: false,
          contained: true
      })

    assert state.pressed
    assert graph == state.graph

    # confirm the input was captured
    assert_receive({:"$gen_cast", {:capture_input, ^context, [:cursor_button, :cursor_pos]}})
  end

  test "handle_input {:cursor_button, :release" do
    context = %ViewPort.Context{viewport: self()}

    {:noreply, state, push: graph} =
      Button.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | pressed: true,
          contained: true
      })

    refute state.pressed
    assert graph == state.graph

    # confirm the input was released
    assert_receive({:"$gen_cast", {:release_input, [:cursor_button, :cursor_pos]}})
  end

  test "handle_input {:cursor_button, :release sends a message if contained" do
    self = self()
    Process.put(:parent_pid, self)
    context = %ViewPort.Context{viewport: self()}

    {:noreply, state, push: graph} =
      Button.handle_input({:cursor_button, {:left, :release, nil, nil}}, context, %{
        @state
        | pressed: true,
          contained: true
      })

    assert graph == state.graph
  end

  test "handle_input does nothing on unknown input" do
    context = %ViewPort.Context{viewport: self()}
    {:noreply, state} = Button.handle_input(:unknown, context, @state)
    assert state == @state
  end
end
