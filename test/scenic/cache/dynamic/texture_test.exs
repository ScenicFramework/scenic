#
#  Created by Boyd Multerer on 2019-03-07.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.Dynamic.TextureTest do
  use ExUnit.Case, async: false
  # doctest Scenic.Cache.Dynamic.Texture

  alias Scenic.Utilities
  alias Scenic.Cache.Base
  alias Scenic.Cache.Dynamic.Texture

  setup do
    GenServer.call(Texture, :reset)
  end

  # ============================================================================
  # core inherited functions are mapped in

  test "get is mapped in" do
    Base.put(Texture, "name", :data)
    assert Texture.get("name") == :data
    assert Texture.get("missing") == nil
    assert Texture.get("missing", :default) == :default
  end

  test "get! is mapped in" do
    Base.put(Texture, "name", :data)
    assert Texture.get!("name") == :data
    assert_raise Base.Error, fn -> Texture.get!("missing") end
  end

  test "fetch is mapped in" do
    Base.put(Texture, "name", :data)
    assert Texture.fetch("name") == {:ok, :data}
    assert Texture.fetch("missing") == {:error, :not_found}
  end

  test "put is mapped in" do
    tex = Utilities.Texture.build!(:g, 10, 20)
    assert Texture.put("name", tex) == {:ok, "name"}
    assert Texture.get("name") == tex
  end

  test "put_new is mapped in" do
    tex = Utilities.Texture.build!(:g, 10, 20)
    assert Texture.put_new("name", tex) == {:ok, "name"}
    assert Texture.get("name") == tex
  end

  test "claim is mapped in" do
    Base.put(Texture, "name", :data)
    assert Texture.claim("name", :global) == :ok
    assert Base.claimed?(Texture, "name", :global)
  end

  test "release is mapped in" do
    Base.put(Texture, "name", :data)
    assert Base.fetch(Texture, "name") == {:ok, :data}
    assert Texture.release("name", delay: 0) == :ok
    Process.sleep(8)
    assert Base.fetch(Texture, "name") == {:error, :not_found}
  end

  test "status is mapped in" do
    Base.put(Texture, "name", :data)
    assert Texture.status("name") == {:ok, self()}
    assert Texture.status("name", :global) == {:error, :not_claimed}
  end

  test "keys is mapped in" do
    Base.put(Texture, "name", :data)
    assert Texture.keys() == ["name"]
    assert Texture.keys(:global) == []
  end

  test "member? is mapped in" do
    Base.put(Texture, "name", :data)
    assert Texture.member?("name")
    refute Texture.member?("missing")
  end

  test "claimed? is mapped in" do
    Base.put(Texture, "name", :data)
    assert Texture.claimed?("name")
    refute Texture.claimed?("name", :global)
  end

  test "subscribe is mapped in" do
    Texture.subscribe(:all, :all)
    Base.put(Texture, "name", "data")
    assert_receive {:"$gen_cast", {Texture, :put, "name"}}
  end

  test "unsubscribe is mapped in" do
    Texture.subscribe(:all, :all)
    Texture.unsubscribe(:all, :all)
    Base.put(Texture, "name", "data")
    refute_receive {:"$gen_cast", {Texture, :put, "name"}}
  end
end
