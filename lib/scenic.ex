defmodule Scenic do


  @moduledoc """
  Welcome to Scenic.

  * [General Overview](overview_general.html)
  * [Getting Started](getting_started.html)
  * [Overview of a Scene](overview_scene.html)
  * [Overview of a ViewPort](overview_viewport.html)
  * [Overview of a Driver](overview_driver.html)

  """
  use Supervisor

  @viewports :scenic_dyn_viewports

  def start_link( opts \\ [] )
  def start_link( {a,b} ), do: start_link( [{a,b}] )
  def start_link( opts ) when is_list(opts) do
    Supervisor.start_link(__MODULE__, opts, name: :scenic)
  end

  #--------------------------------------------------------
  def init( opts ) do
    opts
    |> Keyword.get( :viewports, [] )
    |> do_init
  end

  #--------------------------------------------------------
  # init with no default viewports
  def do_init( [] ) do
    [
      {Scenic.ViewPort.Tables, nil},
      supervisor(Scenic.Cache.Supervisor, []),
      {DynamicSupervisor, name: @viewports, strategy: :one_for_one}
    ]
    |> Supervisor.init( strategy: :one_for_one )
  end

  #--------------------------------------------------------
  # init with default viewports
  def do_init( viewports ) do
    [
      {Scenic.ViewPort.Tables, nil},
      supervisor(Scenic.Cache.Supervisor, []),
      supervisor(Scenic.ViewPort.SupervisorTop, [viewports]),
      {DynamicSupervisor, name: @viewports, strategy: :one_for_one}
    ]
    |> Supervisor.init( strategy: :one_for_one )
  end


end
