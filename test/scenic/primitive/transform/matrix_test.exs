#
#  Created by Boyd Multerer on 11/02/17
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Transform.MatrixTest do
  use ExUnit.Case, async: true
  doctest Scenic

  alias Scenic.Primitive.Transform.Matrix

  @data     <<
      1.0 :: float-size(32)-native,
      1.1 :: float-size(32)-native,
      1.2 :: float-size(32)-native,
      1.3 :: float-size(32)-native,

      2.0 :: float-size(32)-native,
      2.1 :: float-size(32)-native,
      2.2 :: float-size(32)-native,
      2.3 :: float-size(32)-native,

      3.0 :: float-size(32)-native,
      3.1 :: float-size(32)-native,
      3.2 :: float-size(32)-native,
      3.3 :: float-size(32)-native,

      4.0 :: float-size(32)-native,
      4.1 :: float-size(32)-native,
      4.2 :: float-size(32)-native,
      4.3 :: float-size(32)-native
    >>

  @data_big   <<
      1.0 :: float-size(32)-big,
      1.1 :: float-size(32)-big,
      1.2 :: float-size(32)-big,
      1.3 :: float-size(32)-big,

      2.0 :: float-size(32)-big,
      2.1 :: float-size(32)-big,
      2.2 :: float-size(32)-big,
      2.3 :: float-size(32)-big,

      3.0 :: float-size(32)-big,
      3.1 :: float-size(32)-big,
      3.2 :: float-size(32)-big,
      3.3 :: float-size(32)-big,

      4.0 :: float-size(32)-big,
      4.1 :: float-size(32)-big,
      4.2 :: float-size(32)-big,
      4.3 :: float-size(32)-big
    >>

  #============================================================================
  # verify

  test "verify passes valid data" do
    assert Matrix.verify( @data ) == true
  end

  test "verify fails invalid data" do
    assert Matrix.verify( @data <> <<0>> )    == false
    assert Matrix.verify( :banana )           == false
  end

  #============================================================================
  # serialization

  test "serialize native works" do
    assert Matrix.serialize(@data)            == {:ok, @data}
    assert Matrix.serialize(@data, :native)   == {:ok, @data}
  end

  test "serialize big works" do
    assert Matrix.serialize(@data, :big)      == {:ok, @data_big}
  end

  test "deserialize native works" do
    assert assert Matrix.deserialize(@data)          == {:ok, @data, ""}
    assert assert Matrix.deserialize(@data, :native) == {:ok, @data, ""}
  end

  test "deserialize big works" do
    assert assert Matrix.deserialize(@data_big, :big) == {:ok, @data, ""}
  end

end

