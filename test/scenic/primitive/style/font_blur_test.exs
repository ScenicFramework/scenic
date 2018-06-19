#
#  Created by Boyd Multerer on 5/12/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.FontBlurTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.FontBlur


  #============================================================================
  # verify - various forms

  test "verfy works" do
    assert FontBlur.verify( 10 )
    assert FontBlur.verify( 0 )
    assert FontBlur.verify( 255 )
  end

  test "verify rejects out of bounds values" do
    refute FontBlur.verify( -1 )
  end

  test "verify! works" do
    assert FontBlur.verify!( 10 )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      FontBlur.verify!( "banana" )
    end
  end

end


