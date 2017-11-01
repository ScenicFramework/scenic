#
#  Created by Boyd Multerer on 11/01/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.ClearColorTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.ClearColor


  #============================================================================
  # verify - various forms

  test "verfy works for a single color" do
    assert ClearColor.verify( :red )
    assert ClearColor.verify( {:red} )
    assert ClearColor.verify( {:red, 128} )
    assert ClearColor.verify( {{:red, 128}} )
    assert ClearColor.verify( {1,2,3} )
    assert ClearColor.verify( {{1,2,3}} )
    assert ClearColor.verify( {1,2,3,4} )
    assert ClearColor.verify( {{1,2,3,4}} )
  end

  test "verify rejects negative channels" do
    refute ClearColor.verify( {{:red, -1}} )
    refute ClearColor.verify( {{-1,2,3,4}} )
    refute ClearColor.verify( {{1,-2,3,4}} )
    refute ClearColor.verify( {{1,2,-3,4}} )
    refute ClearColor.verify( {{1,2,3,-4}} )
  end

  test "verify rejects out of bounds channels" do
    refute ClearColor.verify( {:red, 256} )
    refute ClearColor.verify( {256,2,3,4} )
    refute ClearColor.verify( {1,256,3,4} )
    refute ClearColor.verify( {1,2,256,4} )
    refute ClearColor.verify( {1,2,3,256} )
  end

  test "verfy rejects multiple colors" do
    refute ClearColor.verify( {:red, :green} )
    refute ClearColor.verify( {:red, :green, :khaki} )
    refute ClearColor.verify( {:red, :green, :crimson, :khaki} )
    refute ClearColor.verify( {:red, {:green, 128}, {1,2,3}, {1,2,3,4}} )
  end

  test "verify! works" do
    assert ClearColor.verify!( :red )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      ClearColor.verify!( {{:red, -1}} )
    end
  end

  #============================================================================
  # normalize - various forms

  test "normalize works for a single color" do
    assert ClearColor.normalize( :red )            == {{255, 0, 0, 255}}
    assert ClearColor.normalize( {:red} )          == {{255, 0, 0, 255}}
    assert ClearColor.normalize( {:red, 128} )     == {{255, 0, 0, 128}}
    assert ClearColor.normalize( {{:red, 128}} )   == {{255, 0, 0, 128}}
    assert ClearColor.normalize( {1,2,3} )         == {{1, 2, 3, 255}}
    assert ClearColor.normalize( {{1,2,3}} )       == {{1, 2, 3, 255}}
    assert ClearColor.normalize( {1,2,3,4} )       == {{1, 2, 3, 4}}
    assert ClearColor.normalize( {{1,2,3,4}} )     == {{1, 2, 3, 4}}
  end

  #============================================================================
  # serialize - various forms
  
  test "serialize works for a single color" do
    assert ClearColor.serialize( :red )            == <<1, 255, 0, 0, 255>>
    assert ClearColor.serialize( {:red} )          == <<1, 255, 0, 0, 255>>
    assert ClearColor.serialize( {:red, 128} )     == <<1, 255, 0, 0, 128>>
    assert ClearColor.serialize( {{:red, 128}} )   == <<1, 255, 0, 0, 128>>
    assert ClearColor.serialize( {1,2,3} )         == <<1, 1, 2, 3, 255>>
    assert ClearColor.serialize( {{1,2,3}} )       == <<1, 1, 2, 3, 255>>
    assert ClearColor.serialize( {1,2,3,4} )       == <<1, 1, 2, 3, 4>>
    assert ClearColor.serialize( {{1,2,3,4}} )     == <<1, 1, 2, 3, 4>>
  end

  #============================================================================
  # serialize - various forms
  
  test "serialize works" do
    assert ClearColor.serialize( :red )            == <<1, 255, 0, 0, 255>>
    assert ClearColor.serialize( {:red} )          == <<1, 255, 0, 0, 255>>
    assert ClearColor.serialize( {:red, 128} )     == <<1, 255, 0, 0, 128>>
    assert ClearColor.serialize( {{:red, 128}} )   == <<1, 255, 0, 0, 128>>
    assert ClearColor.serialize( {1,2,3} )         == <<1, 1, 2, 3, 255>>
    assert ClearColor.serialize( {{1,2,3}} )       == <<1, 1, 2, 3, 255>>
    assert ClearColor.serialize( {1,2,3,4} )       == <<1, 1, 2, 3, 4>>
    assert ClearColor.serialize( {{1,2,3,4}} )     == <<1, 1, 2, 3, 4>>
  end

  #============================================================================
  # deserialize - various forms
  
  test "deserialize works" do
    assert ClearColor.deserialize( <<1,1,2,3,4>> <> <<123,21>>) ==
      {:ok, {{1,2,3,4}}, <<123,21>>}
  end




end


