defmodule Scenic.Primitive.Style.Paint.ImageTest do
  use ExUnit.Case, async: true

  alias Scenic.Primitive.Style.Paint.Image

  test "normalize works with just a hash_key to the image" do
    assert Image.normalize("hash_string") == {"hash_string", 0, 0, 0, 0, 0, 0xFF}
  end

  test "normalize works with just a hash_key and alpha" do
    assert Image.normalize({"hash_string", 128}) == {"hash_string", 0, 0, 0, 0, 0, 128}
  end

  test "normalize works with everything set" do
    assert Image.normalize({"hash_string", 1, 2, 3, 4, 5, 6}) ==
      {"hash_string", 1, 2, 3, 4, 5, 6}
  end

end