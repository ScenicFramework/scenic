#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.BorderWidthTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.BorderWidth


  #============================================================================
  # verify - various forms

  test "verfy works" do
    assert BorderWidth.verify( 10 )
    assert BorderWidth.verify( 0 )
    assert BorderWidth.verify( 255 )
  end

  test "verify rejects out of bounds values" do
    refute BorderWidth.verify( -1 )
    refute BorderWidth.verify( 256 )
  end

  test "verify! works" do
    assert BorderWidth.verify!( 10 )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      BorderWidth.verify!( "banana" )
    end
  end

end


