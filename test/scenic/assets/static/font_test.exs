#
#  Created by Boyd Multerer on 2021-07-05
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Static.FontTest do
  use ExUnit.Case, async: true
  doctest Scenic.Assets.Static.Font

  alias Scenic.Assets.Static.Font

  test "parses a valid font file" do
    bin = File.read!("test/assets/fonts/roboto.ttf")
    {:ok, {Font, %FontMetrics{}}} = Font.parse_meta(bin)
  end

  test "rejects invalid font data" do
    assert Font.parse_meta(<<0, 1, 2, 3, 4, 5, 6>>) == :error
  end
  
end