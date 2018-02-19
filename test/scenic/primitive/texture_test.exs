#
#  Created by Boyd Multerer on 2/18/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.TextureTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive
  alias Scenic.Primitive.Texture


  @data     {{100,300},{300,180},{400,310},{300,520}, "abcdefg"}


  #============================================================================
  # build / add

  test "build works" do
    p = Texture.build( @data )
    assert Primitive.get_parent_uid(p) == -1
    assert Primitive.get_module(p) == Texture
    assert Primitive.get(p) == @data
  end


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Texture.verify( @data ) == {:ok, @data}
  end

  test "verify fails invalid data" do
    assert Texture.verify( {{100,300},{300,180},{400,310},{300,520}, :abcdefg} ) == :invalid_data
    assert Texture.verify( {{100,300},{300,180},{400,310}, "abcdefg"} ) == :invalid_data
    assert Texture.verify( :banana ) == :invalid_data
  end

  #============================================================================
  # styles

  test "valid_styles works" do
    assert Texture.valid_styles() == [:hidden, :color, :border_color, :border_width,
      :texture_wrap, :texture_filter]
  end

  #============================================================================
  # transform helpers

  test "default_pin returns the center of the rect" do
    assert Texture.default_pin(@data) == {275, 328}
  end

  test "expand expands the data" do
    {{{x0,y0},{x1,y1},{x2,y2},{x3,y3}}, _, _} = Texture.expand(@data, 10)

    # rounding to avoid floating-point errors from messing up the tests
    assert {
      {round(x0), round(y0)},
      {round(x1), round(y1)},
      {round(x2), round(y2)},
      {round(x3), round(y3)}
    } ==   {{84, 298}, {302, 167}, {412, 309}, {303, 538}}
  end

  #============================================================================
  # point containment
  test "contains_point? returns true if it contains the point" do
    assert Texture.contains_point?(@data, {101, 300})  == true
    assert Texture.contains_point?(@data, {300,181})   == true
    assert Texture.contains_point?(@data, {399,310})   == true
    assert Texture.contains_point?(@data, {300,519})   == true
  end

end

