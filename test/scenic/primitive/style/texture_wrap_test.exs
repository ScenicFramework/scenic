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
    assert TextureWrap.verify( :repeat )
    assert TextureWrap.verify( :mirrored_repeat )
    assert TextureWrap.verify( :clamp_to_edge )
    assert TextureWrap.verify( :clamp_to_border )
    assert TextureWrap.verify( {:repeat, :clamp_to_border} )
  end

  test "verify rejects invalid values" do
    refute TextureWrap.verify( :banana )
    refute TextureWrap.verify( {:repeat, :banana} )
  end

  test "verify! works" do
    assert TextureWrap.verify!( :clamp_to_border )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      TextureWrap.verify!( :banana )
    end
    assert_raise Style.FormatError, fn ->
      TextureWrap.verify!( {:repeat, :banana} )
    end
  end

  #============================================================================
  # normalize - various forms


  test "normalize expands single value to a list" do
    assert TextureWrap.normalize( :repeat ) == {:repeat, :repeat}
    assert TextureWrap.normalize( :mirrored_repeat ) == {:mirrored_repeat, :mirrored_repeat}
    assert TextureWrap.normalize( :clamp_to_edge ) == {:clamp_to_edge, :clamp_to_edge}
    assert TextureWrap.normalize( :clamp_to_border ) == {:clamp_to_border, :clamp_to_border}
  end


  test "normalize fills in default values" do
    assert TextureWrap.normalize( nil ) == {:repeat, :repeat}
  end

  test "normalize passes dual values" do
    assert TextureWrap.normalize( {:repeat, :clamp_to_edge} ) == {:repeat, :clamp_to_edge}
  end

  test "normalize rejects invalid values" do
    assert_raise CaseClauseError, fn ->
      TextureWrap.normalize( :banana )
    end
    assert_raise CaseClauseError, fn ->
      TextureWrap.normalize( {:clamp_to_edge, :banana} )
    end
  end
  
end

