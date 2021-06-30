#
#  Created by Boyd Multerer on 2017-11-02.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Transform.TranslateTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Transform.Translate

  alias Scenic.Primitive.Transform.Translate

  test "validate accepts valid data" do
    assert Translate.validate({1, 2}) == {:ok, {1, 2}}
    assert Translate.validate({1, 2.5}) == {:ok, {1, 2.5}}
  end

  test "validate rejects bad data" do
    {:error, msg} = Translate.validate({"1.5", 2})
    assert msg =~ "Invalid Translation"

    {:error, msg} = Translate.validate(:banana)
    assert msg =~ "Invalid Translation"
  end
end
