#
#  Created by Boyd Multerer on September 18, 2018
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Component.Input.TextFieldTest do
  use ExUnit.Case, async: true
  doctest Scenic

  # alias Scenic.Component
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.ViewPort
  alias Scenic.Component.Input.TextField

  @initial_value "Initial value"
  @initial_password "*************"

  @state %{
    graph: Graph.build(),
    theme: Primitive.Style.Theme.preset(:primary),
    width: 100,
    height: 30,
    value: @initial_value,
    display: @initial_value,
    hint: "hint",
    index: 2,
    char_width: 12,
    focused: false,
    type: :text,
    filter: :all,
    id: :test_id
  }

  # ============================================================================
  # info

  test "info works" do
    assert is_bitstring(TextField.info(:bad_data))
    assert TextField.info(:bad_data) =~ ":bad_data"
  end

  # ============================================================================
  # verify

  test "verify passes valid data" do
    assert TextField.verify("Title") == {:ok, "Title"}
  end

  test "verify fails invalid data" do
    assert TextField.verify(:banana) == :invalid_data
  end

  # ============================================================================
  # init

  test "init works with simple data" do
    {:ok, state} = TextField.init(@initial_value, styles: %{}, id: :test_id)
    %Graph{} = state.graph
    assert is_map(state.theme)
    assert state.value == @initial_value
    assert state.display == @initial_value
    assert state.focused == false
    assert state.type == :text
    assert state.id == :test_id

    {:ok, state} = TextField.init(@initial_value, styles: %{type: :password})
    assert state.value == @initial_value
    assert state.display == @initial_password
    assert state.type == :password
  end

  # ============================================================================
  # handle_input

  # ============================================================================
  # control keys

  test "handle_input {:key \"left\" moves the cursor to the left" do
    self = self()
    scene_ref = make_ref()
    Process.put(:parent_pid, self)
    Process.put(:scene_ref, scene_ref)
    {:ok, tables_pid} = Scenic.ViewPort.Tables.start_link(nil)
    context = %ViewPort.Context{viewport: self}

    assert @state.index == 2
    {:noreply, state} = TextField.handle_input({:key, {"left", :press, 0}}, context, @state)
    # confirm the graph was pushed
    assert_receive({:"$gen_cast", {:push_graph, _, _, _}})
    assert state.index == 1

    {:noreply, state} = TextField.handle_input({:key, {"left", :press, 0}}, context, state)
    assert state.index == 0

    # does not keep going below 0
    {:noreply, state} = TextField.handle_input({:key, {"left", :press, 0}}, context, state)
    assert state.index == 0

    # cleanup
    Process.exit(tables_pid, :shutdown)
  end

  test "handle_input {:key \"right\" moves the cursor to the right" do
    self = self()
    scene_ref = make_ref()
    Process.put(:parent_pid, self)
    Process.put(:scene_ref, scene_ref)
    {:ok, tables_pid} = Scenic.ViewPort.Tables.start_link(nil)
    context = %ViewPort.Context{viewport: self}

    length = String.length(@initial_value)
    state = %{@state | index: length - 2}

    {:noreply, state} = TextField.handle_input({:key, {"right", :press, 0}}, context, state)
    # confirm the graph was pushed
    assert_receive({:"$gen_cast", {:push_graph, _, _, _}})
    assert state.index == length - 1

    {:noreply, state} = TextField.handle_input({:key, {"right", :press, 0}}, context, state)
    assert state.index == length

    # does not keep going past the end
    {:noreply, state} = TextField.handle_input({:key, {"right", :press, 0}}, context, state)
    assert state.index == length

    # cleanup
    Process.exit(tables_pid, :shutdown)
  end

  test "handle_input {:key \"home\" and \"page_up\" move the cursor all the way to the left" do
    self = self()
    scene_ref = make_ref()
    Process.put(:parent_pid, self)
    Process.put(:scene_ref, scene_ref)
    {:ok, tables_pid} = Scenic.ViewPort.Tables.start_link(nil)
    context = %ViewPort.Context{viewport: self}

    state = %{@state | index: 4}
    {:noreply, state} = TextField.handle_input({:key, {"home", :press, 0}}, context, state)
    # confirm the graph was pushed
    assert_receive({:"$gen_cast", {:push_graph, _, _, _}})
    assert state.index == 0

    state = %{@state | index: 4}
    {:noreply, state} = TextField.handle_input({:key, {"page_up", :press, 0}}, context, state)
    # confirm the graph was pushed
    assert_receive({:"$gen_cast", {:push_graph, _, _, _}})
    assert state.index == 0

    # cleanup
    Process.exit(tables_pid, :shutdown)
  end

  test "handle_input {:key \"end\" and \"page_down\" move the cursor all the way to the right" do
    self = self()
    scene_ref = make_ref()
    Process.put(:parent_pid, self)
    Process.put(:scene_ref, scene_ref)
    {:ok, tables_pid} = Scenic.ViewPort.Tables.start_link(nil)
    context = %ViewPort.Context{viewport: self}

    length = String.length(@initial_value)

    state = %{@state | index: 4}
    {:noreply, state} = TextField.handle_input({:key, {"end", :press, 0}}, context, state)
    # confirm the graph was pushed
    assert_receive({:"$gen_cast", {:push_graph, _, _, _}})
    assert state.index == length

    state = %{@state | index: 4}
    {:noreply, state} = TextField.handle_input({:key, {"page_down", :press, 0}}, context, state)
    # confirm the graph was pushed
    assert_receive({:"$gen_cast", {:push_graph, _, _, _}})
    assert state.index == length

    # cleanup
    Process.exit(tables_pid, :shutdown)
  end

  test "handle_input {:key \"backspace\" deletes to the left" do
    self = self()
    scene_ref = make_ref()
    Process.put(:parent_pid, self)
    Process.put(:scene_ref, scene_ref)
    {:ok, tables_pid} = Scenic.ViewPort.Tables.start_link(nil)
    context = %ViewPort.Context{viewport: self}

    {:noreply, state} = TextField.handle_input({:key, {"backspace", :press, 0}}, context, @state)
    # confirm the graph was pushed
    assert_receive({:"$gen_cast", {:push_graph, _, _, _}})
    assert state.index == 1
    assert state.value == "Iitial value"

    {:noreply, state} = TextField.handle_input({:key, {"backspace", :press, 0}}, context, state)
    assert state.index == 0
    assert state.value == "itial value"

    # does nothing if already at position 0
    {:noreply, state} = TextField.handle_input({:key, {"backspace", :press, 0}}, context, state)
    assert state.index == 0
    assert state.value == "itial value"

    # cleanup
    Process.exit(tables_pid, :shutdown)
  end

  test "handle_input {:key \"delete\" deletes to the right" do
    self = self()
    scene_ref = make_ref()
    Process.put(:parent_pid, self)
    Process.put(:scene_ref, scene_ref)
    {:ok, tables_pid} = Scenic.ViewPort.Tables.start_link(nil)
    context = %ViewPort.Context{viewport: self}

    length = String.length(@initial_value)
    pos = length - 2
    state = %{@state | index: pos}

    {:noreply, state} = TextField.handle_input({:key, {"delete", :press, 0}}, context, state)
    # confirm the graph was pushed
    assert_receive({:"$gen_cast", {:push_graph, _, _, _}})
    assert state.index == pos
    assert state.value == "Initial vale"

    {:noreply, state} = TextField.handle_input({:key, {"delete", :press, 0}}, context, state)
    assert state.index == pos
    assert state.value == "Initial val"

    # does nothing if already at position 0
    {:noreply, state} = TextField.handle_input({:key, {"delete", :press, 0}}, context, state)
    assert state.index == pos
    assert state.value == "Initial val"

    # cleanup
    Process.exit(tables_pid, :shutdown)
  end

  test "handle_input {:codepoint adds and moves cursor to right" do
    self = self()
    scene_ref = make_ref()
    Process.put(:parent_pid, self)
    Process.put(:scene_ref, scene_ref)
    {:ok, tables_pid} = Scenic.ViewPort.Tables.start_link(nil)
    context = %ViewPort.Context{viewport: self}

    state = %{@state | index: 2}

    {:noreply, state} = TextField.handle_input({:codepoint, {"a", 0}}, context, state)
    # confirm the graph was pushed
    assert_receive({:"$gen_cast", {:push_graph, _, _, _}})
    assert state.index == 3
    assert state.value == "Inaitial value"
    assert state.display == "Inaitial value"

    # can also add strings
    {:noreply, state} = TextField.handle_input({:codepoint, {".com", 0}}, context, state)
    assert state.index == 7
    assert state.value == "Ina.comitial value"

    # rejects filtered characters
    state = %{state | filter: :number}
    {:noreply, state} = TextField.handle_input({:codepoint, {"a", 0}}, context, state)
    assert state.index == 7
    assert state.value == "Ina.comitial value"

    # cleanup
    Process.exit(tables_pid, :shutdown)
  end

  test "handle_input {:codepoint displays password * chars" do
    self = self()
    scene_ref = make_ref()
    Process.put(:parent_pid, self)
    Process.put(:scene_ref, scene_ref)
    {:ok, tables_pid} = Scenic.ViewPort.Tables.start_link(nil)
    context = %ViewPort.Context{viewport: self}

    state = %{@state | index: 2, type: :password, display: @initial_password}

    {:noreply, state} = TextField.handle_input({:codepoint, {"a", 0}}, context, state)
    # confirm the graph was pushed
    assert_receive({:"$gen_cast", {:push_graph, _, _, _}})
    assert state.index == 3
    assert state.value == "Inaitial value"
    assert state.display == @initial_password <> "*"

    # cleanup
    Process.exit(tables_pid, :shutdown)
  end

  test "handle_input does nothing on unknown input" do
    context = %ViewPort.Context{viewport: self()}
    {:noreply, state} = TextField.handle_input(:unknown, context, @state)
    assert state == @state
  end
end
