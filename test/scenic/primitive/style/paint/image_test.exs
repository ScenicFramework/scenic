defmodule Scenic.Primitive.Style.Paint.ImageTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Paint.Image

  alias Scenic.Primitive.Style.Paint.Image

  test "validate accepts image asset aliases" do
    assert Image.validate({:image, :test_parrot}) == {:ok, {:image, "images/parrot.png"}}
  end

  test "validate accepts image asset paths" do
    assert Image.validate({:image, "images/parrot.png"}) == {:ok, {:image, "images/parrot.png"}}
  end

  test "validate rejects font assets" do
    {:error, msg} = Image.validate({:image, :test_roboto})
    assert msg =~ "font"
  end

  test "validate rejects unmapped aliases" do
    {:error, msg} = Image.validate({:image, :invalid})
    assert msg =~ "not mapped"
  end

  test "validate rejects missing assets" do
    {:error, msg} = Image.validate({:image, "images/missing.jpg"})
    assert msg =~ "could not be found"
  end

  test "validate rejects bad data" do
    {:error, msg} = Image.validate("totally wrong")
    assert msg =~ "Valid image ids can be"
    assert msg =~ "Examples:"
  end
end
