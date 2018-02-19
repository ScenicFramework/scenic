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
    assert TextureFilter.verify( [mag: :nearest, min: :linear] )
    assert TextureFilter.verify( {:min, :nearest} )
    assert TextureFilter.verify( {:mag, :nearest} )
  end

  test "verify rejects invalid values" do
    refute TextureFilter.verify( :banana )
  end

  test "verify! works" do
    assert TextureFilter.verify!( :linear )
    assert TextureFilter.verify!( :nearest )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      TextureFilter.verify!( :banana )
    end
  end

  #============================================================================
  # normalize - various forms

  test "normalize fills in default values" do
    assert TextureFilter.normalize( nil ) == [min: :linear, mag: :linear]
    assert TextureFilter.normalize( {:min, :nearest} ) == [min: :nearest, mag: :linear]
    assert TextureFilter.normalize( {:mag, :nearest} ) == [min: :linear, mag: :nearest]
    assert TextureFilter.normalize( [{:min, :nearest}] ) == [min: :nearest, mag: :linear]
    assert TextureFilter.normalize( [{:mag, :nearest}] ) == [min: :linear, mag: :nearest]
  end

  test "normalize expands single value to a list" do
    assert TextureFilter.normalize( :linear ) == [min: :linear, mag: :linear]    
    assert TextureFilter.normalize( :nearest ) == [min: :nearest, mag: :nearest]    
  end

  test "normalize passes in valid values" do
    assert TextureFilter.normalize( [mag: :nearest, min: :linear] ) == 
      [min: :linear, mag: :nearest]
  end

  test "normalize rejects invalid values" do
    assert_raise CaseClauseError, fn ->
      TextureFilter.normalize( :banana )
    end
  end

end