#
#  Created by Boyd Multerer on 2017-11-02.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.TranslateTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Translate

  # ============================================================================
  # verify

  test "info works" do
    assert Translate.info(:test_data) =~ ":test_data"
  end

  test "verify passes valid data" do
    assert Translate.verify({1.0, 2.0}) == true
  end

  test "verify fails invalid data" do
    assert Translate.verify(1.1) == false
    assert Translate.verify({1.1}) == false
    assert Translate.verify({1.1, 1.2, 1.3}) == false
    assert Translate.verify({1.1, :banana}) == false
    assert Translate.verify(:banana) == false
  end

  test "normalize works" do
    assert Translate.normalize({1, 2}) == {1, 2}
    assert Translate.normalize({1.1, 2.2}) == {1.1, 2.2}
  end

  test "normalize raises on bad data" do
    assert_raise FunctionClauseError, fn ->
      assert Translate.normalize(:banana)
    end
  end
end
