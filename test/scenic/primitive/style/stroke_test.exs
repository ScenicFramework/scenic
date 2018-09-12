#
#  Created by Boyd Multerer on June 18, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.StrokeTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Stroke

  # ============================================================================
  # verify - various forms

  test "verfy accepts width and a single color" do
    assert Stroke.verify({4, :red})
    assert Stroke.verify({4, {:red, 128}})
    assert Stroke.verify({4, {1, 2, 3}})
    assert Stroke.verify({4, {1, 2, 3, 4}})

    assert Stroke.verify({4, {:color, :red}})
    assert Stroke.verify({4, {:color, {:red, 128}}})
  end

  test "verfy accepts a linear gradient" do
    assert Stroke.verify({4, {:linear, {0, 0, 160, 100, :yellow, :purple}}})
  end

  test "verfy accepts a box gradient" do
    assert Stroke.verify({4, {:box, {0, 0, 160, 100, 100, 20, :yellow, :purple}}})
  end

  test "verfy accepts a radial gradient" do
    assert Stroke.verify({4, {:radial, {80, 50, 20, 60, {:yellow, 128}, {:purple, 128}}}})
  end

  test "verify rejects invalid values" do
    refute Stroke.verify({4, :not_a_color})
    refute Stroke.verify({"4", :red})
  end

  test "verify! works" do
    assert Stroke.verify!({4, :red})
    assert Stroke.verify!({4, {:color, :red}})
    assert Stroke.verify!({4, {:linear, {0, 0, 160, 100, :yellow, :purple}}})
    assert Stroke.verify!({4, {:box, {0, 0, 160, 100, 100, 20, :yellow, :purple}}})
    assert Stroke.verify!({4, {:radial, {80, 50, 20, 60, {:yellow, 128}, {:purple, 128}}}})
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      Stroke.verify!({4, "red"})
    end
  end

  # ============================================================================
  # normalize - various forms

  test "normalize works" do
    assert Stroke.normalize({4, :red}) == {4, {:color, {255, 0, 0, 255}}}

    assert Stroke.normalize({4, {:linear, {0, 0, 160, 100, :yellow, :purple}}}) ==
             {4, {:linear, {0, 0, 160, 100, {255, 255, 0, 255}, {128, 0, 128, 255}}}}

    assert Stroke.normalize({4, {:box, {0, 0, 160, 100, 100, 20, :yellow, :purple}}}) ==
             {4, {:box, {0, 0, 160, 100, 100, 20, {255, 255, 0, 255}, {128, 0, 128, 255}}}}

    assert Stroke.normalize({4, {:radial, {80, 50, 20, 60, :yellow, :purple}}}) ==
             {4, {:radial, {80, 50, 20, 60, {255, 255, 0, 255}, {128, 0, 128, 255}}}}
  end
end
