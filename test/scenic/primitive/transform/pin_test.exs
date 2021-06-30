#
#  Created by Boyd Multerer on 2017-11-02.
#  Copyright © 2017 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Transform.PinTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Transform.Pin

  alias Scenic.Primitive.Transform.Pin


  test "validate accepts valid data" do
    assert Pin.validate({1, 2}) == {:ok, {1, 2}}
    assert Pin.validate({1.5, 2}) == {:ok, {1.5, 2}}
  end

  test "validate rejects bad data" do
    {:error, msg} = Pin.validate({"1.5", 2})
    assert msg =~ "Invalid Pin"

    {:error, msg} = Pin.validate( :banana )
    assert msg =~ "Invalid Pin"
  end

end
