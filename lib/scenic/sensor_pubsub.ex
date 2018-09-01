#
#  Created by Boyd Multerer on August 20, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#
# Centralized sensor data pub-sub with cache

defmodule Scenic.SensorPubSub do
  use GenServer

 # import IEx

  # ets table names
  @sensor_table       __MODULE__
  @name               __MODULE__


  #============================================================================
  # client api

  #--------------------------------------------------------
  @spec get( sensor_id :: atom ) :: {:ok, any} | {:error, :not_found}
  def get( sensor_id ) when is_atom(sensor_id) do
    case :ets.lookup(@sensor_table, sensor_id) do
      [data] ->
        {:ok, data}
      _ -> # no data
        {:error, :no_data}
    end
  end

  #--------------------------------------------------------
  @spec list() :: list
  def list() do
    :ets.match(@sensor_table, {{:registration, :"$1"}, :"$2", :"$3", :"$4"})
    |> Enum.map(fn([key,ver,des,pid])-> {key,ver,des,pid} end)
  end

  #--------------------------------------------------------
  @spec publish( sensor_id :: atom, data :: any ) :: :ok
  def publish( sensor_id, data ) when is_atom(sensor_id) do
    timestamp = :os.system_time(:micro_seconds)
    pid = self()

    # enforce that this is coming from the registered sensor pid
    case :ets.lookup(@sensor_table, {:registration, sensor_id}) do
      [{_,_,_,^pid}] ->
        send( @name, {:put_data, sensor_id, data, timestamp} )
        :ok
      _ -> # no data
        {:error, :not_registered}
    end
  end

  #--------------------------------------------------------
  @spec subscribe( sensor_id :: atom ) :: :ok
  def subscribe( sensor_id ) when is_atom(sensor_id) do
    GenServer.call( @name, {:subscribe, sensor_id, self()} )
  end

  #--------------------------------------------------------
  @spec unsubscribe( sensor_id :: atom ) :: :ok
  def unsubscribe( sensor_id ) when is_atom(sensor_id) do
    send( @name, {:unsubscribe, sensor_id, self()} )
    :ok
  end

  #--------------------------------------------------------
  @spec register(
    sensor_id :: atom, version :: String.t, description :: String.t
  ) :: :ok
  def register( sensor_id, version, description ) when is_atom(sensor_id) and
  is_bitstring(version) and is_bitstring(description) do
    GenServer.call(
      @name,
      {:register, sensor_id, version, description, self()}
    )
  end

  #--------------------------------------------------------
  @spec unregister( sensor_id :: atom ) :: :ok
  def unregister( sensor_id ) when is_atom(sensor_id) do
    send( @name, {:unregister, sensor_id, self()} )
    :ok
  end





  #============================================================================
  # internal api

  #--------------------------------------------------------
  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: @name)
  end

  #--------------------------------------------------------
  @doc false
  def init( :ok ) do

    # set up the initial state
    state = %{
      data_table_id: :ets.new(@sensor_table, [:named_table]),
      subs_id: %{},
      subs_pid: %{}
    }

    # trap exits so we don't just crash when a subscriber goes away
    Process.flag(:trap_exit, true)

    {:ok, state}
  end



  #============================================================================

  #--------------------------------------------------------
  # a sensor (or whatever) is putting data
  @doc false
  # the client api enforced the pid check
  # yes, you could get around that by sending this message directly
  # not best-practice, but is an escape valve.
  # timestamp should be from :os.system_time(:micro_seconds)
  def handle_info({:put_data, sensor_id, data, timestamp}, state) do
    :ets.insert(@sensor_table, {sensor_id, data, timestamp})
    send_subs( sensor_id, :data, {sensor_id, data, timestamp}, state )
    {:noreply, state }
  end


  #--------------------------------------------------------
  @doc false
  def handle_info({:unsubscribe, sensor_id, pid}, state) do
    {:noreply, unsubscribe(pid, sensor_id, state) }
  end



  #============================================================================
  # handle linked processes going down

  #--------------------------------------------------------
  def handle_info( {:EXIT, pid, reason}, state ) do
    IO.puts "Sensor Cache EXIT. #{inspect(reason)}"

    # unsubscribe everything this pid was listening to
    state = do_unsubscribe(pid, :all, state)

    # if this pid was registered as a sensor, unregister it
    :ets.match(@sensor_table, {{:registration, :"$1"}, :_, :_, pid})
    |> Enum.each(fn([id])-> do_unregister( id, pid, state ) end)

    {:noreply, state }
  end

  #--------------------------------------------------------
  @doc false
  def handle_info({:unregister, sensor_id, pid}, state) do
    do_unregister( sensor_id, pid, state )
    {:noreply, state}
  end



  #============================================================================
  # CALLs - mostly for postive confirmation of sign-up style things

  #--------------------------------------------------------
  @doc false
  def handle_call({:subscribe, sensor_id, pid}, _from, state) do
    {reply, state} = do_subscribe(pid, sensor_id, state)

    # send the already-set value if one is set
    case get( sensor_id ) do
      {:ok, data} -> send_msg( pid, :data, data  )
      _ -> :ok
    end

    {:reply, reply, state }
  end


  #--------------------------------------------------------
  @doc false
  # handle sensor registration
  def handle_call({:register, sensor_id, version, description, pid}, _from, state) do
    key = {:registration, sensor_id}
    {reply, state} = case :ets.lookup(@sensor_table, key) do
      [{_, _, _, ^pid}] -> # registered to pid - ok to change
        do_register( pid, sensor_id, version, description, state )

      [{_, _, _, nil}] -> # previously crashed
        do_register( pid, sensor_id, version, description, state )

      [_] -> # registered to other. fail
        {{:error, :already_registered}, state}

      [] ->
        do_register( pid, sensor_id, version, description, state )
    end
    {:reply, reply, state }
  end



  #============================================================================
  # handle sensor registrations

  #--------------------------------------------------------
  defp do_register( pid, sensor_id, version, description, state ) do
    key = {:registration, sensor_id}
    :ets.insert(@sensor_table, {key, version, description, pid})
    # link the sensor
    Process.link( pid )
    # alert the subscribers
    send_subs( sensor_id, :registered, {sensor_id, version, description}, state )
    # reply is sent back to the sensor
    {{:ok, sensor_id}, state}
  end


  #--------------------------------------------------------
  defp do_unregister( sensor_id, pid, state ) do
    reg_key = {:registration, sensor_id}
    
    # first, get the registration and confirm this pid is registered
    case :ets.lookup(@sensor_table, reg_key) do
      [{_, _, _, ^pid}] ->
        # alert the subscribers
        send_subs( sensor_id, :unregistered, sensor_id, state )

        # delete the table entries
        :ets.delete(@sensor_table, reg_key)
        :ets.delete(@sensor_table, sensor_id)

        unlink_pid( pid, state )
        :ok

      _ -> # no registered. do nothing
        :ok
    end
  end


  #============================================================================
  # handle client subscriptions

  #--------------------------------------------------------
  @spec do_subscribe( pid :: GenServer.server, sensor_id :: atom, state :: map ) :: any
  defp do_subscribe( pid, sensor_id, %{subs_id: subs_id, subs_pid: subs_pid} = state ) do
    # record the subscription
    subs_id = Map.put(
      subs_id, sensor_id,
      [pid | Map.get(subs_id, sensor_id, [])] |> Enum.uniq()
    )
    subs_pid = Map.put(
      subs_pid, pid,
      [sensor_id | Map.get(subs_pid, pid, [])] |> Enum.uniq()
    )

    # make sure the subscriber is linked
    Process.link( pid )

    {:ok, %{state | subs_id: subs_id, subs_pid: subs_pid}}
  end

  #--------------------------------------------------------
  @spec do_unsubscribe( pid :: GenServer.server, sensor_id :: atom, state :: map ) :: any
  defp do_unsubscribe( pid, :all, %{subs_pid: subs_pid} = state ) do
    Map.get(subs_pid, pid, [])
    |> Enum.reduce( state, &unsubscribe(pid, &1, &2) )
  end

  #--------------------------------------------------------
  defp unsubscribe( pid, sensor_id,
    %{subs_id: subs_id, subs_pid: subs_pid} = state
  ) do
    # clean up the subs for a given sensor_id
    subs_by_id = Map.get( subs_id, sensor_id, [] )
    |> Enum.reject(fn(sub_pid)-> sub_pid == pid end)
    subs_id = Map.put( subs_id, sensor_id, subs_by_id )

    # part two
    subs_by_pid = Map.get( subs_pid, pid, [] )
    |> Enum.reject( fn(sub_id)-> sub_id == sensor_id end)
    subs_pid = Map.put( subs_pid, pid, subs_by_pid )

    state = %{state | subs_id: subs_id, subs_pid: subs_pid}

    # if pid no longer subscribed to anything, then some further cleanup
    state = case subs_by_pid do
      [] ->
        {_, state} = pop_in( state, [:subs_pid, pid] )
        state

      _ ->
        state
    end

    # if sensor has no subscribers, then some further cleanup
    state = case subs_by_id do
      [] ->
        {_, state} = pop_in( state, [:subs_id, sensor_id] )
        state

      _ ->
        state
    end

    # does the right thing. only unlinks if no longer subscribing
    # to anything and is not a sensor
    unlink_pid( pid, state )

    state
  end

  #--------------------------------------------------------
  @spec send_subs( sensor_id :: atom, verb :: atom, msg :: any, state :: map ) :: any
  defp send_subs( sensor_id, verb, msg, %{subs_id: subs_id} ) do
    Map.get(subs_id, sensor_id, [])
    |> Enum.each( &send_msg(&1, verb, msg) )
  end

  #--------------------------------------------------------
  @spec send_msg( pid :: GenServer.server, verb :: atom, msg :: any ) :: any
  defp send_msg( pid, verb, msg ) do
    send(pid, {:sensor, verb, msg})
  end


  #--------------------------------------------------------
  # only unlink a pid if it is not a registered sensor AND it
  # has no subscriptions. return the state
  defp unlink_pid( pid, %{subs_pid: subs_pid} ) do
    no_subs = case subs_pid[pid] do
      nil -> true
      [] -> true
      _ -> false
    end
    not_sensor = case :ets.match(@sensor_table, {{:registration, :"$1"}, :_, :_, pid}) do
      [] -> true
      _ -> false
    end
    if no_subs && not_sensor do
      Process.unlink( pid )
    end
  end

end

























