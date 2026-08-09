defmodule Scenic.ViewPortScissorStackTest do
  use ExUnit.Case, async: true

  alias Scenic.Math.Matrix

  test "all ancestor scissors participate in effective clipping" do
    parent = {Matrix.identity(), 100, 100}
    child = {Matrix.translate(Matrix.identity(), {20, 20}), 30, 30}

    refute Scenic.ViewPort.point_clipped?([child, parent], {25, 25}, Matrix.identity())
    assert Scenic.ViewPort.point_clipped?([child, parent], {10, 10}, Matrix.identity())
    assert Scenic.ViewPort.point_clipped?([child, parent], {110, 25}, Matrix.identity())
  end
end
