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

  # import IEx

  @max_depth 256

  @min_window_width 20
  @min_window_height 20

  # describe the struct. Name nil and opts as an empty list are good defaults
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
  # @type t :: %Status{
  #   drivers:          Map.t,
  #   root_config:      {scene_module :: atom, args :: any} | scene_name :: atom,
  #   root_graph:       {:graph, reference, any},
  #   root_scene_pid:   pid,
  #   size:             Math.point
  # }

  # --------------------------------------------------------
  def valid?(%Config{
        default_scene: {mod, _},
        name: name,
        drivers: drivers,
        size: {width, height}
      }) do
    ok =
      is_atom(mod) && !is_nil(mod) && is_atom(name) && is_list(drivers) && is_number(width) &&
        is_number(height) && width >= @min_window_width && height >= @min_window_height

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
    ok =
      is_atom(scene_name) && !is_nil(scene_name) && is_atom(name) && is_list(drivers) &&
        is_number(width) && is_number(height) && width > @min_window_width &&
        height > @min_window_height

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
      when is_atom(mod) and not is_nil(mod) and is_atom(name) and is_list(drivers) and
             is_number(width) and is_number(height) and width > @min_window_width and
             height > @min_window_height do
    Enum.each(drivers, &Driver.Config.valid!(&1))
    :ok
  end

  def valid!(%Config{
        default_scene: scene_name,
        name: name,
        drivers: drivers,
        size: {width, height}
      })
      when is_atom(scene_name) and not is_nil(scene_name) and is_atom(name) and is_list(drivers) and
             is_number(width) and is_number(height) and width > @min_window_width and
             height > @min_window_height do
    Enum.each(drivers, &Driver.Config.valid!(&1))
    :ok
  end

  def valid!(%Config{default_scene: nil}) do
    raise "ViewPort Config requires a default_scene"
  end

  def valid!(%Config{name: name}) when not is_atom(name) do
    raise "ViewPort Config name must be an atom"
  end

  def valid!(%Config{default_scene: nil}) do
    raise "ViewPort Config requires a default_scene"
  end

  def valid!(%{} = config) do
    valid!(struct(Config, config))
  end
end
