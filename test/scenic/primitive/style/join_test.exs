#
#  Created by Boyd Multerer on June 18, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.JoinTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Join


  #============================================================================
  # verify - various forms

  test "verfy works" do
    assert Join.verify( :miter )
    assert Join.verify( :round )
    assert Join.verify( :bevel )
  end

  test "verify rejects invalid values" do
    refute Join.verify( "miter" )
    refute Join.verify( 123 )
  end

  test "verify! works" do
    assert Join.verify!( :miter )
  end

  test "verify! raises an error" do
    assert_raise Style.FormatError, fn ->
      Join.verify!( "miter" )
    end
  end

end


