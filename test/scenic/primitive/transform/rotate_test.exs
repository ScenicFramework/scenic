#
#  Created by Boyd Multerer on 11/02/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.RotateTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Rotate

  @data_1   1.0


  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Rotate.verify( 1.0 ) == true
  end

  test "verify fails invalid data" do
    assert Rotate.verify( {1.1, 1.2} )            == false
    assert Rotate.verify( {1.1, 1.2, 1.3, 1.4} )  == false
    assert Rotate.verify( {1.1, 1.2, :banana} )   == false
    assert Rotate.verify( :banana )               == false
  end

end

