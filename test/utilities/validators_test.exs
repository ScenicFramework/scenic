defmodule Scenic.Utilities.ValidatorsTest do
  use ExUnit.Case, async: true
  doctest Scenic.Utilities.Validators

  alias Scenic.Utilities.Validators

  test "validate_xs accepts valid points" do
    assert Validators.validate_xy( {1,2}, :some_name ) == { :ok, {1,2} }
    assert Validators.validate_xy( {1.1,2.1}, :some_name ) == { :ok, {1.1,2.1} }
  end

  test "validate_xs rejects invalid points" do
    assert { :error, _ } = Validators.validate_xy( {1,2,3}, :some_name )
    assert { :error, _ } = Validators.validate_xy( :invalid, :some_name )
  end


  test "validate_wh accepts valid points" do
    assert Validators.validate_wh( {1,2}, :some_name ) == { :ok, {1,2} }
    assert Validators.validate_wh( {1.1,2.1}, :some_name ) == { :ok, {1.1,2.1} }
  end

  test "validate_wh rejects invalid points" do
    assert { :error, _ } = Validators.validate_wh( {1,2,3}, :some_name )
    assert { :error, _ } = Validators.validate_wh( :invalid, :some_name )
  end


  test "validate_scene accepts names" do
    assert Validators.validate_scene( Some.Module, :some_name ) == { :ok, {Some.Module, nil} }
    assert Validators.validate_scene( {Some.Module,123}, :some_name ) == { :ok, {Some.Module,123} }
  end

  test "validate_scene rejects invalid names" do
    assert { :error, _ } = Validators.validate_scene( 123, :some_name )
  end


  test "validate_vp accepts vp structs" do
    assert Validators.validate_vp( %Scenic.ViewPort{}, :some_name ) == { :ok, %Scenic.ViewPort{} }
  end

  test "validate_vp rejects invalid vp structs" do
    assert { :error, _ } = Validators.validate_vp( %{}, :some_name )
  end

end
