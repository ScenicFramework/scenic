#
#  Created by Boyd Multerer on 2017-05-12.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontSizeTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.FontSize

  alias Scenic.Primitive.Style.FontSize

  test "validate accepts valid data" do
    assert FontSize.validate(12) == {:ok, 12}
    assert FontSize.validate(16.5) == {:ok, 16.5}
  end

  test "validate rejects negative numbers" do
    {:error, msg} = FontSize.validate(-12)
    assert msg =~ "must be a positive number"
  end

  test "validate rejects invalid data" do
    {:error, msg} = FontSize.validate("way off")
    assert msg =~ "must be a positive number"
  end
end
