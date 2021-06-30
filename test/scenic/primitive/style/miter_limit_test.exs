#
#  Created by Boyd Multerer on 2017-05-12.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.MiterLimitTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.MiterLimit

  alias Scenic.Primitive.Style.MiterLimit

  test "validate accepts valid data" do
    assert MiterLimit.validate(12) == {:ok, 12}
    assert MiterLimit.validate(16.5) == {:ok, 16.5}
  end

  test "validate rejects negative numbers" do
    {:error, msg} = MiterLimit.validate(-12)
    assert msg =~ "must be a positive number"
  end

  test "validate rejects invalid data" do
    {:error, msg} = MiterLimit.validate("way off")
    assert msg =~ "must be a positive number"
  end

end
