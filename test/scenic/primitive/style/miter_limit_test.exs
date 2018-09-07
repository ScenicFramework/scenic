#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.MiterLimitTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.MiterLimit

  # ============================================================================
  # verify - various forms

  test "verfy works" do
    assert MiterLimit.verify(10)
    assert MiterLimit.verify(1)
    assert MiterLimit.verify(255)
  end

  test "verify rejects out of bounds values" do
    refute MiterLimit.verify(-1)
  end

  test "verify! works" do
    assert MiterLimit.verify!(10)
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      MiterLimit.verify!("banana")
    end
  end
end
