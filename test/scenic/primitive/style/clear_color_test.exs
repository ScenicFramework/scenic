#
#  Created by Boyd Multerer on 11/01/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.ClearColorTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.ClearColor

  # ============================================================================
  # verify - various forms

  test "verfy works for a single color" do
    assert ClearColor.verify(:red)
    assert ClearColor.verify({:red, 128})
    assert ClearColor.verify({1, 2, 3})
    assert ClearColor.verify({1, 2, 3, 4})
  end

  test "verify rejects negative channels" do
    refute ClearColor.verify({:red, -1})
    refute ClearColor.verify({-1, 2, 3, 4})
  end

  test "verify rejects out of bounds channels" do
    refute ClearColor.verify({:red, 256})
    refute ClearColor.verify({256, 2, 3, 4})
  end

  test "verify! works" do
    assert ClearColor.verify!(:red)
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      ClearColor.verify!({{:red, -1}})
    end
  end

  # ============================================================================
  # normalize - various forms

  test "normalize works for a single color" do
    assert ClearColor.normalize(:red) == {255, 0, 0, 255}
    assert ClearColor.normalize({:red, 128}) == {255, 0, 0, 128}
    assert ClearColor.normalize({1, 2, 3}) == {1, 2, 3, 255}
    assert ClearColor.normalize({1, 2, 3, 4}) == {1, 2, 3, 4}
  end
end
