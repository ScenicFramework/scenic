#
#  Created by Boyd Multerer April 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Driver.Config do
  @moduledoc """
  Helper module for configuring ViewPorts during startup
  """

  alias Scenic.ViewPort.Driver.Config

  # describe the struct. Name nil and opts as an empty list are good defaults
  defstruct module: nil, name: nil, opts: []

  # import IEx

  def valid?(%Config{module: mod, name: name}) do
    is_atom(mod) && !is_nil(mod) && is_atom(name)
  end

  def valid?(%{} = config), do: valid?(struct(Config, config))

  def valid!(%Config{module: mod, name: name})
      when is_atom(mod) and not is_nil(mod) and is_atom(name) do
    :ok
  end

  def valid!(%Config{module: _}) do
    raise "Driver.Config must reference a valid module"
  end

  def valid!(%{} = config), do: valid!(struct(Config, config))
end
