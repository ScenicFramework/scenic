#
#  Created by Boyd Multerer on 11/02/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.TranslateTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Translate

  @data_2   {1.0, 2.0}
  @data_3   { 1.0, 2.0, 3.0 }

  @bin_2_native     <<
      1.0 :: float-size(32)-native,
      2.0 :: float-size(32)-native,
      0.0 :: float-size(32)-native,
    >>

  @bin_3_native     <<
      1.0 :: float-size(32)-native,
      2.0 :: float-size(32)-native,
      3.0 :: float-size(32)-native,
    >>

  @bin_2_big   <<
      1.0 :: float-size(32)-big,
      2.0 :: float-size(32)-big,
      0.0 :: float-size(32)-big,
    >>

  @bin_3_big   <<
      1.0 :: float-size(32)-big,
      2.0 :: float-size(32)-big,
      3.0 :: float-size(32)-big,
    >>

  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Translate.verify( @data_2 ) == true
    assert Translate.verify( @data_3 ) == true
  end

  test "verify fails invalid data" do
    assert Translate.verify( 1.1 )                  == false
    assert Translate.verify( {1.1} )                == false
    assert Translate.verify( {1.1, 1.2, 1.3, 1.4} ) == false
    assert Translate.verify( {1.1, :banana} )       == false
    assert Translate.verify( :banana )              == false
  end

end

