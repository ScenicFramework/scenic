#
#  Created by Boyd Multerer on 2018-06-18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextAlignTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.TextAlign

  test "info works" do
    assert TextAlign.info(:test_data) =~ ":test_data"
  end

  # ============================================================================
  # verify - various forms

  test "verfy works" do
    assert TextAlign.verify(:left)
    assert TextAlign.verify(:right)
    assert TextAlign.verify(:center)

    assert TextAlign.verify(:left_top)
    assert TextAlign.verify(:right_top)
    assert TextAlign.verify(:center_top)

    assert TextAlign.verify(:left_middle)
    assert TextAlign.verify(:right_middle)
    assert TextAlign.verify(:center_middle)

    assert TextAlign.verify(:left_bottom)
    assert TextAlign.verify(:right_bottom)
    assert TextAlign.verify(:center_bottom)
  end

  test "verify rejects invalid values" do
    refute TextAlign.verify("left")
    refute TextAlign.verify(123)
  end

  test "verify! works" do
    assert TextAlign.verify!(:left)
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      TextAlign.verify!("left")
    end
  end
end
