#
#  Created by Boyd Multerer on 2018-03-27.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

# Supervisor for non-dynamic scenes

defmodule Scenic.Scene.Supervisor do
  @moduledoc false
  use Supervisor

  def child_spec(opts) do
    %{
      id: opts[:name] || make_ref(),
      start: {__MODULE__, :start_link, opts},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) when is_list(opts) do
    opts =
      opts
      |> Keyword.put(:stop_pid, self())
      |> Keyword.put(:supervisor, self())

    [
      {DynamicSupervisor, strategy: :one_for_one},
      {Scenic.Scene, [opts]}
    ]
    |> Supervisor.init(strategy: :one_for_all)
  end
end
