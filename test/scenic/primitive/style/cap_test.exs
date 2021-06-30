#
#  Created by Boyd Multerer on 2018-06-18.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.CapTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Cap

  alias Scenic.Primitive.Style.Cap

  test "validate accepts valid data" do
    assert Cap.validate(:butt) == {:ok, :butt}
    assert Cap.validate(:round) == {:ok, :round}
    assert Cap.validate(:square) == {:ok, :square}
  end

  test "validate rejects bad data" do
    {:error, msg} = Cap.validate(:invalid)
    assert msg =~ "one of :butt, :round, or :square"
  end

end
