#
#  Created by Boyd Multerer on 20109-03-07.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Cache.BaseTest do
  use ExUnit.Case, async: true
  doctest Scenic.Cache.Support.File

  alias Scenic.Cache.Base

  @table :base_test_table

  defmodule Static.Test do
    use Scenic.Cache.Base, name: "static_test", static: true
    def load(hash, path, options), do: {:load, hash, path, options}
    def load!(hash, path, options), do: {:load!, hash, path, options}
  end

  setup do
    :ets.new(@table, [:set, :protected, :named_table])
    {:ok, static} = Base.start_link(Static.Test, "static_test")

    on_exit(fn ->
      Process.exit(static, :normal)
      Process.sleep(2)
    end)

    %{static: static}
  end

  # ============================================================================
  # get(service, hash, default \\ nil)

  test "get looks up the data" do
    :ets.insert(@table, {"hash", 0, "some_data"})
    assert Base.get(@table, "hash") == "some_data"
  end

  test "get returns nil if missing" do
    :ets.insert(@table, {"hash", 0, "some_data"})
    assert Base.get(@table, "missing") == nil
  end

  test "get returns default if not there" do
    :ets.insert(@table, {"hash", 0, "some_data"})
    assert Base.get(@table, "missing", :default) == :default
  end

  # ============================================================================
  # fetch(service, hash)

  test "fetch looks up the data" do
    :ets.insert(@table, {"hash", 0, "some_data"})
    assert Base.fetch(@table, "hash") == {:ok, "some_data"}
  end

  test "fetch returns error if missing" do
    :ets.insert(@table, {"hash", 0, "some_data"})
    assert Base.fetch(@table, "missing") == {:error, :not_found}
  end

  # ============================================================================
  # get!(service, hash)

  test "get! returns the data" do
    :ets.insert(@table, {"hash", 0, "some_data"})
    assert Base.get!(@table, "hash") == "some_data"
  end

  test "get! raises error if missing" do
    :ets.insert(@table, {"hash", 0, "some_data"})

    assert_raise Base.Error, fn ->
      Base.get!(@table, "missing")
    end
  end

  # ============================================================================
  # put(service, key, data, scope \\ nil)

  test "put sets new data", %{static: static} do
    self = self()
    :erlang.trace(static, true, [:receive])
    assert Base.put(Static.Test, "hash", "new_data") == {:ok, "hash"}
    assert Base.get(Static.Test, "hash") == "new_data"

    assert_receive {:trace, ^static, :receive,
                    {:"$gen_call", {^self, _}, {:put, ^self, "hash", "new_data"}}}
  end

  test "put overwrites existing data", %{static: static} do
    self = self()
    assert Base.put(Static.Test, "hash", "existing_data") == {:ok, "hash"}
    assert Base.get(Static.Test, "hash") == "existing_data"
    :erlang.trace(static, true, [:receive])
    assert Base.put(Static.Test, "hash", "new_data") == {:ok, "hash"}
    assert Base.get(Static.Test, "hash") == "new_data"

    assert_receive {:trace, ^static, :receive,
                    {:"$gen_call", {^self, _}, {:put, ^self, "hash", "new_data"}}}
  end

  test "put claims against various scopes" do
    {:ok, agent} = Agent.start(fn -> 1 + 1 end, name: :named_scope)

    Base.put(Static.Test, "hash_l", "some_data")
    Base.put(Static.Test, "hash_g", "some_data", :global)
    Base.put(Static.Test, "hash_n", "some_data", :named_scope)
    Base.put(Static.Test, "hash_p", "some_data", agent)

    assert Base.claimed?(Static.Test, "hash_l")
    assert Base.claimed?(Static.Test, "hash_l", self())
    refute Base.claimed?(Static.Test, "hash_l", :global)
    assert Base.claimed?(Static.Test, "hash_g", :global)
    assert Base.claimed?(Static.Test, "hash_n", :named_scope)
    assert Base.claimed?(Static.Test, "hash_p", agent)

    Agent.stop(agent)
  end

  # ============================================================================
  # put_new(service, key, data, scope \\ nil)

  test "put_new sets new data", %{static: static} do
    self = self()
    :erlang.trace(static, true, [:receive])
    assert Base.put_new(Static.Test, "hash", "new_data") == {:ok, "hash"}
    assert Base.get(Static.Test, "hash") == "new_data"

    assert_receive {:trace, ^static, :receive,
                    {:"$gen_call", {^self, _}, {:put_new, ^self, "hash", "new_data"}}}
  end

  test "put_new does not overwrite existing data", %{static: static} do
    assert Base.put(Static.Test, "hash", "existing_data") == {:ok, "hash"}
    :erlang.trace(static, true, [:receive])
    assert Base.put_new(Static.Test, "hash", "new_data") == {:ok, "hash"}
    assert Base.get(Static.Test, "hash") == "existing_data"

    refute_receive {:trace, ^static, :receive, {:"$gen_call", _, {:put_new, _, _, _}}}
  end

  test "put_new claims against various scopes" do
    {:ok, agent} = Agent.start(fn -> 1 + 1 end, name: :named_scope)

    Base.put_new(Static.Test, "hash_l", "some_data")
    Base.put_new(Static.Test, "hash_g", "some_data", :global)
    Base.put_new(Static.Test, "hash_n", "some_data", :named_scope)
    Base.put_new(Static.Test, "hash_p", "some_data", agent)

    assert Base.claimed?(Static.Test, "hash_l")
    assert Base.claimed?(Static.Test, "hash_l", self())
    refute Base.claimed?(Static.Test, "hash_l", :global)
    assert Base.claimed?(Static.Test, "hash_g", :global)
    assert Base.claimed?(Static.Test, "hash_n", :named_scope)
    assert Base.claimed?(Static.Test, "hash_p", agent)

    Agent.stop(agent)
  end

  # ============================================================================
  # claim(service, key, scope \\ nil)

  test "claim works" do
    Base.put(Static.Test, "hash", "existing_data", :global)
    assert Base.keys(Static.Test, :global) == ["hash"]
    assert Base.keys(Static.Test) == []

    assert Base.claim(Static.Test, "hash") == :ok
    assert Base.keys(Static.Test) == ["hash"]
  end

  test "claim works with various scopes" do
    {:ok, agent} = Agent.start(fn -> 1 + 1 end, name: :named_scope)

    # start with default scope
    Base.put(Static.Test, "hash", "existing_data")
    Base.put(Static.Test, "hash_2", "existing_data")

    # a bunch of claims
    Base.claim(Static.Test, "hash", :global)
    Base.claim(Static.Test, "hash", :named_scope)
    Base.claim(Static.Test, "hash_2", agent)

    assert Base.claimed?(Static.Test, "hash")
    assert Base.claimed?(Static.Test, "hash", :global)
    assert Base.claimed?(Static.Test, "hash", :named_scope)
    assert Base.claimed?(Static.Test, "hash", agent)
    assert Base.claimed?(Static.Test, "hash_2", agent)

    refute Base.claimed?(Static.Test, "hash_2", :global)

    Agent.stop(agent)
  end

  # ============================================================================
  # release(service, hash, opts \\ [])

  test "release deletes an item that is claimed once" do
    Base.put(Static.Test, "hash", "new_data")
    assert Base.fetch(Static.Test, "hash") == {:ok, "new_data"}

    assert Base.release(Static.Test, "hash", delay: 0) == :ok
    Process.sleep(6)
    assert Base.fetch(Static.Test, "hash") == {:error, :not_found}
  end

  test "release does not delete if claimed multiply" do
    {:ok, agent} = Agent.start(fn -> 1 + 1 end, name: :named_scope)

    Base.put(Static.Test, "hash", "new_data")
    Base.claim(Static.Test, "hash", :global)
    Base.claim(Static.Test, "hash", :named_scope)
    assert Base.fetch(Static.Test, "hash") == {:ok, "new_data"}

    assert Base.release(Static.Test, "hash", delay: 0) == :ok
    # release is async. Wait for it to do it's work
    Process.sleep(6)
    assert Base.fetch(Static.Test, "hash") == {:ok, "new_data"}

    assert Base.release(Static.Test, "hash", scope: :global, delay: 0) == :ok
    # release is async. Wait for it to do it's work
    Process.sleep(6)
    assert Base.fetch(Static.Test, "hash") == {:ok, "new_data"}

    assert Base.release(Static.Test, "hash", scope: :named_scope, delay: 0) == :ok
    # release is async. Wait for it to do it's work
    Process.sleep(6)
    assert Base.fetch(Static.Test, "hash") == {:error, :not_found}

    Agent.stop(agent)
  end

  test "release with a delay works as expected" do
    Base.subscribe(Static.Test, :all, :delete)
    Base.put(Static.Test, "hash", "data")

    Base.release(Static.Test, "hash", delay: 10)
    assert_receive {:"$gen_cast", {Static.Test, :delete, "hash"}}
  end

  # ============================================================================
  # status(service, hash, scope \\ nil)

  test "status indicates if the scope is claimed locally", %{static: static} do
    self = self()
    Base.put(Static.Test, "hash", "new_data")
    Base.claim(Static.Test, "hash")
    :erlang.trace(static, true, [:receive])

    assert Base.status(Static.Test, "hash") == {:ok, self}

    assert_receive {:trace, ^static, :receive,
                    {:"$gen_call", {^self, _}, {:status, ^self, "hash"}}}
  end

  test "status indicates if the scope is claimed globally" do
    Base.put(Static.Test, "hash", "new_data", :global)
    assert Base.status(Static.Test, "hash") == {:ok, :global}
  end

  test "status indicates if the is not put at all" do
    assert Base.status(Static.Test, "hash") == {:error, :not_found}
  end

  test "status indicates if the scope is not claimed" do
    {:ok, agent} = Agent.start(fn -> 1 + 1 end, name: :named_scope)

    Base.put(Static.Test, "hash", "new_data")
    assert Base.status(Static.Test, "hash", :named_scope) == {:error, :not_claimed}

    Agent.stop(agent)
  end

  # ============================================================================
  # keys( service, scope \\ nil)

  test "keys returns a list of claimed keys" do
    {:ok, agent} = Agent.start(fn -> 1 + 1 end, name: :named_scope)

    Base.put(Static.Test, "hash_0", "data_0")
    Base.put(Static.Test, "hash_1", "data_1")
    Base.claim(Static.Test, "hash_0", :global)
    Base.claim(Static.Test, "hash_1", :named_scope)

    assert Base.keys(Static.Test) == ["hash_1", "hash_0"]
    assert Base.keys(Static.Test, :global) == ["hash_0"]
    assert Base.keys(Static.Test, :named_scope) == ["hash_1"]
    assert Base.keys(Static.Test, :invalid_scope) == []
    assert Base.keys(Static.Test, agent) == ["hash_1"]

    Agent.stop(agent)
  end

  # ============================================================================
  # member?(service, key)

  test "member? works" do
    Base.put(Static.Test, "hash_0", "data_0")

    assert Base.member?(Static.Test, "hash_0")
    refute Base.member?(Static.Test, "hash_1")
  end

  # ============================================================================
  # claimed?(service, key, scope \\ nil)

  test "claimed? works" do
    {:ok, agent} = Agent.start(fn -> 1 + 1 end, name: :named_scope)

    Base.put(Static.Test, "hash_0", "data_0")
    Base.put(Static.Test, "hash_1", "data_1")
    Base.claim(Static.Test, "hash_0", :global)
    Base.claim(Static.Test, "hash_1", :named_scope)

    assert Base.claimed?(Static.Test, "hash_0")
    assert Base.claimed?(Static.Test, "hash_1")

    assert Base.claimed?(Static.Test, "hash_0", :global)
    refute Base.claimed?(Static.Test, "hash_1", :global)

    refute Base.claimed?(Static.Test, "hash_0", :named_scope)
    assert Base.claimed?(Static.Test, "hash_1", :named_scope)

    refute Base.claimed?(Static.Test, "hash_0", agent)
    assert Base.claimed?(Static.Test, "hash_1", agent)

    refute Base.claimed?(Static.Test, "hash_0", :invalid_scope)
    refute Base.claimed?(Static.Test, "hash_1", :invalid_scope)

    Agent.stop(agent)
  end

  # ============================================================================
  # subscribe(hash, sub_type \\ :all)

  test "subscribe works against all verbs and hashes" do
    Base.subscribe(Static.Test, :all, :all)

    Base.put(Static.Test, "hash", "data")
    assert_receive {:"$gen_cast", {Static.Test, :put, "hash"}}

    Base.release(Static.Test, "hash", delay: 0)
    assert_receive {:"$gen_cast", {Static.Test, :delete, "hash"}}
  end

  test "subscribe works against specific verbs" do
    Base.subscribe(Static.Test, :all, :put)

    Base.put(Static.Test, "hash", "data")
    assert_receive {:"$gen_cast", {Static.Test, :put, "hash"}}

    Base.release(Static.Test, "hash", delay: 0)
    refute_receive {:"$gen_cast", {Static.Test, :delete, "hash"}}
  end

  test "subscribe works against specific hashes" do
    Base.subscribe(Static.Test, "hash", :all)

    Base.put(Static.Test, "hash", "data")
    Base.put(Static.Test, "hash2", "data")
    assert_receive {:"$gen_cast", {Static.Test, :put, "hash"}}
    refute_receive {:"$gen_cast", {Static.Test, :put, "hash2"}}

    Base.release(Static.Test, "hash", delay: 0)
    Base.release(Static.Test, "hash2", delay: 0)
    assert_receive {:"$gen_cast", {Static.Test, :delete, "hash"}}
    refute_receive {:"$gen_cast", {Static.Test, :delete, "hash2"}}
  end

  # ============================================================================
  # unsubscribe(hash, sub_type \\ :all)

  test "unsubscribe works against all verbs and hashes" do
    Base.subscribe(Static.Test, :all, :all)
    Base.unsubscribe(Static.Test, :all, :all)

    Base.put(Static.Test, "hash", "data")
    refute_receive {:"$gen_cast", {Static.Test, :put, "hash"}}

    Base.release(Static.Test, "hash", delay: 0)
    refute_receive {:"$gen_cast", {Static.Test, :delete, "hash"}}
  end

  test "unsubscribe works against specific verbs" do
    Base.subscribe(Static.Test, :all, :all)
    Base.unsubscribe(Static.Test, :all, :put)

    Base.put(Static.Test, "hash", "data")
    refute_receive {:"$gen_cast", {Static.Test, :put, "hash"}}

    Base.release(Static.Test, "hash", delay: 0)
    assert_receive {:"$gen_cast", {Static.Test, :delete, "hash"}}
  end

  test "unsubscribe works against specific hashes" do
    Base.subscribe(Static.Test, "hash", :all)
    Base.subscribe(Static.Test, "hash2", :all)
    Base.unsubscribe(Static.Test, "hash2", :all)

    Base.put(Static.Test, "hash", "data")
    Base.put(Static.Test, "hash2", "data")
    assert_receive {:"$gen_cast", {Static.Test, :put, "hash"}}
    refute_receive {:"$gen_cast", {Static.Test, :put, "hash2"}}

    Base.release(Static.Test, "hash", delay: 0)
    Base.release(Static.Test, "hash2", delay: 0)
    assert_receive {:"$gen_cast", {Static.Test, :delete, "hash"}}
    refute_receive {:"$gen_cast", {Static.Test, :delete, "hash2"}}
  end
end
