#
#  Created by Boyd Multerer on 11/02/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.PinTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Pin

  @data_2         { 1, 2 }
  @data_3         { 1, 2, 3 }

  @bin_2_native     <<
      1 :: integer-size(16)-native,
      2 :: integer-size(16)-native,
      0 :: integer-size(16)-native
    >>

  @bin_3_native     <<
      1 :: integer-size(16)-native,
      2 :: integer-size(16)-native,
      3 :: integer-size(16)-native
    >>

  @bin_2_big   <<
      1 :: integer-size(16)-big,
      2 :: integer-size(16)-big,
      0 :: integer-size(16)-big
    >>

  @bin_3_big   <<
      1 :: integer-size(16)-big,
      2 :: integer-size(16)-big,
      3 :: integer-size(16)-big
    >>

  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Pin.verify( @data_2 ) == true
    assert Pin.verify( @data_3 ) == true
  end

  test "verify fails invalid data" do
    assert Pin.verify( 1 )         == false
    assert Pin.verify( {1} )       == false
    assert Pin.verify( {1,2,3,4} ) == false
    assert Pin.verify( :banana )   == false
  end


  #============================================================================
  # serialization

  test "serialize 2 native works" do
    assert Pin.serialize(@data_2)            == {:ok, @bin_2_native}
    assert Pin.serialize(@data_2, :native)   == {:ok, @bin_2_native}
  end

  test "serialize 3 native works" do
    assert Pin.serialize(@data_3)            == {:ok, @bin_3_native}
    assert Pin.serialize(@data_3, :native)   == {:ok, @bin_3_native}
  end

  test "serialize 2 big works" do
    assert Pin.serialize(@data_2, :big)      == {:ok, @bin_2_big}
  end

  test "serialize 3 big works" do
    assert Pin.serialize(@data_3, :big)      == {:ok, @bin_3_big}
  end

  test "deserialize 2 native works" do
    assert assert Pin.deserialize(@bin_2_native)          == {:ok, @data_2, ""}
    assert assert Pin.deserialize(@bin_2_native, :native) == {:ok, @data_2, ""}
  end

  test "deserialize 3 native works" do
    assert assert Pin.deserialize(@bin_3_native)          == {:ok, @data_3, ""}
    assert assert Pin.deserialize(@bin_3_native, :native) == {:ok, @data_3, ""}
  end

  test "deserialize 2 big works" do
    assert assert Pin.deserialize(@bin_2_big, :big) == {:ok, @data_2, ""}
  end

  test "deserialize 3 big works" do
    assert assert Pin.deserialize(@bin_3_big, :big) == {:ok, @data_3, ""}
  end

end

