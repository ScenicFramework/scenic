#
#  Created by Boyd Multerer on June 18, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.ScissorTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Scissor

  test "info works" do
    assert Scissor.info(:test_data) =~ ":test_data"
  end

  # ============================================================================
  # verify - various forms

  test "verfy works" do
    assert Scissor.verify({100, 200})
  end

  test "verify rejects invalid values" do
    refute Scissor.verify(123)
    refute Scissor.verify({10, 20, 100})
  end

  test "verify! works" do
    assert Scissor.verify!({100, 200})
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      Scissor.verify!(123)
    end
  end
end
