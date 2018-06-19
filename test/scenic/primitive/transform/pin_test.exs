#
#  Created by Boyd Multerer on 11/02/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.PinTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Pin

  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Pin.verify( { 1, 2 } ) == true
  end

  test "verify fails invalid data" do
    assert Pin.verify( 1 )         == false
    assert Pin.verify( {1} )       == false
    assert Pin.verify( {1,2,3,4} ) == false
    assert Pin.verify( :banana )   == false
  end


end

