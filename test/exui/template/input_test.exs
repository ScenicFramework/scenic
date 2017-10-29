#
#  Created by Boyd Multerer on 6/20/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Template.InputTest do
  use ExUnit.Case, async: true
  doctest Exui

  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.Template.Input


  @value    {123, "abc"}
  @name     "test value"
  @state    {:test,"state"}
  @input    Input.build(name: @name, value: @value, state:  @state) |> Graph.get(0)

  #============================================================================
  # build
  test "build works" do
    assert Input.build(name: "test", value: 123)
  end

  test "build sets the requested name" do
    input = Input.build(name: "test_name")
    {:input, "test_name", _, _} = input
      |> Graph.get(0)
      |> Primitive.get_state()
  end

  test "build rejects non-bitstring names" do
    assert_raise Scenic.Template.Input.Error, fn ->
      Input.build(name: :test_name)
    end
  end

  test "build sets requested value" do
    input = Input.build(value: 123)
    {:input, _, 123, _} = input
      |> Graph.get(0)
      |> Primitive.get_state()
  end

  test "build sets requested state" do
    input = Input.build(state: {:abc, 123})
    {:input, _, _, {:abc, 123}} = input
      |> Graph.get(0)
      |> Primitive.get_state()
  end

  #============================================================================
  # access the input value
  test "get_value returns the value" do
    assert Input.get_value(@input) == @value
  end

  test "put_value sets the value" do
    assert Input.put_value(@input, 1024)
      |> Input.get_value() == 1024
  end

  #============================================================================
  # access the input name
  test "get_name returns the name" do
    assert Input.get_name(@input) == @name
  end

  test "put_name sets the name" do
    assert Input.put_name(@input, "A different name")
      |> Input.get_name() == "A different name"
  end

  #============================================================================
  # access the input state
  test "get_state returns the state" do
    assert Input.get_state(@input) == @state
  end

  test "put_state sets the state" do
    assert Input.put_state(@input, {:updated,"state"})
      |> Input.get_state() == {:updated,"state"}
  end


end