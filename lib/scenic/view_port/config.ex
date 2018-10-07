#
#  Created by Boyd Multerer April 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Config do
  @moduledoc """
  Helper module for configuring Drivers during startup.
  """

  alias Scenic.ViewPort.Driver
  alias Scenic.ViewPort.Config
  alias Scenic.Math

  @max_depth 256

  @min_window_width 20
  @min_window_height 20

  defstruct name: nil,
            default_scene: nil,
            default_scene_activation: nil,
            drivers: [],
            max_depth: @max_depth,
            size: nil,
            on_close: nil,
            opts: []

  @type t :: %Config{
          name: atom,
          default_scene: name :: atom | {module :: atom, any},
          default_scene_activation: any,
          drivers: list,
          max_depth: pos_integer,
          size: Math.point(),
          on_close: :stop_viewport | :stop_system | function,
          opts: list({atom, any})
        }

  # --------------------------------------------------------
  defguardp is_valid(name, drivers, height, width)
            when is_atom(name) and is_list(drivers) and is_number(height) and is_number(width) and
                   width >= @min_window_width and height >= @min_window_height

  defp valid?(name, drivers, height, width) do
    is_atom(name) and is_list(drivers) and is_number(width) and is_number(height) and
      width >= @min_window_width and height >= @min_window_height
  end

  def valid?(%Config{
        default_scene: {mod, _},
        name: name,
        drivers: drivers,
        size: {width, height}
      }) do
    ok = is_atom(mod) and not is_nil(mod) and valid?(name, drivers, height, width)

    Enum.reduce(drivers, ok, fn driver_config, ok ->
      Driver.Config.valid?(driver_config) && ok
    end)
  end

  def valid?(%Config{
        default_scene: scene_name,
        name: name,
        drivers: drivers,
        size: {width, height}
      }) do
    ok = is_atom(scene_name) and not is_nil(scene_name) and valid?(name, drivers, height, width)

    Enum.reduce(drivers, ok, fn driver_config, ok ->
      Driver.Config.valid?(driver_config) && ok
    end)
  end

  def valid?(%{} = config), do: valid?(struct(Config, config))

  # --------------------------------------------------------
  def valid!(%Config{
        default_scene: {mod, _},
        name: name,
        drivers: drivers,
        size: {width, height}
      })
      when is_atom(mod) and not is_nil(mod) and is_valid(name, drivers, height, width) do
    Enum.each(drivers, &Driver.Config.valid!(&1))
    :ok
  end

  def valid!(%Config{
        default_scene: scene_name,
        name: name,
        drivers: drivers,
        size: {width, height}
      })
      when is_atom(scene_name) and not is_nil(scene_name) and
             is_valid(name, drivers, height, width) do
    Enum.each(drivers, &Driver.Config.valid!(&1))
    :ok
  end

  def valid!(%Config{default_scene: nil}) do
    raise "ViewPort Config requires a default_scene"
  end

  def valid!(%Config{name: name}) when not is_atom(name) do
    raise "ViewPort Config name must be an atom"
  end

  def valid!(%{} = config) do
    valid!(struct(Config, config))
  end
end
