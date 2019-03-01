#
#  Created by Boyd Multerer on 28/02/2019.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Scenes.ErrorTest do
  use ExUnit.Case, async: true
  doctest Scenic.Scenes.Error

  alias Scenic.Scenes

  test "init" do
    self = self()

    {:ok, {:mod, :args, ^self}} =
      Scenes.Error.init(
        {{"head", "err", "args", "stack"}, :mod, :args},
        viewport: self
      )
  end

  test "filter_event {:click, :try_again}" do
    self = self()
    state = {:mod, :args, self}
    {:stop, ^state} = Scenes.Error.filter_event({:click, :try_again}, nil, state)
    assert_receive({:"$gen_cast", {:set_root, {:mod, :args}, _}})
  end

  test "filter_event {:click, :restart}" do
    self = self()
    state = {:mod, :args, self}
    {:stop, ^state} = Scenes.Error.filter_event({:click, :restart}, nil, state)
    assert_receive({:"$gen_cast", :reset})
  end
end
