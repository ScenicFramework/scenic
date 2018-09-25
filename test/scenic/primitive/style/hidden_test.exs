#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.HiddenTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Hidden

  test "info works" do
    assert Hidden.info(:test_data) =~ ":test_data"
  end

  # ============================================================================
  # verify - various forms

  test "verfy works for a single color" do
    assert Hidden.verify(true)
    assert Hidden.verify(false)
  end

  test "verify rejects anything else" do
    refute Hidden.verify("true")
    refute Hidden.verify(1)
    refute Hidden.verify(0)
  end

  test "verify! works" do
    assert Hidden.verify!(true)
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      Hidden.verify!("banana")
    end
  end
end
