#
#  Created by Boyd Multerer on 2018-02-20.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.LineHeightTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.LineHeight

  alias Scenic.Primitive.Style.LineHeight

  test "validate accepts valid data" do
    assert LineHeight.validate(0) == {:ok, 0}
    assert LineHeight.validate(12) == {:ok, 12}
    assert LineHeight.validate(-12) == {:ok, -12}
    assert LineHeight.validate(16.5) == {:ok, 16.5}
  end

  test "validate rejects invalid data" do
    {:error, msg} = LineHeight.validate("way off")
    assert msg =~ "must be a positive number"
  end

end
