#
#  Created by Boyd Multerer on September 19, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ComponentsTest do
  use ExUnit.Case, async: true
  doctest Scenic.Components
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Components

  @graph Graph.build()

  # @tau    2.0 * :math.pi();

  # import IEx

  # ============================================================================
  test "button adds to a graph - default opts" do
    g = Components.button(@graph, "Name")
    p = g.primitives[1]

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Button, "Name"}
  end

  test "button adds to a graph" do
    p =
      Components.button(@graph, "Name", id: :button)
      |> Graph.get!(:button)

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Button, "Name"}
    assert p.id == :button
  end

  test "button modifies ref init data" do
    p =
      Components.button(@graph, "Name", id: :button)
      |> Graph.get!(:button)
      |> Components.button("Modified", id: :modified)

    assert p.data == {Scenic.Component.Button, "Modified"}
    assert p.id == :modified
  end

  # ============================================================================
  test "checkbox adds to a graph - default opts" do
    g = Components.checkbox(@graph, {"Name", true})
    p = g.primitives[1]

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Input.Checkbox, {"Name", true}}
  end

  test "checkbox adds to a graph" do
    p =
      Components.checkbox(@graph, {"Name", true}, id: :checkbox)
      |> Graph.get!(:checkbox)

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Input.Checkbox, {"Name", true}}
    assert p.id == :checkbox

    p =
      Components.checkbox(@graph, {"Name", false}, id: :checkbox)
      |> Graph.get!(:checkbox)

    assert p.data == {Scenic.Component.Input.Checkbox, {"Name", false}}
  end

  test "checkbox modifies ref init data" do
    p =
      Components.checkbox(@graph, {"Name", true}, id: :checkbox)
      |> Graph.get!(:checkbox)
      |> Components.checkbox({"Modified", false}, id: :modified)

    assert p.data == {Scenic.Component.Input.Checkbox, {"Modified", false}}
    assert p.id == :modified
  end

  # ============================================================================
  @drop_data {[{"a", 1}, {"b", 2}], 2}

  test "dropdown adds to a graph - default opts" do
    g = Components.dropdown(@graph, @drop_data)
    p = g.primitives[1]

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Input.Dropdown, @drop_data}
  end

  test "dropdown adds to a graph" do
    p =
      Components.dropdown(@graph, @drop_data, id: :dropdown)
      |> Graph.get!(:dropdown)

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Input.Dropdown, @drop_data}
    assert p.id == :dropdown
  end

  test "dropdown modifies ref init data" do
    mod_data = {[{"a", 1}, {"b", 2}], 1}

    p =
      Components.dropdown(@graph, @drop_data, id: :dropdown)
      |> Graph.get!(:dropdown)
      |> Components.dropdown(mod_data, id: :modified)

    assert p.data == {Scenic.Component.Input.Dropdown, mod_data}
    assert p.id == :modified
  end

  # ============================================================================
  @radio_data [{"a", 1}, {"b", 2, true}, {"c", 2, false}]

  test "radio_group adds to a graph - default opts" do
    g = Components.radio_group(@graph, @radio_data)
    p = g.primitives[1]

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Input.RadioGroup, @radio_data}
  end

  test "radio_group adds to a graph" do
    p =
      Components.radio_group(@graph, @radio_data, id: :radio_group)
      |> Graph.get!(:radio_group)

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Input.RadioGroup, @radio_data}
    assert p.id == :radio_group
  end

  test "radio_group modifies ref init data" do
    mod_data = [{"a", 1, true}, {"b", 2}, {"c", 2, false}]

    p =
      Components.radio_group(@graph, @radio_data, id: :radio_group)
      |> Graph.get!(:radio_group)
      |> Components.radio_group(mod_data, id: :modified)

    assert p.data == {Scenic.Component.Input.RadioGroup, mod_data}
    assert p.id == :modified
  end

  # ============================================================================
  @slider_int_data {{0, 100}, 20}
  @slider_float_data {{0.1, 100.2}, 20.2}
  @slider_list_data {[:red, :green, :blue], :green}

  test "slider adds to a graph - default opts" do
    g = Components.slider(@graph, @slider_int_data)
    p = g.primitives[1]

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Input.Slider, @slider_int_data}
  end

  test "slider adds to a graph" do
    p =
      Components.slider(@graph, @slider_int_data, id: :slider)
      |> Graph.get!(:slider)

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Input.Slider, @slider_int_data}
    assert p.id == :slider

    p =
      Components.slider(@graph, @slider_float_data, id: :slider)
      |> Graph.get!(:slider)

    assert p.data == {Scenic.Component.Input.Slider, @slider_float_data}

    p =
      Components.slider(@graph, @slider_list_data, id: :slider)
      |> Graph.get!(:slider)

    assert p.data == {Scenic.Component.Input.Slider, @slider_list_data}
  end

  test "slider modifies ref init data" do
    mod_data = {[:red, :green, :blue, :yellow], :red}

    p =
      Components.slider(@graph, @slider_list_data, id: :slider)
      |> Graph.get!(:slider)
      |> Components.slider(mod_data, id: :modified)

    assert p.data == {Scenic.Component.Input.Slider, mod_data}
    assert p.id == :modified
  end

  # ============================================================================
  test "text_field adds to a graph - default opts" do
    g = Components.text_field(@graph, "Name")
    p = g.primitives[1]

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Input.TextField, "Name"}
  end

  test "text_field adds to a graph" do
    p =
      Components.text_field(@graph, "Name", id: :text_field)
      |> Graph.get!(:text_field)

    assert p.module == Primitive.SceneRef
    assert p.data == {Scenic.Component.Input.TextField, "Name"}
    assert p.id == :text_field
  end

  test "text_field modifies ref init data" do
    p =
      Components.text_field(@graph, "Name", id: :text_field)
      |> Graph.get!(:text_field)
      |> Components.text_field("Modified", id: :modified)

    assert p.data == {Scenic.Component.Input.TextField, "Modified"}
    assert p.id == :modified
  end
end
