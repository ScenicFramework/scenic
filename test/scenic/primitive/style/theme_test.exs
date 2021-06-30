#
#  Created by Boyd Multerer on 2018-09-25.
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.ThemeTest do
  use ExUnit.Case, async: true
  doctest Scenic.Primitive.Style.Theme

  alias Scenic.Primitive.Style.Theme

  test "validate accepts the named themes" do
    assert Theme.validate(:dark) == {:ok, :dark}
    assert Theme.validate(:light) == {:ok, :light}
    assert Theme.validate(:primary) == {:ok, :primary}
    assert Theme.validate(:secondary) == {:ok, :secondary}
    assert Theme.validate(:success) == {:ok, :success}
    assert Theme.validate(:danger) == {:ok, :danger}
    assert Theme.validate(:warning) == {:ok, :warning}
    assert Theme.validate(:info) == {:ok, :info}
    assert Theme.validate(:text) == {:ok, :text}
  end

  test "validate rejects invalid theme names" do
    {:error, msg} = Theme.validate(:invalid)
    assert msg =~ "Named themes must be from the following list"
  end

  test "validate accepts maps of colors" do
    color_map = %{
      text: :red,
      background: :green,
      border: :blue,
      active: :magenta,
      thumb: :cyan,
      focus: :yellow,
      my_color: :black
    }
    assert Theme.validate(color_map) == {:ok, color_map}
  end

  test "validate rejects maps with invalid colors" do
    color_map = %{
      text: :red,
      background: :green,
      border: :invalid,
      active: :magenta,
      thumb: :cyan,
      focus: :yellow,
      my_color: :black
    }
    {:error, msg} = Theme.validate(color_map)
    assert msg =~ "Map entry: :border"
    assert msg =~ "Invalid Color specification: :invalid"
  end

  test "verify rejects maps without the standard colors" do
    color_map = %{some_name: :red}
    {:error, msg} = Theme.validate(color_map)
    assert msg =~ "didn't include all the required color"
  end

  test "verify rejects  invalid values" do
    {:error, _msg} = Theme.validate("totally wrong")
  end

end
