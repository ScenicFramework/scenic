#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.LineWidthTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.LineWidth


  #============================================================================
  # verify - various forms

  test "verfy works" do
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

end


