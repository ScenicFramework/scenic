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

  # ============================================================================
  # valid?

  test "valid? passes just a default scene" do
    assert Config.valid?(%Config{default_scene: :some_scene, size: {640, 480}})
    assert Config.valid?(%Config{default_scene: {:some_mod, nil}, size: {640, 480}})
  end

  test "valid? passes a default scene and a name" do
    assert Config.valid?(%Config{default_scene: :some_scene, name: :abc, size: {640, 480}})
    assert Config.valid?(%Config{default_scene: {:some_mod, nil}, name: :abc, size: {640, 480}})
  end

  test "valid? passes a default scene, a name, and a driver" do
    assert Config.valid?(%Config{
             default_scene: :some_scene,
             name: :abc,
             drivers: [%Driver.Config{module: :some_driver}],
             size: {640, 480}
           })

    assert Config.valid?(%Config{
             default_scene: {:some_mod, nil},
             name: :abc,
             drivers: [%Driver.Config{module: :some_driver}],
             size: {640, 480}
           })
  end

  test "valid? fails a nil default scene" do
    refute Config.valid?(%Config{default_scene: nil, size: {640, 480}})
  end

  test "valid? fails an invalid name" do
    refute Config.valid?(%Config{
             default_scene: :some_scene,
             name: "invalid name",
             size: {640, 480}
           })
  end

  test "valid? fails an invalid driver" do
    refute Config.valid?(%Config{
             default_scene: :some_scene,
             drivers: [%Driver.Config{module: "invalid driver name"}],
             size: {640, 480}
           })
  end

  test "valid? accepts a plane-jane map as would be define in config" do
    assert Config.valid?(%{default_scene: :some_scene, size: {640, 480}})
  end

  # #============================================================================
  # # valid!

  test "valid! passes just a default scene" do
    assert Config.valid!(%Config{default_scene: :some_scene, size: {640, 480}}) == :ok
    assert Config.valid!(%Config{default_scene: {:some_mod, nil}, size: {640, 480}}) == :ok
  end

  test "valid! passes a default scene and a name" do
    assert Config.valid!(%Config{default_scene: :some_scene, name: :abc, size: {640, 480}}) == :ok

    assert Config.valid!(%Config{default_scene: {:some_mod, nil}, name: :abc, size: {640, 480}}) ==
             :ok
  end

  test "valid! passes a default scene, a name, and a driver" do
    assert Config.valid!(%Config{
             default_scene: :some_scene,
             name: :abc,
             drivers: [%Driver.Config{module: :some_driver}],
             size: {640, 480}
           }) == :ok

    assert Config.valid!(%Config{
             default_scene: {:some_mod, nil},
             name: :abc,
             drivers: [%Driver.Config{module: :some_driver}],
             size: {640, 480}
           }) == :ok
  end

  test "valid! fails a nil default scene" do
    assert_raise RuntimeError, "ViewPort Config requires a default_scene", fn ->
      Config.valid!(%Config{default_scene: nil, size: {640, 480}})
    end
  end

  test "valid! fails an invalid name" do
    assert_raise RuntimeError, "ViewPort Config name must be an atom", fn ->
      Config.valid!(%Config{
        default_scene: :some_scene,
        name: "invalid name",
        size: {640, 480}
      })
    end
  end

  test "valid! fails an invalid driver" do
    assert_raise RuntimeError, "Driver.Config must reference a valid module", fn ->
      Config.valid!(%Config{
        default_scene: :some_scene,
        drivers: [%Driver.Config{module: "invalid driver name"}],
        size: {640, 480}
      })
    end
  end

  test "valid! accepts a plane-jane map as would be define in config" do
    assert Config.valid!(%{default_scene: :some_scene, size: {640, 480}})
  end
end
