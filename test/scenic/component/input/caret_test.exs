#
#  Created by Boyd Multerer on 2018-09-11.
#  Copyright © 2018 Kry10 Industries.
#

defmodule Scenic.Component.Input.CaretTest do
  use ExUnit.Case, async: false
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Component.Input.Caret
  alias Scenic.Graph
  import Scenic.Primitives

  @graph_hidden Graph.build()
                |> line(
                  {{0, 4}, {0, 22 - 2}},
                  stroke: {2, :red},
                  hidden: true,
                  id: :caret
                )

  @graph_showing Graph.build()
                 |> line(
                   {{0, 4}, {0, 22 - 2}},
                   stroke: {2, :red},
                   hidden: false,
                   id: :caret
                 )

  @state %{
    graph: @graph_hidden,
    hidden: true,
    timer: nil,
    focused: false
  }

  # ============================================================================
  # info

  test "info works" do
    assert is_bitstring(Caret.info(:bad_data))
  end

  # ============================================================================
  # verify

  test "verify passes valid data" do
    assert Caret.verify({24, :red}) == {:ok, {24, :red}}
  end

  test "verify fails invalid data" do
    assert Caret.verify(:banana) == :invalid_data
  end

  # ============================================================================
  # init

  test "init works" do
    {:ok, state, push: graph} = Caret.init({24, :red}, styles: %{}, id: :comp_id)
    assert state == @state
    assert state.graph == graph
    assert graph == state.graph
  end

  # ============================================================================
  # cast handlers

  test ":gain_focus starts a timer and shows the caret" do
    {:noreply, state, push: graph} = Caret.handle_cast(:start_caret, @state)
    assert state.graph == @graph_showing
    assert state.graph == graph
    assert state.timer
    refute state.hidden
    assert state.focused
  end

  test ":gain_focus stops the timer and hides the caret" do
    {:noreply, state, push: graph} = Caret.handle_cast(:stop_caret, @state)
    assert state.graph == graph
    assert state.graph == @graph_hidden
    assert state.timer == nil
    assert state.hidden
    refute state.focused
  end

  test ":reset_caret resets the timer and shows the caret" do
    old_timer = :timer.send_interval(1000, :blink)
    state = %{@state | timer: old_timer, focused: true}
    {:noreply, state, push: graph} = Caret.handle_cast(:reset_caret, state)
    assert state.graph == graph
    assert state.graph == @graph_showing
    assert state.timer != old_timer
    refute state.hidden
    assert state.focused
  end

  # ============================================================================
  # cast handlers

  test ":blink toggles hidden" do
    {:noreply, state, push: graph} = Caret.handle_info(:blink, @state)
    assert state.graph == @graph_showing
    assert state.graph == graph
    refute state.hidden

    {:noreply, state, push: graph} = Caret.handle_info(:blink, state)
    assert state.graph == @graph_hidden
    assert state.graph == graph
    assert state.hidden
  end
end
