#
#  Created by Boyd Multerer on 2018-06-18.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.JoinTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Join

  alias Scenic.Primitive.Style.Join

  test "validate accepts valid data" do
    assert Join.validate(:miter) == {:ok, :miter}
    assert Join.validate(:round) == {:ok, :round}
    assert Join.validate(:bevel) == {:ok, :bevel}
  end

  test "validate rejects bad data" do
    {:error, msg} = Join.validate(:invalid)
    assert msg =~ "one of :miter, :round, or :bevel"
  end

end
