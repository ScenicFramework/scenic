#
#  Created by Boyd Multerer on 2018-06-18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.FillTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Fill

  test "info works" do
    assert Fill.info(:test_data) =~ ":test_data"
  end

  # ============================================================================
  # verify - various forms

  test "verfy accepts a single color" do
    assert Fill.verify(:red)
    assert Fill.verify({:red, 128})
    assert Fill.verify({1, 2, 3})
    assert Fill.verify({1, 2, 3, 4})

    assert Fill.verify({:color, :red})
    assert Fill.verify({:color, {:red, 128}})
  end

  test "verfy accepts a linear gradient" do
    assert Fill.verify({:linear, {0, 0, 160, 100, :yellow, :purple}})
  end

  test "verfy accepts a box gradient" do
    assert Fill.verify({:box, {0, 0, 160, 100, 100, 20, :yellow, :purple}})
  end

  test "verfy accepts a radial gradient" do
    assert Fill.verify({:radial, {80, 50, 20, 60, {:yellow, 128}, {:purple, 128}}})
  end

  test "verify rejects invalid values" do
    refute Fill.verify(:not_a_color)
  end

  test "verify! works" do
    assert Fill.verify!(:red)
    assert Fill.verify!({:red, 128})
    assert Fill.verify!({1, 2, 3})
    assert Fill.verify!({1, 2, 3, 4})
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      Fill.verify!("red")
    end
  end

  # ============================================================================
  # normalize - various forms

  test "normalize works on single color" do
    assert Fill.normalize(:red) == {:color, {255, 0, 0, 255}}
    assert Fill.normalize({:red, 128}) == {:color, {255, 0, 0, 128}}
    assert Fill.normalize({1, 2, 3}) == {:color, {1, 2, 3, 255}}
    assert Fill.normalize({1, 2, 3, 4}) == {:color, {1, 2, 3, 4}}
  end

  test "normalize works on linear gradient" do
    assert Fill.normalize({:linear, {0, 0, 160, 100, :yellow, :purple}}) ==
             {:linear, {0, 0, 160, 100, {255, 255, 0, 255}, {128, 0, 128, 255}}}
  end

  test "normalize works on box gradient" do
    assert Fill.normalize({:box, {0, 0, 160, 100, 100, 20, :yellow, :purple}}) ==
             {:box, {0, 0, 160, 100, 100, 20, {255, 255, 0, 255}, {128, 0, 128, 255}}}
  end

  test "normalize works on radial gradient" do
    assert Fill.normalize({:radial, {80, 50, 20, 60, {:yellow, 128}, {:purple, 128}}}) ==
             {:radial, {80, 50, 20, 60, {255, 255, 0, 128}, {128, 0, 128, 128}}}
  end
end
