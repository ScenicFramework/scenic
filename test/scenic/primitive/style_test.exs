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
  # verify
  test "verify works" do
    assert Style.verify( :border_color, :red ) == true
    assert Style.verify( :border_width, 10 )   == true
    assert Style.verify( :color, :green )      == true
    assert Style.verify( :hidden, true )       == true
    assert Style.verify( :line_width, 10 )     == true
    assert Style.verify( :clear_color, :blue ) == true
  end

  test "verify passes non-primitive styles" do
    assert Style.verify( :fruit, :bananas ) == true
  end

  test "verify uses the primitive style's verify" do
    assert Style.verify( :border_color, :not_a_color ) == false
    assert Style.verify( :border_width, -1 )           == false
    assert Style.verify( :color, :not_a_color )        == false
    assert Style.verify( :hidden, 12 )                 == false
    assert Style.verify( :line_width, 300 )            == false
    assert Style.verify( :clear_color, :not_a_color )  == false
  end

  #============================================================================
  # verify!
  test "verify! works" do
    assert Style.verify!( :border_color, :red ) == :red
  end
  test "verify! passes non-primitive styles" do
    assert Style.verify!( :fruit, :bananas ) == :bananas
  end
  test "verify! raises on error" do
    assert_raise Style.FormatError, fn ->
      Style.verify!( :color, :bananas )
    end
  end


  #============================================================================
  # normalize
  test "normalize transforms data into the style's normlized version" do
    assert Style.normalize( :border_color, :red ) == {{255, 0, 0, 255}}
    assert Style.normalize( :color, :green )      == {{0, 128, 0, 255}}
    assert Style.normalize( :clear_color, :blue ) == {{0, 0, 255, 255}}
  end

  #============================================================================
  # primitives

  test "primitives filters a style map to only the normalized, primitive types" do
    assert Style.primitives(@styles) == %{
      color:  {{255, 0, 0, 255}},
      hidden: false
    }
  end

end
