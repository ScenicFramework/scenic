#
#  Created by Boyd Multerer on November 13, 2017.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# ==============================================================================
defmodule Scenic.CacheTest do
  use ExUnit.Case, async: false
  doctest Scenic.Cache

  alias Scenic.Cache

  #  import IEx

  @cache_table :scenic_cache_key_table
  @scope_table :scenic_cache_scope_table
  @agent_name :test_agent_name

  # --------------------------------------------------------
  setup do
    assert :ets.info(@cache_table) == :undefined
    assert :ets.info(@scope_table) == :undefined
    :ets.new(@cache_table, [:set, :public, :named_table])
    :ets.new(@scope_table, [:bag, :public, :named_table])

    {:ok, agent} = Agent.start(fn -> 1 + 1 end, name: @agent_name)
    on_exit(fn -> Agent.stop(agent) end)

    %{agent: agent}
  end

  # ============================================================================
  # get

  test "get gets a cached item from the key table" do
    :ets.insert(@cache_table, {"test_key", 1, :test_data})
    assert Cache.get("test_key") == :test_data
  end

  test "get returns nil by default if the key isn't in the table" do
    assert Cache.get("test_key") == nil
  end

  test "get returns passed in default if the key isn't in the table" do
    assert Cache.get("test_key", :default) == :default
  end

  # ============================================================================
  # fetch

  test "fetch gets a cached item from the key table" do
    :ets.insert(@cache_table, {"test_key", 1, :test_data})
    assert Cache.fetch("test_key") == {:ok, :test_data}
  end

  test "fetch returns nil by default if the key isn't in the table" do
    assert Cache.fetch("test_key") == {:error, :not_found}
  end

  # ============================================================================
  # get!

  test "get! gets a cached item from the key table" do
    :ets.insert(@cache_table, {"test_key", 1, :test_data})
    assert Cache.get!("test_key") == :test_data
  end

  test "get! raises if the key isn't in the table" do
    assert_raise Cache.Error, fn ->
      Cache.get!("test_key")
    end
  end

  # ============================================================================
  # put

  test "put adds the keyed data to the current process scope by default - setting refcount to 1" do
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 1, "data"}]
    assert :ets.lookup(@scope_table, :global) == []
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]
  end

  test "put adds the keyed data to the :global scope" do
    assert Cache.put("test_key", "data", :global) == {:ok, "test_key"}
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 1, "data"}]
    assert :ets.lookup(@scope_table, :global) == [{:global, "test_key", self()}]
    assert :ets.lookup(@scope_table, self()) == []
  end

  test "put adds the keyed data to the named scope", %{agent: agent} do
    assert Cache.put("test_key", "data", @agent_name) == {:ok, "test_key"}
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 1, "data"}]
    assert :ets.lookup(@scope_table, agent) == [{agent, "test_key", self()}]
    assert :ets.lookup(@scope_table, self()) == []
    assert :ets.lookup(@scope_table, :global) == []
  end

  test "put adds the keyed data to the pid scope", %{agent: agent} do
    assert Cache.put("test_key", "data", agent) == {:ok, "test_key"}
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 1, "data"}]
    assert :ets.lookup(@scope_table, agent) == [{agent, "test_key", self()}]
    assert :ets.lookup(@scope_table, self()) == []
    assert :ets.lookup(@scope_table, :global) == []
  end

  test "put accepts non-string keys" do
    Cache.put({:test_key, 123}, "data")
    assert Cache.get!({:test_key, 123}) == "data"
  end

  test "put is able to put multiple keys into the same scope" do
    assert Cache.put("test_key_0", "data_0") == {:ok, "test_key_0"}
    assert Cache.put("test_key_1", "data_1") == {:ok, "test_key_1"}
    assert Cache.keys() == ["test_key_0", "test_key_1"]
    assert Cache.get!("test_key_0") == "data_0"
    assert Cache.get!("test_key_1") == "data_1"
  end

  # ============================================================================
  # claim

  test "claim increases the refcount on this process by default" do
    assert Cache.put("test_key", "data", :global) == {:ok, "test_key"}
    assert :ets.lookup(@scope_table, self()) == []
    assert Cache.claim("test_key")
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 2, "data"}]
    assert :ets.lookup(@scope_table, :global) == [{:global, "test_key", self()}]
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]
  end

  test "claim increases the refcount on the :global scope" do
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert :ets.lookup(@scope_table, :global) == []
    assert Cache.claim("test_key", :global)
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 2, "data"}]
    assert :ets.lookup(@scope_table, :global) == [{:global, "test_key", self()}]
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]
  end

  test "claim increases the refcount on the named scope", %{agent: agent} do
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert :ets.lookup(@scope_table, @agent_name) == []
    assert Cache.claim("test_key", @agent_name)
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 2, "data"}]
    assert :ets.lookup(@scope_table, :global) == []
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]
    assert :ets.lookup(@scope_table, agent) == [{agent, "test_key", self()}]
  end

  test "claim increases the refcount on the pid scope", %{agent: agent} do
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert :ets.lookup(@scope_table, agent) == []
    assert Cache.claim("test_key", agent)
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 2, "data"}]
    assert :ets.lookup(@scope_table, :global) == []
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]
    assert :ets.lookup(@scope_table, agent) == [{agent, "test_key", self()}]
  end

  test "claim does nothing if the key is already claimed at the given scope" do
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert Cache.claim("test_key")
    assert Cache.claim("test_key")
    assert Cache.claim("test_key")
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 1, "data"}]
    assert :ets.lookup(@scope_table, :global) == []
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]
  end

  test "claim fails if the key is not already in the table" do
    refute Cache.claim("test_key")
  end

  # ============================================================================
  # release

  test "release deletes both the scope reference and the key itself" do
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 1, "data"}]
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]

    assert Cache.release("test_key", delay: 0)

    assert :ets.lookup(@cache_table, "test_key") == []
    assert :ets.lookup(@scope_table, self()) == []
  end

  test "release decrements the key and releases current process scope" do
    assert Cache.put("test_key", "data", :global) == {:ok, "test_key"}
    assert Cache.claim("test_key")
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 2, "data"}]
    assert :ets.lookup(@scope_table, :global) == [{:global, "test_key", self()}]
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]

    assert Cache.release("test_key", delay: 0)

    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 1, "data"}]
    assert :ets.lookup(@scope_table, :global) == [{:global, "test_key", self()}]
    assert :ets.lookup(@scope_table, self()) == []
  end

  test "release decrements the key and releases :global scope" do
    assert Cache.put("test_key", "data", :global) == {:ok, "test_key"}
    assert Cache.claim("test_key")
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 2, "data"}]
    assert :ets.lookup(@scope_table, :global) == [{:global, "test_key", self()}]
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]

    assert Cache.release("test_key", scope: :global, delay: 0)

    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 1, "data"}]
    assert :ets.lookup(@scope_table, :global) == []
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]
  end

  test "release decrements the key and releases named scope", %{agent: agent} do
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert Cache.claim("test_key", agent)
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 2, "data"}]
    assert :ets.lookup(@scope_table, agent) == [{agent, "test_key", self()}]
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]

    assert Cache.release("test_key", scope: @agent_name, delay: 0)

    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 1, "data"}]
    assert :ets.lookup(@scope_table, agent) == []
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]
  end

  test "release decrements the key and releases pid scope", %{agent: agent} do
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert Cache.claim("test_key", agent)
    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 2, "data"}]
    assert :ets.lookup(@scope_table, agent) == [{agent, "test_key", self()}]
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]

    assert Cache.release("test_key", scope: agent, delay: 0)

    assert :ets.lookup(@cache_table, "test_key") == [{"test_key", 1, "data"}]
    assert :ets.lookup(@scope_table, agent) == []
    assert :ets.lookup(@scope_table, self()) == [{self(), "test_key", self()}]
  end

  test "release returns false if the key does not exist" do
    refute Cache.release("test_key", delay: 0)
  end

  # ============================================================================
  # status

  test "status returns {:ok, pid} if the key is claimed locally" do
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert Cache.status("test_key") == {:ok, self()}
  end

  test "status returns {ok, :global} if the key is global, but not local" do
    assert Cache.put("test_key", "data", :global) == {:ok, "test_key"}
    assert Cache.status("test_key") == {:ok, :global}
  end

  test "status returns {ok, :global} if the key is global, and global is requested" do
    assert Cache.put("test_key", "data", :global) == {:ok, "test_key"}
    assert Cache.status("test_key", :global) == {:ok, :global}
  end

  test "status return {:err, :not_claimed} if the key is present, but not claimed", %{
    agent: agent
  } do
    assert Cache.put("test_key", "data", agent) == {:ok, "test_key"}
    assert Cache.status("test_key") == {:err, :not_claimed}
  end

  test "status return {:err, :not_found} if the key is not present at all" do
    assert Cache.status("test_key") == {:err, :not_found}
  end

  test "status returns {:ok, pid} if the key is claimed at named scope", %{agent: agent} do
    assert Cache.put("test_key", "data", agent) == {:ok, "test_key"}
    assert Cache.status("test_key", @agent_name) == {:ok, agent}
  end

  test "status returns {:ok, pid} if the key is claimed at pid scope", %{agent: agent} do
    assert Cache.put("test_key", "data", agent) == {:ok, "test_key"}
    assert Cache.status("test_key", agent) == {:ok, agent}
  end

  # ============================================================================
  # keys

  test "keys returns the keys claimed by the current process scope" do
    assert Cache.put("test_key_0", "data_0") == {:ok, "test_key_0"}
    assert Cache.put("test_key_1", "data_1") == {:ok, "test_key_1"}
    assert Cache.put("test_key_g", "data_g", :global) == {:ok, "test_key_g"}
    assert Cache.keys() == ["test_key_0", "test_key_1"]
  end

  test "keys returns the keys claimed by the :global scope" do
    assert Cache.put("test_key_0", "data_0", :global) == {:ok, "test_key_0"}
    assert Cache.put("test_key_1", "data_1", :global) == {:ok, "test_key_1"}
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert Cache.keys(:global) == ["test_key_0", "test_key_1"]
  end

  test "keys returns the keys claimed by the named scope", %{agent: agent} do
    assert Cache.put("test_key_0", "data_0", agent) == {:ok, "test_key_0"}
    assert Cache.put("test_key_1", "data_1", agent) == {:ok, "test_key_1"}
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert Cache.keys(@agent_name) == ["test_key_0", "test_key_1"]
  end

  test "keys returns the keys claimed by the pid scope", %{agent: agent} do
    assert Cache.put("test_key_0", "data_0", agent) == {:ok, "test_key_0"}
    assert Cache.put("test_key_1", "data_1", agent) == {:ok, "test_key_1"}
    assert Cache.put("test_key", "data") == {:ok, "test_key"}
    assert Cache.keys(agent) == ["test_key_0", "test_key_1"]
  end

  test "keys an empty list if no keys are claimed" do
    assert Cache.keys() == []
    assert Cache.keys(:global) == []
  end

  # ============================================================================
  # handle_cast({:monitor_scope

  test "handle_cast({:monitor_scope, pid}... starts monitoring the pid" do
    # use a seperate agent from the one in setup for this
    {:ok, agent} = Agent.start(fn -> 1 + 1 end)

    {:noreply, :test_state} = Cache.handle_cast({:monitor_scope, agent}, :test_state)
    Agent.stop(agent)

    assert_receive({:DOWN, _, :process, pid, :normal})
    assert pid == agent
  end

  test "handle_cast({:monitor_scope, :global}... does nothing" do
    # use a seperate agent from the one in setup for this
    {:ok, agent} = Agent.start(fn -> 1 + 1 end)

    {:noreply, :test_state} = Cache.handle_cast({:monitor_scope, :global}, :test_state)
    Agent.stop(agent)

    refute_receive({:DOWN, _, :process, _, :normal})
  end

  # ============================================================================
  # handle_info({:DOWN

  test "handle_info({:DOWN... releases all the pid's keys", %{agent: agent} do
    assert Cache.put("test_key_0", "data_0", agent) == {:ok, "test_key_0"}
    assert Cache.put("test_key_1", "data_1", agent) == {:ok, "test_key_1"}
    assert Cache.claim("test_key_0")
    assert Cache.keys() == ["test_key_0"]
    assert Cache.keys(agent) == ["test_key_0", "test_key_1"]

    {:noreply, :test_state} =
      Cache.handle_info({:DOWN, make_ref(), :process, agent, :normal}, :test_state)

    assert Cache.keys() == ["test_key_0"]
    assert Cache.get("test_key_0") == "data_0"
  end

  # ============================================================================
  # notifications
  
  @cache_registry :scenic_cache_registry
  @cache_put :cache_put
  @cache_delete :cache_delete
  @cache_claim :cache_claim
  @cache_release :cache_release

  test "request & stop notification put" do
    assert Registry.keys( @cache_registry, self() ) == []
    Cache.request_notification( @cache_put )
    assert Registry.keys( @cache_registry, self() ) == [@cache_put]
    Cache.stop_notification( @cache_put )
    assert Registry.keys( @cache_registry, self() ) == []
  end

  test "request & stop notification delete" do
    assert Registry.keys( @cache_registry, self() ) == []
    Cache.request_notification( @cache_delete )
    assert Registry.keys( @cache_registry, self() ) == [@cache_delete]
    Cache.stop_notification( @cache_delete )
    assert Registry.keys( @cache_registry, self() ) == []
  end

  test "request & stop notification claim" do
    assert Registry.keys( @cache_registry, self() ) == []
    Cache.request_notification( @cache_claim )
    assert Registry.keys( @cache_registry, self() ) == [@cache_claim]
    Cache.stop_notification( @cache_claim )
    assert Registry.keys( @cache_registry, self() ) == []
  end

  test "request & stop notification release" do
    assert Registry.keys( @cache_registry, self() ) == []
    Cache.request_notification( @cache_release )
    assert Registry.keys( @cache_registry, self() ) == [@cache_release]
    Cache.stop_notification( @cache_release )
    assert Registry.keys( @cache_registry, self() ) == []
  end

end

# ==============================================================================
# testing init outside of the module above as I'm creating the ets table before each test there.
# this is all about creating the tables in the proper code, so don't interfere with it.
defmodule Scenic.CacheInitTest do
  use ExUnit.Case, async: false
  alias Scenic.Cache

  @cache_table :scenic_cache_key_table
  @scope_table :scenic_cache_scope_table

  test "init creates the cache ets tables" do
    assert :ets.info(@cache_table) == :undefined
    assert :ets.info(@scope_table) == :undefined

    {:ok, _} = Cache.init(nil)

    assert :ets.info(@cache_table) != :undefined
    assert :ets.info(@scope_table) != :undefined
  end
end
