#
#  Created by Boyd Multerer on 2018-06-18.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.FillTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Fill

  alias Scenic.Primitive.Style.Fill

  test "validate accepts color paint" do
    assert Fill.validate({:color, :red}) == {:ok, {:color, {:color_rgba, {255, 0, 0, 255}}}}
    assert Fill.validate(:red) == {:ok, {:color, {:color_rgba, {255, 0, 0, 255}}}}
  end

  test "validate accepts streaming paint" do
    assert Fill.validate({:stream, "tex"}) == {:ok, {:stream, "tex"}}
  end

  test "validate accepts image paint" do
    assert Fill.validate({:image, :test_parrot}) == {:ok, {:image, "images/parrot.png"}}
  end

  test "validate accepts linear graient paint" do
    assert Fill.validate({:linear, {1,2,3,4,:red,:green}}) ==
      {:ok, {:linear, {1, 2, 3, 4, {:color_rgba, {255, 0, 0, 255}}, {:color_rgba, {0, 128, 0, 255}}}}}
  end

  test "validate accepts radial graient paint" do
    assert Fill.validate({:radial, {1,2,3,4,:red,:green}}) ==
      {:ok, {:radial, {1, 2, 3, 4, {:color_rgba, {255, 0, 0, 255}}, {:color_rgba, {0, 128, 0, 255}}}}}
  end

  test "validate rejects bad data" do
    {:error, msg} = Fill.validate(:invalid)
    assert msg =~ "must be a valid paint"
  end

end
