#
#  Created by Boyd Multerer on 2032-03-02.
#  Copyright © 2021-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.InputTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Input

  alias Scenic.Primitive.Style.Input

  test "validate accepts single input types" do
    Scenic.ViewPort.Input.positional_inputs()
    |> Enum.each( &assert(Input.validate(&1) == {:ok, [&1]}) )
  end

  test "validate accepts lists of positional input types" do
    assert Input.validate([:cursor_button, :cursor_pos]) == {:ok, [:cursor_button, :cursor_pos]}
    assert Input.validate([:cursor_button, :cursor_scroll]) == {:ok, [:cursor_button, :cursor_scroll]}
    assert Input.validate([:cursor_pos, :cursor_scroll]) == {:ok, [:cursor_pos, :cursor_scroll]}
    assert Input.validate([:cursor_button, :cursor_scroll, :cursor_pos]) == {:ok, [:cursor_button, :cursor_scroll, :cursor_pos]}
  end

  test "validate rejects invalid data" do
    {:error, msg} = Input.validate("way off")
    assert msg =~ inspect(Scenic.ViewPort.Input.positional_inputs())
  end
end
