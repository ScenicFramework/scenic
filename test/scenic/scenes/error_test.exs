#
#  Created by Boyd Multerer on 28/02/2019.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Scenes.ErrorTest do
  use ExUnit.Case, async: true
  doctest Scenic.Scenes.Error

  alias Scenic.Scenes

  defmodule FakeViewPort do
    use GenServer

    def start_link(), do: GenServer.start_link(__MODULE__, nil)
    def init(nil), do: {:ok, nil}

    def handle_call(:query_info, _, state) do
      {:reply, {:ok, %Scenic.ViewPort.Status{size: {500, 400}}}, state}
    end
  end

  test "init" do
    {:ok, fvp} = FakeViewPort.start_link()

    {:ok, {:mod, :args, ^fvp}, push: _} =
      Scenes.Error.init(
        {{"module", "err", "args", "stack"}, :mod, :args},
        viewport: fvp
      )

    Process.exit(fvp, :normal)
  end

  test "filter_event {:click, :try_again}" do
    self = self()
    state = {:mod, :args, self}
    {:halt, ^state} = Scenes.Error.filter_event({:click, :try_again}, nil, state)
    assert_receive({:"$gen_cast", {:set_root, {:mod, :args}, _}})
  end

  test "filter_event {:click, :restart}" do
    self = self()
    state = {:mod, :args, self}
    {:halt, ^state} = Scenes.Error.filter_event({:click, :restart}, nil, state)
    assert_receive({:"$gen_cast", :reset})
  end
end
