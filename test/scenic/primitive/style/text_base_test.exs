#
#  Created by Boyd Multerer on 2021-02-05.
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextBaseTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.TextBase

  alias Scenic.Primitive.Style.TextBase

  test "validate accepts valid data" do
    assert TextBase.validate(:top) == {:ok, :top}
    assert TextBase.validate(:middle) == {:ok, :middle}
    assert TextBase.validate(:alphabetic) == {:ok, :alphabetic}
    assert TextBase.validate(:bottom) == {:ok, :bottom}
  end

  test "validate rejects bad data" do
    {:error, msg} = TextBase.validate(:invalid)
    assert msg =~ "one of :top, :middle, :alphabetic, or :bottom"
  end
end
