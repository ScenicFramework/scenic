#
#  Created by Boyd Multerer on 2017-05-12.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.HiddenTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Hidden

  alias Scenic.Primitive.Style.Hidden

  test "validate accepts valid data" do
    assert Hidden.validate(true) == {:ok, true}
    assert Hidden.validate(false) == {:ok, false}
  end

  test "validate rejects invalid data" do
    {:error, msg} = Hidden.validate("way off")
    assert msg =~ "true or false"
  end
end
