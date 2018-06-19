#
#  Created by Boyd Multerer on 11/02/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.ScaleTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Scale

  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Scale.verify( 1.0 ) == true
    assert Scale.verify( {1.0, 2.0} ) == true
  end

  test "verify fails invalid data" do
    assert Scale.verify( {1.1, 1.2, 1.3} )  == false
    assert Scale.verify( {1.1, :banana} )   == false
    assert Scale.verify( :banana )               == false
  end

end

