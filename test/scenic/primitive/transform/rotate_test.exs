#
#  Created by Boyd Multerer on 2017-11-02.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Transform.RotateTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Transform.Rotate

  alias Scenic.Primitive.Transform.Rotate

  test "validate accepts valid data" do
    assert Rotate.validate(1) == {:ok, 1}
    assert Rotate.validate(1.5) == {:ok, 1.5}
  end

  test "validate rejects bad data" do
    {:error, msg} = Rotate.validate({1.5, 2})
    assert msg =~ "Invalid Rotation"

    {:error, msg} = Rotate.validate("1.5")
    assert msg =~ "Invalid Rotation"

    {:error, msg} = Rotate.validate(:banana)
    assert msg =~ "Invalid Rotation"
  end
end
