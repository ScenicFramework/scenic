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

  #============================================================================
  # serialization

  #============================================================================
  # serialization

  test "serialize 1 native works" do
    assert Translate.serialize(@data_2)            == {:ok, @bin_2_native}
    assert Translate.serialize(@data_2, :native)   == {:ok, @bin_2_native}
  end

  test "serialize 3 native works" do
    assert Translate.serialize(@data_3)            == {:ok, @bin_3_native}
    assert Translate.serialize(@data_3, :native)   == {:ok, @bin_3_native}
  end

  test "serialize 1 big works" do
    assert Translate.serialize(@data_2, :big)      == {:ok, @bin_2_big}
  end

  test "serialize 3 big works" do
    assert Translate.serialize(@data_3, :big)      == {:ok, @bin_3_big}
  end

  test "deserialize 1 native works" do
    assert assert Translate.deserialize(@bin_2_native)          == {:ok, @data_2, ""}
    assert assert Translate.deserialize(@bin_2_native, :native) == {:ok, @data_2, ""}
  end

  test "deserialize 3 native works" do
    assert assert Translate.deserialize(@bin_3_native)          == {:ok, @data_3, ""}
    assert assert Translate.deserialize(@bin_3_native, :native) == {:ok, @data_3, ""}
  end

  test "deserialize 1 big works" do
    assert assert Translate.deserialize(@bin_2_big, :big) == {:ok, @data_2, ""}
  end

  test "deserialize 3 big works" do
    assert assert Translate.deserialize(@bin_3_big, :big) == {:ok, @data_3, ""}
  end

end

