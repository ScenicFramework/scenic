#
#  Created by Boyd Multerer on September 25 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.ThemeTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Theme

  test "info works" do
    assert Theme.info(:test_data) =~ ":test_data"
  end

  # ============================================================================
  # verify - various forms

  test "verify works with presets" do
    assert Theme.verify(:dark)
    assert Theme.verify(:light)
    assert Theme.verify(:primary)
    assert Theme.verify(:secondary)
    assert Theme.verify(:success)
    assert Theme.verify(:danger)
    assert Theme.verify(:warning)
    assert Theme.verify(:info)
    assert Theme.verify(:text)
  end

  test "verify works with color maps" do
    assert Theme.verify(%{some_name: :red, another_name: :blue})
  end

  test "verify rejects invalid values" do
    refute Theme.verify("banana")
  end

  test "verify rejects maps with invalid colors" do
    refute Theme.verify(%{some_name: "red", another_name: :blue})
  end

  test "verify! works" do
    assert Theme.verify!(:primary)
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      Theme.verify!("banana")
    end
  end

  # ============================================================================
  # normalize - various forms

  test "normalize works" do
    assert is_map(Theme.normalize(:primary))
    assert is_map(Theme.normalize(%{some_name: :red, another_name: :blue}))
  end
end
