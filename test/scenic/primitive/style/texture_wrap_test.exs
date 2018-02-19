#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextureWrapTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.TextureWrap


  #============================================================================
  # verify - various forms

  test "verfy works" do
    assert TextureWrap.verify( nil )
    assert TextureWrap.verify( :clamp_to_border )
    assert TextureWrap.verify( [v: :mirrored_repeat, h: :clamp_to_border] )
    assert TextureWrap.verify( {:h, :mirrored_repeat} )
    assert TextureWrap.verify( {:v, :mirrored_repeat} )
  end

  test "verify rejects invalid values" do
    refute TextureWrap.verify( :banana )
  end

  test "verify! works" do
    assert TextureWrap.verify!( :clamp_to_border )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      TextureWrap.verify!( :banana )
    end
  end

  #============================================================================
  # normalize - various forms

  test "normalize fills in default values" do
    assert TextureWrap.normalize( nil ) == [h: :repeat, v: :repeat]
    assert TextureWrap.normalize( {:h, :mirrored_repeat} ) == [h: :mirrored_repeat, v: :repeat]
    assert TextureWrap.normalize( {:v, :mirrored_repeat} ) == [h: :repeat, v: :mirrored_repeat]
    assert TextureWrap.normalize( [{:h, :mirrored_repeat}] ) == [h: :mirrored_repeat, v: :repeat]
    assert TextureWrap.normalize( [{:v, :mirrored_repeat}] ) == [h: :repeat, v: :mirrored_repeat]
  end

  test "normalize expands single value to a list" do
    assert TextureWrap.normalize( :mirrored_repeat ) == [h: :mirrored_repeat, v: :mirrored_repeat]    
  end

  test "normalize passes in valid values" do
    assert TextureWrap.normalize( [v: :mirrored_repeat, h: :repeat] ) == 
      [h: :repeat, v: :mirrored_repeat]
    assert TextureWrap.normalize( [v: :clamp_to_edge, h: :clamp_to_border] ) == 
      [h: :clamp_to_border, v: :clamp_to_edge]
  end

  test "normalize rejects invalid values" do
    assert_raise CaseClauseError, fn ->
      TextureWrap.normalize( :banana )
    end
  end

end

