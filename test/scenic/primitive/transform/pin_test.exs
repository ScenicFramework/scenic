#
#  Created by Boyd Multerer on 2017-11-02.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.PinTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Pin

  test "info works" do
    assert Pin.info(:test_data) =~ ":test_data"
  end

  test "verify passes valid data" do
    assert Pin.verify({1, 2}) == true
  end

  test "verify fails invalid data" do
    assert Pin.verify(1) == false
    assert Pin.verify({1}) == false
    assert Pin.verify({1, 2, 3, 4}) == false
    assert Pin.verify(:banana) == false
  end

  test "normalize" do
    assert Pin.normalize({1, 2}) == {1, 2}
    assert Pin.normalize({1.1, 2.2}) == {1.1, 2.2}
  end

  test "normalize raises on bad data" do
    assert_raise FunctionClauseError, fn ->
      assert Pin.normalize(:banana)
    end
  end
end
