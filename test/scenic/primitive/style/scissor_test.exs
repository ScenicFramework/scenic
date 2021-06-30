#
#  Created by Boyd Multerer on 2018-06-18.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.ScissorTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Scissor

  alias Scenic.Primitive.Style.Scissor

  test "validate accepts valid data" do
    assert Scissor.validate({10, 20}) == {:ok, {10, 20}}
  end

  test "validate rejects invalid data" do
    {:error, msg} = Scissor.validate("way off")
    assert msg =~ "must be {width, height}"
  end

end
