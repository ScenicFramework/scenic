#
#  Created by Boyd Multerer on 2017-05-12.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Font

  alias Scenic.Primitive.Style.Font

  test "validate accepts font asset aliases" do
    assert Font.validate(:test_roboto) == {:ok, "fonts/roboto.ttf"}
  end

  test "validate accepts font` asset paths" do
    assert Font.validate("fonts/roboto.ttf") == {:ok, "fonts/roboto.ttf"}
  end

  test "validate rejects image assets" do
    {:error, msg} = Font.validate(:test_parrot)
    assert msg =~ "image"
  end

  test "validate rejects unmapped aliases" do
    {:error, msg} = Font.validate(:invalid)
    assert msg =~ "not mapped"
  end

  test "validate rejects missing assets" do
    {:error, msg} = Font.validate("fonts/missing.ttf")
    assert msg =~ "could not be found"
  end

  test "validate rejects bad data" do
    {:error, msg} = Font.validate("totally wrong")
    assert msg =~ ":font style must be an id that names an font"
  end

end
