defmodule Temp.StaticSupervisor do
  use Supervisor

  @name     :static_scenes

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def init(:ok) do
    children = [
      {Scenic.Clock.Digital, {[], [name: :clock]}},
      # {Scenic.Clock.Analog, {[size: 40], [name: :clock]}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
