defmodule Scenic.Primitive.Style.Paint.ColorTest do
  @moduledoc false
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Paint.Color

  alias Scenic.Primitive.Style.Paint.Color

  test "validate({:color, color}) validates into rgba colors" do
    assert Color.validate({:color, :red}) == {:ok, {:color, {:color_rgba, {0xFF, 0x00, 0x00, 0xFF}}}}
  end

  test "validate({:color, color}) rejects bad colors" do
    {:error, err_str} = Color.validate({:color, :invalid})
    assert is_bitstring(err_str)
  end

  test "validate(color) works" do
    assert Color.validate(:red) == {:ok, {:color_rgba, {0xFF, 0x00, 0x00, 0xFF}} }
  end

  test "validate(color) rejects bad colors" do
    {:error, err_str} = Color.validate(:invalid)
    assert is_bitstring(err_str)
  end

end
