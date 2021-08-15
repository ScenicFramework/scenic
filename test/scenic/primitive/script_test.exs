#
#  Created by Boyd Multerer on 2021-03-02
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.ScriptTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Script

  alias Scenic.Primitive
  alias Scenic.Primitive.Script

  @data_name_id {:named_scene, 123}
  #  pid version must be made dynamically
  #  ref version must be made dynamically
  @data_mod {{__MODULE__, 123}, 456}

  # ============================================================================
  # build / add

  test "build works" do
    p = Script.build("named_scene")
    assert p.module == Script
    assert Primitive.get(p) == "named_scene"
  end

  # ============================================================================

  test "validate accepts an id" do
    assert Script.validate("a string id") == {:ok, "a string id"}
  end

  test "validate rejects bad data" do
    {:error, msg} = Script.validate({100, "1.4"})
    assert msg =~ "Invalid Script"
  end

  # ============================================================================
  # styles

  test "valid_styles works" do
    assert Script.valid_styles() == [:hidden, :scissor]
  end

  # ============================================================================
  # compile

  test "compile raises - it is a special case" do
    p = Script.build("named_scene")
    assert_raise RuntimeError, fn -> Script.compile(p, %{}) end
  end

  # ============================================================================
  # transforms

  test "default pin simply returns {0,0}" do
    assert Script.default_pin({:named, nil}) == {0, 0}
    assert Script.default_pin(@data_name_id) == {0, 0}
    assert Script.default_pin(@data_mod) == {0, 0}
    assert Script.default_pin({self(), 123}) == {0, 0}
    graph = {:graph, make_ref(), 123}
    assert Script.default_pin(graph) == {0, 0}
  end
end
