defmodule ScenicTest do
  use ExUnit.Case
  doctest Scenic

  test "version works" do
    assert Scenic.version == Mix.Project.config()[:version]
  end

  test "child_spec" do
   assert Scenic.child_spec(:opts) == %{
      id: Scenic,
      start: {Scenic, :start_link, [:opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: 500
    }
  end

end
