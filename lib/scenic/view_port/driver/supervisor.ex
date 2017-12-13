#
#  Created by Boyd Multerer on 10/07/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.ViewPort.Driver.Supervisor do
  use Supervisor
  require Logger

  @name       :drivers

#  import IEx

  #============================================================================
  # setup the viewport supervisor - get the list of drivers from the config

  def start_link( ) do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init( :ok ) do
    Application.get_env(:scenic, Scenic)[:drivers]
    |> Enum.map( fn({driver, name}) ->
      get_driver_config({driver, name})
      |> driver.child_spec()
    end)
    |> Supervisor.init( strategy: :one_for_one )
  end

  def get_driver_config({driver, name}) when is_atom(driver) and is_atom(name) do
    config = Application.get_env(:scenic, name) || []
    {name, config}
  end
  def get_driver_config(opts) do
    Logger.error( """
      Invalid driver request: #{inspect(opts)}
      To specify a render driver in Scenic, include both the module and a unique
      name (an atom) for the driver. Like this:

      config :scenic, Scenic,
        drivers: [
          {Scenic.Render.Glfw,    :render_glfw},
          {Scenic.Render.Remote,  :remote_user},
          {Scenic.Render.Remote,  :remote_mirror}
        ]

      The above configuration will spin up 3 render drivers simultaneously that will 
      display the same information.

      Configure a specific driver in a seperate config line. Like this:

      config :scenic, :render_glfw, w: 700, h: 600, title: "Render GLFW"

      The reason the driver is configured in a seperate line instead of in a keyword list
      when first specifying which drivers to load is to make it easy to include secrets
      in a seperate configuration line in a seperate file. 

      For example, the remote drivers require a URL, user ID and password. These should NOT
      be checked into your source control. Instead, put them in a config.secrets.exs type
      file that is outside of source control.

      Then you can configure those parameters like this:

      config :scenic, :remote_user,
        url:  "https://www.example.com",
        id:   "sample_id",
        key:  "sample_secret_key"


      The configuration keys will be merged together and presented to the driver.
      """ )
    end

end