#
#  Created by Boyd Multerer on 2018-03-27.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# Supervisor for non-dynamic scenes

defmodule Scenic.Scene.Supervisor do
  @moduledoc false
  use Supervisor

  def child_spec({scene_module, args, opts}) do
    %{
      id: opts[:name] || make_ref(),
      start: {__MODULE__, :start_link, [{scene_module, args, opts}]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link({scene_module, args, opts}) do
    Supervisor.start_link(__MODULE__, {scene_module, args, opts})
  end

  def init(args) do
    [
      {DynamicSupervisor, strategy: :one_for_one},
      {Scenic.Scene, args}
    ]
    |> Supervisor.init(strategy: :one_for_all)
  end
end
