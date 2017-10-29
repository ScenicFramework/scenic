#
#  Created by Boyd Multerer on 5/7/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.StyleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style

  @styles %{
      color:  :red,
      fruit:  :bananas,
      hidden: false
    }


  #============================================================================
  # name_to_style
  test "name_to_style works" do
    assert Style.name_to_style( :border_color ) == Style.BorderColor
    assert Style.name_to_style( :color ) ==        Style.Color
    assert Style.name_to_style( :hidden ) ==       Style.Hidden
    assert Style.name_to_style( :line_width ) ==   Style.LineWidth
  end

  #============================================================================
  # get

  test "get gets a style" do
    assert Style.get(@styles, :color) == :red
    assert Style.get(@styles, :fruit) == :bananas
  end

  test "get rejects non-atoms" do
    assert_raise FunctionClauseError, fn ->
      Style.get(@styles, "non-atom")
    end
  end

  test "get returns nil for missing" do
    assert Style.get(@styles, :missing) == nil
  end

  #============================================================================
  # put

  test "put puts a style" do
    assert Style.put(@styles, :color, :green) == %{
      color:  :green,
      fruit:  :bananas,
      hidden: false
    }
  end

  test "put verifies the data" do
    assert_raise Style.FormatError, fn ->
      Style.put(@styles, :color, "not a color")
    end
  end

  test "put rejects non atoms" do
    assert_raise FunctionClauseError, fn ->
      Style.put(@styles, "non-atom", :bananas)
    end
  end

  test "put accepts non-primitive types" do
    assert Style.put(@styles, :vegetables, :carrots) == %{
      color:      :red,
      fruit:      :bananas,
      hidden:     false,
      vegetables: :carrots
    }
  end

  test "put deletes the style if setting to nil" do
    assert Style.put(@styles, :color, nil) == %{
      fruit:  :bananas,
      hidden: false
    }
  end

  #============================================================================
  # primitives

  test "primitives filters a style map to only the primitive types" do
    assert Style.primitives(@styles) == %{
      color: :red,
      hidden: false
    }
  end

end
