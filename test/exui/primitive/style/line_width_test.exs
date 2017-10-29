#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.LineWidthTest do
  use ExUnit.Case, async: true
  doctest Exui

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.LineWidth

#  @dflag_bling      2
#  @type_code        0x0020



  #============================================================================
  # verify - various forms

  test "verfy works for a single color" do
    assert LineWidth.verify( 10 )
    assert LineWidth.verify( 0 )
    assert LineWidth.verify( 255 )
  end

  test "verify rejects out of bounds values" do
    refute LineWidth.verify( -1 )
    refute LineWidth.verify( 256 )
  end

  test "verify! works" do
    assert LineWidth.verify!( 10 )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      LineWidth.verify!( "banana" )
    end
  end

  #============================================================================
  # serialize
  
  test "serialize works" do
    assert LineWidth.serialize( 8 )       == <<8>>
    assert LineWidth.serialize( 255 )     == <<255>>
  end

  #============================================================================
  # deserialize
  
  test "deserialize works" do
    assert LineWidth.deserialize( <<7, 2, 3>> )    == {:ok, 7, <<2, 3>>}
  end




end


