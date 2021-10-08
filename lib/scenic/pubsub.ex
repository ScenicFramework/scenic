#
#  Created by Boyd Multerer on August 20, 2018.
#  Changed to Scenic.PubSub on 2021-06-08
#  Copyright © 2018-2021 Kry10 Limited. All rights reserved.
#
# Centralized channel data pub-sub with cache
# Was originally Scenic.Sensor.

defmodule Scenic.PubSub do
  use GenServer

  @moduledoc """
  `Scenic.PubSub` is a combination pub/sub server and data cache.

  It is intended to be the interface between sensors (or other data sources) and Scenic scenes.

  ## Why Scenic.PubSub

  Sensors (or other data sources) and scenes often need to communicate, but tend to operate on different timelines.

  Some sensors update fairly slowly or don't behave well when asked to get data at random times by multiple clients.
  `Scenic.PubSub` is backed by a `GenServer` that collects data from a data source in a well-behaved manner,
  yet is able to serve that data on demand or by subscription to many clients.


  ## Global Scope

  It is important to note that `Scenic.PubSub` is global in scope. In other words, anything published
  into `Scenic.PubSub` is visible to all `ViewPorts` and `Scenes`.

  ## Registering Data Sources

  Before a process can start publishing data from a source, it must register a source id with `Scenic.PubSub`.
  This source id should be an atom. This prevents other processes from stepping on that data and alerts any
  subscribing processes that the data is coming online.

        Scenic.PubSub.register( source_id )

  The `source_id` parameter must be an atom that names the sensor. Subscribers will use this id to request
  data or subscriptions to the source.

  You can can also unregister data sources if they are no longer available.

        Scenic.PubSub.unregister( source_id )

  Simply exiting the data source process does also cleans up its registration.


  ## Publishing Data

  When a sensor process publishes data, two things happen. First, that data is cached in an `:ets` table so
  that future requests for that data from scenes happen quickly and don't need to bother the data
  source process. Second, any processes that have subscribed to that source are sent a message containing the new data.

        Scenic.PubSub.publish( source_id, value )

  The `source_id` parameter must be the atom that was previously registered.

  The `value` parameter can be anything that makes sense for the data source.


  ## Subscribing to a Data Source

  Scenes (or any other process) can subscribe to a data source. They will receive messages when the source updates its data, comes online, or goes away.

        Scenic.PubSub.subscribe( source_id )

  The `source_id` parameter is the atom registered for the data source. Note that the name source does NOT
  need to be registered when a listening process subscribes to it. When the source process eventually registers and
  starts publishing data, the listening subscribers will be notified.


  The subscribing process will then start receiving messages that can be handled with `handle_info/2`

  event | message sent to subscribers
  --- | ---
  data published | `{{Scenic.PubSub, :data}, {source_id, value, timestamp}}` 
  source registered | `{{Scenic.PubSub, :registered}, {source_id, opts}}` 
  source unregistered | `{{Scenic.PubSub, :unregistered}, source_id}` 



  Scenes can also unsubscribe if they are no longer interested in updates.

        Scenic.PubSub.unsubscribe( source_id )

  ## Other functions

  Any process can get data from a source on demand, whether or not it is a subscriber.

        Scenic.PubSub.get( source_id )
        >> {:ok, data}

  Any process can list the currently registered data sources.

        Scenic.PubSub.list()
        >> [{source_id, opts, pid}]
  """

  # ets table names
  @table __MODULE__
  @name __MODULE__

  @data {__MODULE__, :data}
  @registered {__MODULE__, :registered}
  @unregistered {__MODULE__, :unregistered}

  defmodule Error do
    @moduledoc false
    defexception message: nil, source_id: nil
  end

  # ============================================================================
  # client api

  # --------------------------------------------------------
  @doc """
  Retrieve the cached data value for a named data source.

  This data is pulled from an `:ets` table and does not put load on the data source itself.

  ## Parameters
  * `source_id` an atom that is registered to a data source.

  ## Return Value

        data

  If the data source is either not registered, or has not yet published any data, get returns

        nil
  """

  @spec get(source_id :: atom) :: any | nil
  def get(source_id) when is_atom(source_id) do
    case :ets.lookup(@table, source_id) do
      [{_key, data, _timestamp}] -> data
      _ -> nil
    end
  end

  # --------------------------------------------------------
  @doc """
  Retrieve the cached data value for a named data source.

  Raises an error if the value is not registered

  This data is pulled from an `:ets` table and does not put load on the data source itself.

  ## Parameters
  * `source_id` an atom that is registered to a data source.

  ## Return Value

        data

  If the data source is either not registered, or has not yet published any data, get returns

        nil
  """

  @spec get!(source_id :: atom) :: any
  def get!(source_id) when is_atom(source_id) do
    case fetch(source_id) do
      {:ok, data} -> data
      _ -> raise Error, message: "#{inspect(source_id)} is not registered", source_id: source_id
    end
  end

  # --------------------------------------------------------
  @doc """
  Retrieve the cached data for a named data source.

  This data is pulled from an `:ets` table and does not put load on the data source itself.

  ## Parameters
  * `source_id` an atom that is registered to a data source.

  ## Return Value

        {:ok, {source_id, data, timestamp}}

  * `source_id` is the atom representing the data source.
  * `data` source_id whatever data the data source last published.
  * `timestamp` is the time - from `:os.system_time(:micro_seconds)` - the last data was published.

  If the data source is either not registered, or has not yet published any data, get returns

        {:error, :no_data} 
  """

  @spec fetch(source_id :: atom) :: {:ok, any} | {:error, :not_found}
  def fetch(source_id) when is_atom(source_id) do
    case :ets.lookup(@table, source_id) do
      [{_key, data, _timestamp}] ->
        {:ok, data}

      # no data
      _ ->
        {:error, :not_found}
    end
  end

  # --------------------------------------------------------
  @doc """
  Retrieve the full cached data for a named data source.

  This data is pulled from an `:ets` table and does not put load on the data source itself.

  ## Parameters
  * `source_id` an atom that is registered to a data source.

  ## Return Value

        {:ok, {source_id, data, timestamp}}

  * `source_id` is the atom representing the data source.
  * `data` source_id whatever data the data source last published.
  * `timestamp` is the time - from `:os.system_time(:micro_seconds)` - the last data was published.

  If the data source is either not registered, or has not yet published any data, get returns

        {:error, :not_found} 
  """

  @spec query(source_id :: atom) :: {:ok, any} | {:error, :not_found}
  def query(source_id) when is_atom(source_id) do
    case :ets.lookup(@table, source_id) do
      [data] ->
        {:ok, data}

      # no data
      _ ->
        {:error, :not_found}
    end
  end

  # --------------------------------------------------------
  @doc """
  List the registered data sources.

  ## Return Value

  `list/0` returns a list of registered data sources

        [{source_id, version, description, pid}]

  * `source_id` is the atom representing the data source.
  * `opts` options list of metadata about the data source.
    * `:version` is the version string supplied by the data source during registration.
    * `:description` is the description string supplied by the data source during registration.
    * `:registered_at` The system time the data source was registered at.
  * `pid` is the pid of the data source's process.
  """
  @spec list() :: [{atom, Keyword.t(), pid}]
  def list() do
    :ets.match(@table, {{:registration, :"$1"}, :"$2", :"$3"})
    |> Enum.map(fn [key, opts, pid] -> {key, opts, pid} end)
  end

  # --------------------------------------------------------
  @doc """
  Publish a data point from a data source.

  When a data source uses `publish/2` to publish data, that data is recorded in the
  cache and a
        {{Scenic.PubSub, :data}, {source_id, my_value, timestamp}}
  message is sent to each subscriber. The timestamp is the current time in microseconds as returned
  from `:os.system_time(:micro_seconds)`.

  ## Parameters
  * `source_id` an atom that is registered to a data source.
  * `data` the data to publish.

  ## Return Value

  On success, returns `:ok`

  It returns `{:error, :not_registered}` if the caller is not the
  registered process for the data source.
  """
  @spec publish(source_id :: atom, data :: any) :: :ok
  def publish(source_id, data) when is_atom(source_id) do
    timestamp = :os.system_time(:micro_seconds)
    pid = self()

    # enforce that this is coming from the registered data source pid
    case :ets.lookup(@table, {:registration, source_id}) do
      [{_, _, ^pid}] ->
        send(@name, {:put_data, source_id, data, timestamp})
        :ok

      # no data
      _ ->
        {:error, :not_registered}
    end
  end

  # --------------------------------------------------------
  @doc """
  Subscribe the calling process to receive events about a data source.

  The messages the subscriber will start receiving about a data source are:

  event | message sent to subscribers
  --- | ---
  data published | `{{Scenic.PubSub, :data}, {source_id, value, timestamp}}` 
  source registered | `{{Scenic.PubSub, :registered}, {source_id, opts}}` 
  source unregistered | `{{Scenic.PubSub, :unregistered}, source_id}` 

  ## Parameters
  * `source_id` an atom that is registered to a data source.

  ## Return Value

  On success, returns `:ok`
  """
  @spec subscribe(source_id :: atom) :: :ok
  def subscribe(source_id) when is_atom(source_id) do
    GenServer.call(@name, {:subscribe, source_id, self()})
  end

  # --------------------------------------------------------
  @doc """
  Unsubscribe the calling process from receive events about a data source.

  The caller will stop receiving events about a data source

  ## Parameters
  * `source_id` an atom that is registered to a data source.

  ## Return Value

  Returns `:ok`
  """
  @spec unsubscribe(source_id :: atom) :: :ok
  def unsubscribe(source_id) when is_atom(source_id) do
    send(@name, {:unsubscribe, source_id, self()})
    :ok
  end

  # --------------------------------------------------------
  @register_opts_schema [
    version: [type: :string, doc: "Data format version"],
    description: [type: :string, doc: "Your appropriate description"]
  ]
  @doc """
  Register the calling process as a data source for the named id.

  ## Parameters
  * `source_id` the data source being registered.
  * `opts` optional information about the data source.

  Supported options:\n#{NimbleOptions.docs(@register_opts_schema)}

  ## Return Value

  On success, returns `{:ok, source_id}`

  If `source_id` is already registered to another process, it returns

      {:error, :already_registered}
  """
  @spec register(source_id :: atom, opts :: Keyword.t()) ::
          {:ok, atom} | {:error, :already_registered}
  def register(source_id, opts \\ []) when is_atom(source_id) do
    opts = Enum.into( opts, [] )
    case NimbleOptions.validate(opts, @register_opts_schema) do
      {:ok, opts} -> opts
      {:error, error} -> raise Error, message: error, source_id: source_id
    end

    opts = Keyword.put(opts, :registered_at, :os.system_time(:micro_seconds))

    GenServer.call(
      @name,
      {:register, source_id, opts, self()}
    )
  end

  # --------------------------------------------------------
  @doc """
  Unregister the calling process as a data source for a data source.

  ## Parameters
  * `source_id` the data source being registered.

  ## Return Value

  Returns `:ok`
  """
  @spec unregister(source_id :: atom) :: :ok
  def unregister(source_id) when is_atom(source_id) do
    send(@name, {:unregister, source_id, self()})
    :ok
  end

  # ============================================================================
  # internal api

  # --------------------------------------------------------
  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  # --------------------------------------------------------
  @doc false
  def init(:ok) do
    # set up the initial state
    state = %{
      data_table_id: :ets.new(@table, [:named_table]),
      subs_id: %{},
      subs_pid: %{}
    }

    # trap exits so we don't just crash when a subscriber goes away
    Process.flag(:trap_exit, true)

    {:ok, state}
  end

  # ============================================================================

  # --------------------------------------------------------
  # a data source (or whatever) is putting data
  @doc false
  # the client api enforced the pid check
  # yes, you could get around that by sending this message directly
  # not best-practice, but is an escape valve.
  # timestamp should be from :os.system_time(:micro_seconds)
  def handle_info({:put_data, source_id, data, timestamp}, state) do
    :ets.insert(@table, {source_id, data, timestamp})
    send_subs(source_id, @data, {source_id, data, timestamp}, state)
    {:noreply, state}
  end

  # --------------------------------------------------------
  @doc false
  def handle_info({:unsubscribe, source_id, pid}, state) do
    {:noreply, unsubscribe(pid, source_id, state)}
  end

  # ============================================================================
  # handle linked processes going down

  # --------------------------------------------------------
  def handle_info({:EXIT, pid, _reason}, state) do
    # unsubscribe everything this pid was listening to
    state = do_unsubscribe(pid, :all, state)

    # if this pid was registered as a data source, unregister it
    :ets.match(@table, {{:registration, :"$1"}, :_, :_, pid})
    |> Enum.each(fn [id] -> do_unregister(id, pid, state) end)

    {:noreply, state}
  end

  # --------------------------------------------------------
  @doc false
  def handle_info({:unregister, source_id, pid}, state) do
    do_unregister(source_id, pid, state)
    {:noreply, state}
  end

  # ============================================================================
  # CALLs - mostly for postive confirmation of sign-up style things

  # --------------------------------------------------------
  @doc false
  def handle_call({:subscribe, source_id, pid}, _from, state) do
    {reply, state} = do_subscribe(pid, source_id, state)

    # send the already-set value if one is set
    case query(source_id) do
      {:ok, data} -> send(pid, {@data, data})
      _ -> :ok
    end

    {:reply, reply, state}
  end

  # --------------------------------------------------------
  @doc false
  # handle data source registration
  def handle_call({:register, source_id, opts, pid}, _from, state) do
    key = {:registration, source_id}

    {reply, state} =
      case :ets.lookup(@table, key) do
        # registered to pid - ok to change
        [{_, _, ^pid}] ->
          do_register(pid, source_id, opts, state)

        # previously crashed
        [{_, _, nil}] ->
          do_register(pid, source_id, opts, state)

        # registered to other. fail
        [_] ->
          {{:error, :already_registered}, state}

        [] ->
          do_register(pid, source_id, opts, state)
      end

    {:reply, reply, state}
  end

  # ============================================================================
  # handle data source registrations

  # --------------------------------------------------------
  defp do_register(pid, source_id, opts, state) do
    key = {:registration, source_id}
    :ets.insert(@table, {key, opts, pid})
    # link the data source
    Process.link(pid)
    # alert the subscribers
    send_subs(source_id, @registered, {source_id, opts}, state)
    # reply is sent back to the data source
    {{:ok, source_id}, state}
  end

  # --------------------------------------------------------
  defp do_unregister(source_id, pid, state) do
    reg_key = {:registration, source_id}

    # first, get the registration and confirm this pid is registered
    case :ets.lookup(@table, reg_key) do
      [{_, _, ^pid}] ->
        # alert the subscribers
        send_subs(source_id, @unregistered, source_id, state)

        # delete the table entries
        :ets.delete(@table, reg_key)
        :ets.delete(@table, source_id)

        unlink_pid(pid, state)
        :ok

      # no registered. do nothing
      _ ->
        :ok
    end
  end

  # ============================================================================
  # handle client subscriptions

  # --------------------------------------------------------
  @spec do_subscribe(pid :: GenServer.server(), source_id :: atom, state :: map) :: any
  defp do_subscribe(pid, source_id, %{subs_id: subs_id, subs_pid: subs_pid} = state) do
    # record the subscription
    subs_id =
      Map.put(
        subs_id,
        source_id,
        [pid | Map.get(subs_id, source_id, [])] |> Enum.uniq()
      )

    subs_pid =
      Map.put(
        subs_pid,
        pid,
        [source_id | Map.get(subs_pid, pid, [])] |> Enum.uniq()
      )

    # make sure the subscriber is linked
    Process.link(pid)

    {:ok, %{state | subs_id: subs_id, subs_pid: subs_pid}}
  end

  # --------------------------------------------------------
  @spec do_unsubscribe(pid :: GenServer.server(), source_id :: atom, state :: map) :: any
  defp do_unsubscribe(pid, :all, %{subs_pid: subs_pid} = state) do
    Map.get(subs_pid, pid, [])
    |> Enum.reduce(state, &unsubscribe(pid, &1, &2))
  end

  # --------------------------------------------------------
  defp unsubscribe(pid, source_id, %{subs_id: subs_id, subs_pid: subs_pid} = state) do
    # clean up the subs for a given source_id
    subs_by_id =
      Map.get(subs_id, source_id, [])
      |> Enum.reject(fn sub_pid -> sub_pid == pid end)

    subs_id = Map.put(subs_id, source_id, subs_by_id)

    # part two
    subs_by_pid =
      Map.get(subs_pid, pid, [])
      |> Enum.reject(fn sub_id -> sub_id == source_id end)

    subs_pid = Map.put(subs_pid, pid, subs_by_pid)

    state = %{state | subs_id: subs_id, subs_pid: subs_pid}

    # if pid no longer subscribed to anything, then some further cleanup
    state =
      case subs_by_pid do
        [] ->
          {_, state} = pop_in(state, [:subs_pid, pid])
          state

        _ ->
          state
      end

    # if channel has no subscribers, then some further cleanup
    state =
      case subs_by_id do
        [] ->
          {_, state} = pop_in(state, [:subs_id, source_id])
          state

        _ ->
          state
      end

    # does the right thing. only unlinks if no longer subscribing
    # to anything and is not a channel
    unlink_pid(pid, state)

    state
  end

  # --------------------------------------------------------
  defp send_subs(source_id, verb, msg, %{subs_id: subs}) do
    msg = {verb, msg}

    subs
    |> Map.get(source_id, [])
    |> Enum.each(&send(&1, msg))
  end

  # --------------------------------------------------------
  # only unlink a pid if it is not a registered channel AND it
  # has no subscriptions. return the state
  defp unlink_pid(pid, %{subs_pid: subs_pid}) do
    no_subs =
      case subs_pid[pid] do
        nil -> true
        [] -> true
        _ -> false
      end

    not_sensor =
      case :ets.match(@table, {{:registration, :"$1"}, :_, pid}) do
        [] -> true
        _ -> false
      end

    if no_subs && not_sensor do
      Process.unlink(pid)
    end
  end
end
