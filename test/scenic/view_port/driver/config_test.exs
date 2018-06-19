#
#  Created by Boyd Multerer April 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# helper module for configuring Viewports during startup



defmodule Scenic.ViewPort.Driver.ConfigTest do
  use ExUnit.Case, async: true
  alias Scenic.ViewPort.Driver.Config

  #============================================================================
  # valid?

  test "valid? passes just a module" do
    assert Config.valid?( %Config{module: :some_module} )
  end

  test "valid? passes a module and a name" do
    assert Config.valid?( %Config{
      module: :some_module,
      name: :some_name,
    } )
  end

  test "valid? passes a module, a name, and arbirary opts" do
    assert Config.valid?( %Config{
      module: :some_module,
      name: :some_name,
      opts: {123, :stuff}
    } )
  end


  test "valid? fails a nil module" do
    refute Config.valid?( %Config{module: nil} )
  end

  test "valid? fails an invalid name" do
    refute Config.valid?( %Config{module: :some_module, name: "invalid name"} )
  end

  test "valid? accepts a plane-jane map as would be define in config" do
    assert Config.valid?( %{module: :some_module} )
  end

  #============================================================================
  # valid!

  test "valid! passes just a module" do
    assert Config.valid!( %Config{module: :some_module} ) == :ok
  end

  test "valid! passes a module and a name" do
    assert Config.valid!( %Config{
      module: :some_module,
      name: :some_name,
    } ) == :ok
  end

  test "valid! passes a module, a name, and arbirary opts" do
    assert Config.valid!( %Config{
      module: :some_module,
      name: :some_name,
      opts: {123, :stuff}
    } ) == :ok
  end

  test "valid! fails a nil module" do
    assert_raise RuntimeError, fn ->
      Config.valid!( %Config{module: nil} )
    end
  end

  test "valid! accepts a plane-jane map as would be define in config" do
    assert Config.valid!( %{module: :some_module} )
  end

end