#
#  Created by Boyd Multerer on 2018-09-19.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

defmodule Scenic.ComponentsTest do
  use ExUnit.Case, async: true
  doctest Scenic.Components

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Components

  @graph Graph.build()

  # ============================================================================
  test "button adds to a graph - default opts" do
    g = Components.button(@graph, "Name")
    p = g.primitives[1]

    assert p.module == Primitive.Component
    assert {Scenic.Component.Button, "Name", _} = p.data
  end

  test "button adds to a graph" do
    p =
      Components.button(@graph, "Name", id: :button)
      |> Graph.get!(:button)

    assert p.module == Primitive.Component
    assert {Scenic.Component.Button, "Name", _} = p.data
    assert p.id == :button
  end

  test "button add rejects bad data" do
    assert_raise RuntimeError, fn ->
      Components.button(@graph, 123, id: :button)
    end
  end

  test "button modifies ref init data" do
    p =
      Components.button(@graph, "Name", id: :button)
      |> Graph.get!(:button)
      |> Components.button("Modified", id: :modified)

    assert {Scenic.Component.Button, "Modified", _} = p.data
    assert p.id == :modified
  end

  test "button modify rejects bad data" do
    p =
      Components.button(@graph, "Name", id: :button)
      |> Graph.get!(:button)

    assert_raise RuntimeError, fn ->
      Components.button(p, 123)
    end
  end

  # ============================================================================
  test "checkbox adds to a graph - default opts" do
    g = Components.checkbox(@graph, {"Name", true})
    p = g.primitives[1]

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.Checkbox, {"Name", true}, _} = p.data
  end

  test "checkbox adds to a graph" do
    p =
      Components.checkbox(@graph, {"Name", true}, id: :checkbox)
      |> Graph.get!(:checkbox)

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.Checkbox, {"Name", true}, _} = p.data
    assert p.id == :checkbox

    p =
      Components.checkbox(@graph, {"Name", false}, id: :checkbox)
      |> Graph.get!(:checkbox)

    assert {Scenic.Component.Input.Checkbox, {"Name", false}, _} = p.data
  end

  test "checkbox add rejects bad data" do
    assert_raise RuntimeError, fn ->
      Components.checkbox(@graph, 123, id: :checkbox)
    end
  end

  test "checkbox modifies ref init data" do
    p =
      Components.checkbox(@graph, {"Name", true}, id: :checkbox)
      |> Graph.get!(:checkbox)
      |> Components.checkbox({"Modified", false}, id: :modified)

    assert {Scenic.Component.Input.Checkbox, {"Modified", false}, _} = p.data
    assert p.id == :modified
  end

  test "checkbox modify rejects bad data" do
    p =
      Components.checkbox(@graph, {"Name", true}, id: :checkbox)
      |> Graph.get!(:checkbox)

    assert_raise RuntimeError, fn ->
      Components.checkbox(p, 123)
    end
  end

  # ============================================================================
  @drop_data {[{"a", 1}, {"b", 2}], 2}

  test "dropdown adds to a graph - default opts" do
    g = Components.dropdown(@graph, @drop_data)
    p = g.primitives[1]

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.Dropdown, @drop_data, _} = p.data
  end

  test "dropdown adds to a graph" do
    p =
      Components.dropdown(@graph, @drop_data, id: :dropdown)
      |> Graph.get!(:dropdown)

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.Dropdown, @drop_data, _} = p.data
    assert p.id == :dropdown
  end

  test "dropdown add rejects bad data" do
    assert_raise RuntimeError, fn ->
      Components.dropdown(@graph, 123, id: :button)
    end
  end

  test "dropdown modifies ref init data" do
    mod_data = {[{"a", 1}, {"b", 2}], 1}

    p =
      Components.dropdown(@graph, @drop_data, id: :dropdown)
      |> Graph.get!(:dropdown)
      |> Components.dropdown(mod_data, id: :modified)

    assert {Scenic.Component.Input.Dropdown, ^mod_data, _} = p.data
    assert p.id == :modified
  end

  test "dropdown modify rejects bad data" do
    p =
      Components.dropdown(@graph, @drop_data, id: :dropdown)
      |> Graph.get!(:dropdown)

    assert_raise RuntimeError, fn ->
      Components.dropdown(p, 123)
    end
  end

  # ============================================================================
  @radio_data {[{"a", 1}, {"b", 2}, {"c", 3}], 2}

  test "radio_group adds to a graph - default opts" do
    g = Components.radio_group(@graph, @radio_data)
    p = g.primitives[1]

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.RadioGroup, @radio_data, _} = p.data
  end

  test "radio_group adds to a graph" do
    p =
      Components.radio_group(@graph, @radio_data, id: :radio_group)
      |> Graph.get!(:radio_group)

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.RadioGroup, @radio_data, _} = p.data
    assert p.id == :radio_group
  end

  test "radio_group add rejects bad data" do
    assert_raise RuntimeError, fn ->
      Components.radio_group(@graph, 123, id: :radio_group)
    end
  end

  test "radio_group modifies ref init data" do
    mod_data = {[{"a", 1}, {"b", 2}, {"c", 3}], 3}

    p =
      Components.radio_group(@graph, @radio_data, id: :radio_group)
      |> Graph.get!(:radio_group)
      |> Components.radio_group(mod_data, id: :modified)

    assert {Scenic.Component.Input.RadioGroup, ^mod_data, _} = p.data
    assert p.id == :modified
  end

  test "radio_group modify rejects bad data" do
    p =
      Components.radio_group(@graph, @drop_data, id: :radio_group)
      |> Graph.get!(:radio_group)

    assert_raise RuntimeError, fn ->
      Components.radio_group(p, 123)
    end
  end

  # ============================================================================
  @slider_int_data {{0, 100}, 20}
  @slider_float_data {{0.1, 100.2}, 20.2}
  @slider_list_data {[:red, :green, :blue], :green}

  test "slider adds to a graph - default opts" do
    g = Components.slider(@graph, @slider_int_data)
    p = g.primitives[1]

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.Slider, @slider_int_data, _} = p.data
  end

  test "slider adds to a graph" do
    p =
      Components.slider(@graph, @slider_int_data, id: :slider)
      |> Graph.get!(:slider)

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.Slider, @slider_int_data, _} = p.data
    assert p.id == :slider

    p =
      Components.slider(@graph, @slider_float_data, id: :slider)
      |> Graph.get!(:slider)

    assert {Scenic.Component.Input.Slider, @slider_float_data, _} = p.data

    p =
      Components.slider(@graph, @slider_list_data, id: :slider)
      |> Graph.get!(:slider)

    assert {Scenic.Component.Input.Slider, @slider_list_data, _} = p.data
  end

  test "slider add rejects bad data" do
    assert_raise RuntimeError, fn ->
      Components.slider(@graph, 123, id: :slider)
    end
  end

  test "slider modifies ref init data" do
    mod_data = {[:red, :green, :blue, :yellow], :red}

    p =
      Components.slider(@graph, @slider_list_data, id: :slider)
      |> Graph.get!(:slider)
      |> Components.slider(mod_data, id: :modified)

    assert {Scenic.Component.Input.Slider, ^mod_data, _} = p.data
    assert p.id == :modified
  end

  test "slider modify rejects bad data" do
    p =
      Components.slider(@graph, @slider_list_data, id: :slider)
      |> Graph.get!(:slider)

    assert_raise RuntimeError, fn ->
      Components.slider(p, 123)
    end
  end

  # ============================================================================
  test "text_field adds to a graph - default opts" do
    g = Components.text_field(@graph, "Name")
    p = g.primitives[1]
    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.TextField, "Name", _} = p.data
  end

  test "text_field adds to a graph" do
    p =
      Components.text_field(@graph, "Name", id: :text_field)
      |> Graph.get!(:text_field)

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.TextField, "Name", _} = p.data
    assert p.id == :text_field
  end

  test "text_field add rejects bad data" do
    assert_raise RuntimeError, fn ->
      Components.text_field(@graph, 123, id: :text_field)
    end
  end

  test "text_field modifies ref init data" do
    p =
      Components.text_field(@graph, "Name", id: :text_field)
      |> Graph.get!(:text_field)
      |> Components.text_field("Modified", id: :modified)

    assert {Scenic.Component.Input.TextField, "Modified", _} = p.data
    assert p.id == :modified
  end

  test "text_field modify rejects bad data" do
    p =
      Components.text_field(@graph, "some text", id: :text_field)
      |> Graph.get!(:text_field)

    assert_raise RuntimeError, fn ->
      Components.text_field(p, 123)
    end
  end

  # ============================================================================
  test "toggle adds to a graph - default opts" do
    g = Components.toggle(@graph, true)
    p = g.primitives[1]

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.Toggle, true, _} = p.data
  end

  test "toggle adds to a graph" do
    p =
      Components.toggle(@graph, true, id: :toggle)
      |> Graph.get!(:toggle)

    assert p.module == Primitive.Component
    assert {Scenic.Component.Input.Toggle, true, _} = p.data
    assert p.id == :toggle

    p =
      Components.toggle(@graph, false, id: :toggle)
      |> Graph.get!(:toggle)

    assert {Scenic.Component.Input.Toggle, false, _} = p.data
  end

  test "toggle add rejects bad data" do
    assert_raise RuntimeError, fn ->
      Components.toggle(@graph, 123, id: :toggle)
    end
  end

  test "toggle modifies ref init data" do
    p =
      Components.toggle(@graph, true, id: :toggle)
      |> Graph.get!(:toggle)
      |> Components.toggle(false, id: :modified)

    assert {Scenic.Component.Input.Toggle, false, _} = p.data
    assert p.id == :modified
  end

  test "toggle modify rejects bad data" do
    p =
      Components.toggle(@graph, true, id: :toggle)
      |> Graph.get!(:toggle)

    assert_raise RuntimeError, fn ->
      Components.toggle(p, 123)
    end
  end
end
