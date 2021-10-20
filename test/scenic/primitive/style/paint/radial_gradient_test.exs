defmodule Scenic.Primitive.Style.Paint.RadialGradientTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Paint.RadialGradient

  alias Scenic.Primitive.Style.Paint.RadialGradient

  test "validate accepts valid data & converts colors" do
    assert RadialGradient.validate({:radial, {1.5, 2, 3, 4, :red, :green}}) ==
             {:ok,
              {:radial,
               {1.5, 2, 3, 4, {:color_rgba, {255, 0, 0, 255}}, {:color_rgba, {0, 128, 0, 255}}}}}
  end

  test "validate rejects non-colors" do
    {:error, msg} = RadialGradient.validate({:radial, {1.5, 2, 3, 4, :red, :invalid}})
    assert msg =~ "Invalid Color"
    assert msg =~ ":invalid"
  end

  test "validate rejects bad data" do
    {:error, msg} = RadialGradient.validate("not even close")
    assert msg =~ "specified in the form of"
  end
end
