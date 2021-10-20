#
#  Created by Boyd Multerer on 2021-04-19
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Stream.ImageTest do
  use ExUnit.Case, async: true
  doctest Scenic.Assets.Stream.Image

  alias Scenic.Assets.Static
  alias Scenic.Assets.Stream.Image

  test "from_binary works" do
    # use the parrot from the static assets as the input...
    {:ok, bin} = Static.load(:parrot)
    {:ok, {Image, {62, 114, "image/png"}, b}} = Image.from_binary(bin)
    assert b == bin
  end

  test "from_binary rejects non-image binary data" do
    assert Image.from_binary(<<0, 1, 2, 3, 4, 5, 6>>) == {:error, :invalid}
  end
end
