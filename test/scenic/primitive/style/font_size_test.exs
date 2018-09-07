#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontSizeTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.FontSize

  # ============================================================================
  # verify - various forms

  test "verfy works" do
    assert FontSize.verify(10)
    assert FontSize.verify(255)
  end

  test "verify rejects out of bounds values" do
    refute FontSize.verify(5)
  end

  test "verify! works" do
    assert FontSize.verify!(10)
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      FontSize.verify!("banana")
    end
  end
end
