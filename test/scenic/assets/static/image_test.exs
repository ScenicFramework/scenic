#
#  Created by Boyd Multerer on 2021-07-05
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Static.ImageTest do
  use ExUnit.Case, async: true
  doctest Scenic.Assets.Static.Image

  alias Scenic.Assets.Static.Image

  test "parses a valid font file" do
    bin = File.read!("test/assets/images/parrot.png")
    {:ok, {Image, {62, 114, "image/png"}}} = Image.parse_meta(bin)
  end

  test "rejects invalid image data" do
    assert Image.parse_meta(<<0, 1, 2, 3, 4, 5, 6>>) == :error
  end
end
