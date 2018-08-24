defmodule Temp do
  @moduledoc """
  Starter application using the Scenic framework.
  """

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # load the viewport configuration from config
    viewport_config = Application.get_env(:temp, :viewport)

    # start the application with the viewport
    opts = [strategy: :one_for_one, name: ScenicExample]
    children = [
      supervisor(Scenic, [viewports: [viewport_config]]),
      supervisor(Temp.StaticSupervisor, []),
    ]
    Supervisor.start_link(children, opts)
  end

end
