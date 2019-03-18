#
#  Created by Boyd Multerer on 2017-11-29.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Support.Supervisor do
  @moduledoc """
  Supervisor that starts up and manages the asset caches
  """
  use Supervisor

  #  import IEx

  # ============================================================================
  # setup the viewport supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  @doc false
  def init(:ok) do
    [
      {Scenic.Cache.Static.Texture, []},
      {Scenic.Cache.Static.Font, []},
      {Scenic.Cache.Static.FontMetrics, []},
      {Scenic.Cache.Dynamic.Texture, []}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
