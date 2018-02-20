#
#  Created by Boyd Multerer on 2/20/18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.TextHeightTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.TextHeight

  #============================================================================
  # verify - various forms

  test "verfy works" do
    assert TextHeight.verify( 10 )
    assert TextHeight.verify( 0 )
    assert TextHeight.verify( 255 )
  end

  test "verify rejects invalid values" do
    refute TextHeight.verify( "banana" )
  end

  test "verify! works" do
    assert TextHeight.verify!( 10 )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      TextHeight.verify!( "banana" )
    end
  end

end


