#
#  Created by Boyd Multerer on 28/02/2019.
#  Copyright © 2019 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Scenes.ErrorTest do
  use ExUnit.Case, async: true
  doctest Scenic.Scenes.Error

  alias Scenic.ViewPort
  alias Scenic.Scenes

  @viewports :scenic_viewports

  test "the error scene is startable" do
    {:ok, pid} = DynamicSupervisor.start_link(name: @viewports, strategy: :one_for_one)

    {:ok, %ViewPort{} = vp} =
      ViewPort.start(
        size: {700, 600},
        opts: [font: :roboto, font_size: 30, scale: 1.4],
        default_scene: {Scenes.Error, {{"module", "err", "args", "stack"}, :mod, :args}}
      )

    Process.sleep(100)

    # confirm it's script is in place
    # starting the scene is async and may take some time
    Enum.find(1..200, fn _ ->
      case ViewPort.get_script_by_id(vp, 1) do
        {:ok, _script} ->
          true

        :error ->
          Process.sleep(1)
          false
      end
    end)

    DynamicSupervisor.terminate_child(@viewports, pid)
    Process.sleep(2)
  end
end
