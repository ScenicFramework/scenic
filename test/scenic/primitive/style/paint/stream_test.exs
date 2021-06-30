defmodule Scenic.Primitive.Style.Paint.StreamTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Paint.Stream

  alias Scenic.Primitive.Style.Paint.Stream

  # --------------------------------------------------------

  test "validate accepts texture names" do
    assert Stream.validate({:stream, "tex"}) == {:ok, {:stream, "tex"}}
  end

  test "validate rejects bad data" do
    {:error, err_str} = Stream.validate({:stream, :invalid})
    assert is_bitstring(err_str)
  end

end
