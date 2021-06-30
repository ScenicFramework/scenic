#
#  Created by Boyd Multerer on 2018-06-18.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextAlignTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.TextAlign

  alias Scenic.Primitive.Style.TextAlign

  test "validate accepts valid data" do
    assert TextAlign.validate(:left) == {:ok, :left}
    assert TextAlign.validate(:right) == {:ok, :right}
    assert TextAlign.validate(:center) == {:ok, :center}
  end

  test "validate rejects bad data" do
    {:error, msg} = TextAlign.validate(:invalid)
    assert msg =~ "one of :left, :center, or :right"
  end
end
