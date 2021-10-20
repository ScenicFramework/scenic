#
#  Created by Boyd Multerer on 2017-11-02.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Transform.ScaleTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Transform.Scale

  alias Scenic.Primitive.Transform.Scale

  test "validate accepts valid data" do
    assert Scale.validate(1.5) == {:ok, {1.5, 1.5}}
    assert Scale.validate({1, 2.5}) == {:ok, {1, 2.5}}
  end

  test "validate rejects bad data" do
    {:error, msg} = Scale.validate(-2)
    assert msg =~ "Invalid Scale"

    {:error, msg} = Scale.validate({2, -3})
    assert msg =~ "Invalid Scale"

    {:error, msg} = Scale.validate({"1.5", 2})
    assert msg =~ "Invalid Scale"

    {:error, msg} = Scale.validate("1.5")
    assert msg =~ "Invalid Scale"

    {:error, msg} = Scale.validate(:banana)
    assert msg =~ "Invalid Scale"
  end
end
