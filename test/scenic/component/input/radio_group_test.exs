#
#  Created by Boyd Multerer on 2018-09-18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.Input.RadioGroupTest do
  use ExUnit.Case, async: false
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Graph
  alias Scenic.ViewPort.Tables
  alias Scenic.Component.Input.RadioGroup

  @state %{
    graph: Graph.build(),
    value: :abc,
    id: :test_id
  }

  # ============================================================================
  # info

  test "info works" do
    assert is_bitstring(RadioGroup.info(:bad_data))
    assert RadioGroup.info(:bad_data) =~ ":bad_data"
  end

  # ============================================================================
  # verify

  test "verify passes valid data" do
    list = [{"Title", :abc}]
    assert RadioGroup.verify(list) == {:ok, list}
    list = [{"Title0", :abc}, {"Title1", :def, true}, {"Title2", :ghi, false}]
    assert RadioGroup.verify(list) == {:ok, list}
  end

  test "verify fails invalid data" do
    assert RadioGroup.verify(:banana) == :invalid_data
    assert RadioGroup.verify({"Title", :abc}) == :invalid_data
    list = [{"Title0", :abc}, {"Title1", :def, true}, {"Title2", :ghi, :bad_value}]
    assert RadioGroup.verify(list) == :invalid_data
  end

  # ============================================================================
  # init

  test "init works with simple data" do
    list = [{"Title0", :abc}, {"Title1", :def, true}, {"Title2", :ghi, false}]
    {:ok, state, push: graph} = RadioGroup.init(list, styles: %{}, id: :test_id)
    %Graph{} = state.graph
    assert state.graph == graph
    assert state.value == :def
    assert state.id == :test_id
  end

  # ============================================================================
  # filter_event

  test "filter_event listens to clicks from buttons and handles value changes" do
    self = self()
    scene_ref = make_ref()
    Process.put(:parent_pid, self)
    Process.put(:scene_ref, scene_ref)
    {:ok, tables_pid} = Scenic.ViewPort.Tables.start_link(nil)

    Tables.insert_graph({:graph, scene_ref, nil}, self(), Graph.build(), %{})

    {:halt, state} = RadioGroup.filter_event({:click, :def}, nil, @state)
    assert state.value == :def

    # confirm the event was sent
    assert_receive({:"$gen_cast", {:event, {:value_changed, :test_id, :def}, ^self}})

    # cleanup
    Process.exit(tables_pid, :shutdown)
  end

  test "filter_event unknown event does nothing" do
    {:cont, :unknown, state} = RadioGroup.filter_event(:unknown, nil, @state)
    assert state == @state
  end
end
