#
#  Created by Boyd Multerer on 2017-11-02.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.ScaleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Scale

  test "info works" do
    assert Scale.info(:test_data) =~ ":test_data"
  end

  test "verify passes valid data" do
    assert Scale.verify(1.0) == true
    assert Scale.verify({1.0, 2.0}) == true
  end

  test "verify fails invalid data" do
    assert Scale.verify({1.1, 1.2, 1.3}) == false
    assert Scale.verify({1.1, :banana}) == false
    assert Scale.verify(:banana) == false
  end

  test "normalize" do
    assert Scale.normalize(2) == {2, 2}
    assert Scale.normalize(2.1) == {2.1, 2.1}
    assert Scale.normalize({1.1, 2.2}) == {1.1, 2.2}
  end

  test "normalize raises on bad data" do
    assert_raise FunctionClauseError, fn ->
      assert Scale.normalize(:banana)
    end
  end
end
