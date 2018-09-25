#
#  Created by Boyd Multerer on June 18, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.CapTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Cap

  # ============================================================================
  # verify - various forms
  test "info works" do
    assert Cap.info(:test_data) =~ ":test_data"
  end

  test "verfy works" do
    assert Cap.verify(:butt)
    assert Cap.verify(:round)
    assert Cap.verify(:square)
  end

  test "verify rejects invalid values" do
    refute Cap.verify("butt")
    refute Cap.verify(123)
  end

  test "verify! works" do
    assert Cap.verify!(:butt)
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      Cap.verify!("butt")
    end
  end
end
