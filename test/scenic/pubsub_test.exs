defmodule Scenic.PubSubTest do
  use ExUnit.Case
  doctest Scenic.PubSub

  alias Scenic.PubSub
  @table Scenic.PubSub

  @data {PubSub, :data}
  @registered {PubSub, :registered}
  @unregistered {PubSub, :unregistered}

  # --------------------------------------------------------
  setup do
    {:ok, svc} = PubSub.start_link(nil)
    on_exit(fn -> Process.exit(svc, :normal) end)
    %{svc: svc}
  end

  # ============================================================================
  # integration style tests

  test "integration - subscribe, register, publish, unregister, get&co" do
    # subscribe
    :ok = PubSub.subscribe(:abc)
    assert PubSub.get(:abc) == nil

    # register
    self = self()
    assert PubSub.list() == []
    {:ok, :abc} = PubSub.register(:abc)
    [{:abc, opts, ^self}] = PubSub.list()
    assert Keyword.get(opts, :registered_at)

    # confirm registration message was received
    assert_receive({@registered, {:abc, ^opts}})
    # confirm no value was sent (none set)
    refute_receive({@data, _})

    # send some data
    :ok = PubSub.publish(:abc, 123)
    # confirm a data message was sent
    assert_receive({@data, {:abc, 123, timestamp}})
    assert is_integer(timestamp)
    [{:abc, 123, ^timestamp}] = :ets.lookup(@table, :abc)

    # get/fetch/query the data
    assert PubSub.get(:abc) == 123
    assert PubSub.fetch(:abc) == {:ok, 123}
    {:ok, {:abc, 123, timestamp}} = PubSub.query(:abc)
    assert is_integer(timestamp)

    # unregister the PubSub
    refute_receive({@unregistered, :abc})
    :ok = PubSub.unregister(:abc)
    assert_receive({@unregistered, :abc})

    # should now fail to publish new data
    assert PubSub.publish(:abc, 456) == {:error, :not_registered}
    refute_receive({@data, {:abc, 456, _}})

    # confirm the table is empty
    assert :ets.lookup(@table, :abc) == []
    assert :ets.lookup(@table, {:registration, :abc}) == []
  end

  test "integration - register, publish, subscribe, unsubscribe, publish" do
    # register
    self = self()
    assert PubSub.list() == []
    {:ok, :abc} = PubSub.register(:abc)
    [{:abc, opts, ^self}] = PubSub.list()
    assert Keyword.get(opts, :registered_at)

    # publish some data
    :ok = PubSub.publish(:abc, 123)
    # confirm a data message was not sent
    refute_receive({@data, _})
    # confirm it is in the table
    [{:abc, 123, timestamp}] = :ets.lookup(@table, :abc)

    # subscribe
    :ok = PubSub.subscribe(:abc)
    # confirm the previous data was sent
    assert_receive({@data, {:abc, 123, ^timestamp}})

    # publish some more data
    :ok = PubSub.publish(:abc, 456)
    # confirm a data message was sent
    # confirm the previous data was sent
    assert_receive({@data, {:abc, 456, timestamp2}})
    refute timestamp == timestamp2

    # unregister the PubSub
    refute_receive({@unregistered, :abc})
    :ok = PubSub.unregister(:abc)
    assert_receive({@unregistered, :abc})

    # should now fail to publish new data
    assert PubSub.publish(:abc, 789) == {:error, :not_registered}
    refute_receive({@data, {:abc, 456, _}})
  end

  test "register enforces the options schema" do
    assert_raise RuntimeError, fn ->
      PubSub.register(:abc, invalid: "some term")
    end
  end
end
