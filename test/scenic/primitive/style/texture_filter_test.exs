#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextureFilterTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.TextureFilter


  #============================================================================
  # verify - various forms

  test "verfy works" do
    assert TextureFilter.verify( nil )
    assert TextureFilter.verify( :nearest )
    assert TextureFilter.verify( :linear )
    assert TextureFilter.verify( {:nearest, :linear} )
  end

  test "verify rejects invalid values" do
    refute TextureFilter.verify( :banana )
  end

  test "verify! works" do
    assert TextureFilter.verify!( :linear )
    assert TextureFilter.verify!( :nearest )
    assert TextureFilter.verify!( {:nearest, :linear} )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      TextureFilter.verify!( :banana )
    end
    assert_raise Style.FormatError, fn ->
      TextureFilter.verify!( {:nearest, :banana} )
    end
  end

  #============================================================================
  # normalize - various forms

  test "normalize expands single value to a list" do
    assert TextureFilter.normalize( :linear ) == {:linear, :linear}
    assert TextureFilter.normalize( :nearest ) == {:nearest, :nearest}
  end


  test "normalize fills in default values" do
    assert TextureFilter.normalize( nil ) == {:linear, :linear}
  end

  test "normalize passes dual values" do
    assert TextureFilter.normalize( {:nearest, :linear} ) == {:nearest, :linear}
  end

  test "normalize rejects invalid values" do
    assert_raise CaseClauseError, fn ->
      TextureFilter.normalize( :banana )
    end
    assert_raise CaseClauseError, fn ->
      TextureFilter.normalize( {:nearest, :banana} )
    end
  end

end