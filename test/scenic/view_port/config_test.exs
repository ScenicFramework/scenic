#
#  Created by Boyd Multerer April 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# helper module for configuring Viewports during startup



defmodule Scenic.ViewPort.ConfigTest do
  use ExUnit.Case, async: true
  alias Scenic.ViewPort.Driver
  alias Scenic.ViewPort.Config

#   defstruct name: nil, default_scene: nil, default_scene_activation: nil, drivers: []



  #============================================================================
  # valid?

  test "valid? passes just a default scene" do
    assert Config.valid?( %Config{default_scene: :some_scene} )
    assert Config.valid?( %Config{default_scene: {:some_mod, nil}} )
  end

  test "valid? passes a default scene and a name" do
    assert Config.valid?( %Config{default_scene: :some_scene, name: :abc} )
    assert Config.valid?( %Config{default_scene: {:some_mod, nil}, name: :abc} )
  end

  test "valid? passes a default scene, a name, and a driver" do
    assert Config.valid?( %Config{
      default_scene: :some_scene,
      name: :abc,
      drivers: [%Driver.Config{module: :some_driver}]
    } )

    assert Config.valid?( %Config{
      default_scene: {:some_mod, nil},
      name: :abc,
      drivers: [%Driver.Config{module: :some_driver}]
    } )
  end

  test "valid? fails a nil default scene" do
    refute Config.valid?( %Config{default_scene: nil} )
  end

  test "valid? fails an invalid name" do
    refute Config.valid?( %Config{
      default_scene: :some_scene,
      name: "invalid name"
    } )
  end

  test "valid? fails an invalid driver" do
    refute Config.valid?( %Config{
      default_scene: :some_scene,
      drivers: [%Driver.Config{module: "invalid driver name"}]
    } )
  end

  test "valid? accepts a plane-jane map as would be define in config" do
    assert Config.valid?( %{default_scene: :some_scene} )
  end

  # #============================================================================
  # # valid!

  test "valid! passes just a default scene" do
    assert Config.valid!( %Config{default_scene: :some_scene} ) == :ok
    assert Config.valid!( %Config{default_scene: {:some_mod, nil}} ) == :ok
  end

  test "valid! passes a default scene and a name" do
    assert Config.valid!( %Config{default_scene: :some_scene, name: :abc} ) == :ok
    assert Config.valid!( %Config{default_scene: {:some_mod, nil}, name: :abc} ) == :ok
  end

  test "valid! passes a default scene, a name, and a driver" do
    assert Config.valid!( %Config{
      default_scene: :some_scene,
      name: :abc,
      drivers: [%Driver.Config{module: :some_driver}]
    } ) == :ok

    assert Config.valid!( %Config{
      default_scene: {:some_mod, nil},
      name: :abc,
      drivers: [%Driver.Config{module: :some_driver}]
    } ) == :ok
  end

  test "valid! fails a nil default scene" do
    assert_raise RuntimeError, fn ->
      Config.valid!( %Config{default_scene: nil} )
    end
  end

  test "valid! fails an invalid name" do
    assert_raise RuntimeError, fn ->
      Config.valid!( %Config{
        default_scene: :some_scene,
        name: "invalid name"
      } )
    end
  end

  test "valid! fails an invalid driver" do
    assert_raise RuntimeError, fn ->
      Config.valid!( %Config{
        default_scene: :some_scene,
        drivers: [%Driver.Config{module: "invalid driver name"}]
      } )
    end
  end

  test "valid! accepts a plane-jane map as would be define in config" do
    assert Config.valid!( %{default_scene: :some_scene} )
  end

end