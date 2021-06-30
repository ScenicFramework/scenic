#
#  Created by Boyd Multerer on 2032-03-02.
#  Copyright © 2021-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.InputTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Input

  alias Scenic.Primitive.Style.Input

  test "validate accepts valid data" do
    assert Input.validate(true) == {:ok, true}
    assert Input.validate(false) == {:ok, false}
  end

  test "validate rejects invalid data" do
    {:error, msg} = Input.validate("way off")
    assert msg =~ "true or false"
  end
end
