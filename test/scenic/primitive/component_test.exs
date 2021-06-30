#
#  Created by Boyd Multerer on 2021-03-02
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.ComponentTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Component

  alias Scenic.Primitive
  alias Scenic.Primitive.Component
  alias Scenic.Component.Button

  @data_name_id {:named_scene, 123}
  #  pid version must be made dynamically
  #  ref version must be made dynamically
  @data_mod {{__MODULE__, 123}, 456}

  # ============================================================================
  # build / add

  test "build works" do
    p = Component.build({Button, "button", "named_button"})
    assert p.module == Component
    {Button, "button", "named_button"} = Primitive.get(p)
  end

  # ============================================================================

  test "validate accepts valid data" do
    assert Component.validate({Button, "button", "name"}) == {:ok, {Button, "button", "name"}}
  end

  test "validate accepts valid data gens name if non is supplied" do
    {:ok, {Button, "button", name}} = Component.validate({Button, "button"})
    assert is_bitstring(name)
  end

  test "validate rejects bad data" do
    {:error, msg} = Component.validate({100, "1.4"})
    assert msg =~ "Invalid Component"

    {:error, msg} = Component.validate(:banana)
    assert msg =~ "Invalid Component"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Component.valid_styles() == [:hidden]
  end

  # ============================================================================
  # compile

  test "compile raises - it is a special case" do
    p = Component.build({Button, "button", "named_button"})
    assert_raise RuntimeError, fn -> Component.compile(p, %{}) end
  end

  # ============================================================================
  # transforms

  test "default pin simply returns {0,0}" do
    assert Component.default_pin({:named, nil}) == {0, 0}
    assert Component.default_pin(@data_name_id) == {0, 0}
    assert Component.default_pin(@data_mod) == {0, 0}
    assert Component.default_pin({self(), 123}) == {0, 0}
    graph = {:graph, make_ref(), 123}
    assert Component.default_pin(graph) == {0, 0}
  end
end
