#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Font

  test "info works" do
    assert Font.info(:test_data) =~ ":test_data"
  end

  # ============================================================================
  # verify - various forms

  test "verfy works" do
    assert Font.verify(:roboto)
    assert Font.verify("98u2r8hkajhfs")
  end

  test "verify rejects bad values" do
    refute Font.verify(123)
  end

  test "verify! works" do
    assert Font.verify!(:roboto)
    assert Font.verify!("98u2r8hkajhfs")
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      Font.verify!(123)
    end
  end
end
