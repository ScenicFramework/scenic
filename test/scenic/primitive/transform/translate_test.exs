#
#  Created by Boyd Multerer on 11/02/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.TranslateTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Translate

  # ============================================================================
  # verify

  test "verify passes valid data" do
    assert Translate.verify({1.0, 2.0}) == true
  end

  test "verify fails invalid data" do
    assert Translate.verify(1.1) == false
    assert Translate.verify({1.1}) == false
    assert Translate.verify({1.1, 1.2, 1.3}) == false
    assert Translate.verify({1.1, :banana}) == false
    assert Translate.verify(:banana) == false
  end
end
