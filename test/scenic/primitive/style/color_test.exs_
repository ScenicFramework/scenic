#
#  Created by Boyd Multerer on 5/7/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.ColorTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Color


  #============================================================================
  # verify - various forms

  test "verfy works for a single color" do
    assert Color.verify( :red )
    assert Color.verify( {:red} )
    assert Color.verify( {:red, 128} )
    assert Color.verify( {{:red, 128}} )
    assert Color.verify( {1,2,3} )
    assert Color.verify( {{1,2,3}} )
    assert Color.verify( {1,2,3,4} )
    assert Color.verify( {{1,2,3,4}} )
  end

  test "verfy works for multiple colors" do
    assert Color.verify( {:red, :green} )
    assert Color.verify( {:red, :green, :khaki} )
    assert Color.verify( {:red, :green, :crimson, :khaki} )
    assert Color.verify( {:red, {:green, 128}, {1,2,3}, {1,2,3,4}} )
  end

  test "verify rejects negative channels" do
    refute Color.verify( {{:red, -1}} )
    refute Color.verify( {{-1,2,3,4}} )
    refute Color.verify( {{1,-2,3,4}} )
    refute Color.verify( {{1,2,-3,4}} )
    refute Color.verify( {{1,2,3,-4}} )
  end

  test "verify rejects out of bounds channels" do
    refute Color.verify( {:red, 256} )
    refute Color.verify( {256,2,3,4} )
    refute Color.verify( {1,256,3,4} )
    refute Color.verify( {1,2,256,4} )
    refute Color.verify( {1,2,3,256} )
  end

  test "verify! works" do
    assert Color.verify!( :red )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      Color.verify!( {{:red, -1}} )
    end
  end

  #============================================================================
  # normalize - various forms

  test "normalize works for a single color" do
    assert Color.normalize( :red )            == {{255, 0, 0, 255}}
    assert Color.normalize( {:red} )          == {{255, 0, 0, 255}}
    assert Color.normalize( {:red, 128} )     == {{255, 0, 0, 128}}
    assert Color.normalize( {{:red, 128}} )   == {{255, 0, 0, 128}}
    assert Color.normalize( {1,2,3} )         == {{1, 2, 3, 255}}
    assert Color.normalize( {{1,2,3}} )       == {{1, 2, 3, 255}}
    assert Color.normalize( {1,2,3,4} )       == {{1, 2, 3, 4}}
    assert Color.normalize( {{1,2,3,4}} )     == {{1, 2, 3, 4}}
  end

  test "normalize works for multiple colors" do
    assert Color.normalize( {:red, {:green, 129}} ) ==
      {{255, 0, 0, 255}, {0, 128, 0, 129}}

    assert Color.normalize( {:red, {:green, 129}, {1,2,3}} ) ==
      {{255, 0, 0, 255}, {0, 128, 0, 129}, {1,2,3,255}}

    assert Color.normalize( {:red, {:green, 129}, {1,2,3}, {1,2,3,4}} ) ==
      {{255, 0, 0, 255}, {0, 128, 0, 129}, {1,2,3,255}, {1,2,3,4}}
  end


  #============================================================================
  # to_rgba various forms

  test "to_rgba assumes opaque for three-tuple colors" do
    assert Color.to_rgba( {1, 2, 3} ) == {1, 2, 3, 0xff}
  end

  test "to_rgba returns already tupled colors unchanged" do
    assert Color.to_rgba( {1, 2, 3, 4} ) == {1, 2, 3, 4}
  end

  test "to_rgba maps a named color - default alpha of 0xFF" do
    assert Color.to_rgba( :crimson ) == {0xDC, 0x14, 0x3C, 0xFF}
  end

  test "to_rgba maps {named_color, alpha}" do
    assert Color.to_rgba( {:crimson, 128} ) == {0xDC, 0x14, 0x3C, 128}
  end

  test "to_rgba maps binary to components" do
    assert Color.to_rgba( <<0xDC, 0x14, 0x3C, 128>> ) == {0xDC, 0x14, 0x3C, 128}
  end



end


