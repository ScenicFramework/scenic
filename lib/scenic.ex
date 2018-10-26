defmodule Scenic do
  @moduledoc """
  The Scenic module itself is a supervisor that manages all the machinery that
  makes the [Scenes](overview_scene.html), [ViewPorts](overview_viewport.html),
  and [Drivers](overview_driver.html) run.

  In order to run any Scenic application, you will need to start the Scenic
  supervisor in your supervision tree.

  Load a configuration for one or more ViewPorts, then add Scenic to your root
  supervisor.

      defmodule MyApp do

        def start(_type, _args) do
          import Supervisor.Spec, warn: false

          # load the viewport configuration from config
          main_viewport_config = Application.get_env(:my_app :viewport)

          # start the application with the viewport
          children = [
            supervisor(Scenic, [viewports: [main_viewport_config]]),
          ]
          Supervisor.start_link(children, strategy: :one_for_one)
        end

      end

  Note that you can start the Scenic supervisor without any ViewPort
  Configurations. In that case, you are responsible for supervising
  the ViewPorts yourself. This is not recommended for devices
  as Scenic should know how to restart the main ViewPort in the event
  of an error.
  """

  use Supervisor

  @viewports :scenic_dyn_viewports

  @version Mix.Project.config()[:version]

  @doc """
  Return the current version of scenic
  """
  def version(), do: @version

  # --------------------------------------------------------
  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end

  # --------------------------------------------------------
  @doc false
  def start_link(opts \\ [])
  def start_link({a, b}), do: start_link([{a, b}])

  def start_link(opts) when is_list(opts) do
    Supervisor.start_link(__MODULE__, opts, name: :scenic)
  end

  # --------------------------------------------------------
  @doc false
  def init(opts) do
    opts
    |> Keyword.get(:viewports, [])
    |> do_init
  end

  # --------------------------------------------------------
  # init with no default viewports
  defp do_init([]) do
    [
      {Scenic.ViewPort.Tables, nil},
      supervisor(Scenic.Cache.Supervisor, []),
      {DynamicSupervisor, name: @viewports, strategy: :one_for_one}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

  # --------------------------------------------------------
  # init with default viewports
  defp do_init(viewports) do
    [
      {Scenic.ViewPort.Tables, nil},
      supervisor(Scenic.Cache.Supervisor, []),
      supervisor(Scenic.ViewPort.SupervisorTop, [viewports]),
      {DynamicSupervisor, name: @viewports, strategy: :one_for_one}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
