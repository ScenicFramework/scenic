#
#  Created by Boyd Multerer on 2018-06-18.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.StrokeTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Stroke

  alias Scenic.Primitive.Style.Stroke

  test "validate accepts color paint" do
    assert Stroke.validate({1, :red}) == {:ok, {1, {:color, {:color_rgba, {255, 0, 0, 255}}}}}

    assert Stroke.validate({1.5, {:color, :red}}) ==
             {:ok, {1.5, {:color, {:color_rgba, {255, 0, 0, 255}}}}}
  end

  test "validate accepts streaming paint" do
    assert Stroke.validate({1, {:stream, "tex"}}) == {:ok, {1, {:stream, "tex"}}}
  end

  test "validate accepts image paint" do
    assert Stroke.validate({1, {:image, :test_parrot}}) ==
             {:ok, {1, {:image, "images/parrot.png"}}}
  end

  test "validate accepts linear graient paint" do
    assert Stroke.validate({1, {:linear, {1, 2, 3, 4, :red, :green}}}) ==
             {:ok,
              {1,
               {:linear,
                {1, 2, 3, 4, {:color_rgba, {255, 0, 0, 255}}, {:color_rgba, {0, 128, 0, 255}}}}}}
  end

  test "validate accepts radial graient paint" do
    assert Stroke.validate({1, {:radial, {1, 2, 3, 4, :red, :green}}}) ==
             {:ok,
              {1,
               {:radial,
                {1, 2, 3, 4, {:color_rgba, {255, 0, 0, 255}}, {:color_rgba, {0, 128, 0, 255}}}}}}
  end

  test "validate rejects invalid colors" do
    {:error, _} = assert Stroke.validate({1, :invalid})
    {:error, _} = assert Stroke.validate({1, {:color, :invalid}})
  end

  test "validate rejects invalid colors in linear gradient" do
    {:error, _} = assert Stroke.validate({1, {:linear, {1, 2, 3, 4, :red, :invalid}}})
  end

  test "validate rejects invalid colors in radial gradient" do
    {:error, _} = assert Stroke.validate({1, {:radial, {1, 2, 3, 4, :red, :invalid}}})
  end

  test "validate negative width" do
    {:error, msg} = Stroke.validate({-1, :red})
    assert msg =~ "positive"
  end

  test "validate rejects bad data" do
    {:error, msg} = Stroke.validate(:invalid)
    assert msg =~ "positive"
  end
end
