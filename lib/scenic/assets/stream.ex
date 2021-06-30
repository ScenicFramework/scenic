#
#  Created by Boyd Multerer on 2021-04-12
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

# A streaming asset is an asset that changes over time and thus
# cannot be cached, neither on the device itself nor any intermediate servers.
# the best caching we can do is a "most recent snapshot", as long as the
# clients understand this snapshot can be updated at any time.

# These asset snapshots can potentially be large in size (think frames from a camera).
# This means we do not want to pass the data round in messages as that causes memory
# copying, when sent across processes. (Drivers are by nature in separate processes).
# So the data is written into an :ets table that is read optimized, then only the
# name/id of the updated asset is sent via messages to the drivers or any other
# listening process. This allows these processes to retrieve the data when they see fit.

# In this sense, streaming assets most closely resemble the old Cache mechanism.

# Unlike static assets, which use the cryptographic hash to both identify and verify the
# contents of the asset, streaming assets cannot be hashed as they change over time. So
# instead the name can be any string you want. This name is effectively a pub/sub id
# that clients listen to for updates, in addition to accessing the data itself.

defmodule Scenic.Assets.Stream do
  use GenServer

  # alias Scenic.Assets
  alias Scenic.Assets.Stream.Texture

  @type asset :: Texture.t()
  @type id :: String.t()

  # import IEx

  # ===========================================================================
  defmodule Error do
    @moduledoc false
    defexception message: nil, error: nil, id: nil
  end


  # ============================================================================
  # Client API

  @spec exists?( id :: String.t ) :: boolean
  def exists?( id ) when is_bitstring(id) do
    case :ets.lookup(__MODULE__, id) do
      [{^id, _, _}] -> true
      [] -> false
    end
  end

  @spec exists!( id :: String.t() ) :: :ok
  def exists!( id ) when is_bitstring(id) do
    case :ets.lookup(__MODULE__, id) do
      [{^id, _, _}] -> :ok
      [] -> raise Error, message: "Not Found: #{id}", error: :not_found, id: id
    end
  end

  @spec fetch( id :: String.t ) :: {:ok, asset :: asset()} | {:error, :not_found}
  def fetch( id ) when is_bitstring(id) do
    case :ets.lookup(__MODULE__, id) do
      [{_, asset, _}] -> {:ok, asset}
      [] -> {:error, :not_found}
    end
  end

  @spec put( id :: String.t, asset :: asset() ) ::
    :ok | {:error, atom} | {:error, atom, any}
  def put( id, asset ) do
    case validate( asset ) do
      :ok ->
        case :ets.lookup(__MODULE__, id) do
          [{_, ^asset, _}] -> :ok
          _ ->
            true = :ets.insert( __MODULE__, {id, asset, self()} )
            GenServer.cast( __MODULE__, {:put, id} )
        end
      err ->
        err
    end
  end

  @spec delete( id :: String.t ) :: :ok
  def delete( id ) do
    GenServer.cast( __MODULE__, {:delete, id} )
  end

  # subscribing to a streaming asset that doesn't exist yet, still succeeds and
  # will start sending updates if it is published in the future
  @spec subscribe( id :: String.t ) :: :ok
  def subscribe( id ) do
    GenServer.cast( __MODULE__, {:subscribe, self(), id})
  end

  @spec unsubscribe( id :: String.t | :all ) :: :ok
  def unsubscribe( id ) do
    GenServer.cast( __MODULE__, {:unsubscribe, self(), id})
  end



  # ============================================================================
  # formats aren't completely opaque. We can verify some of them

  defp validate( asset )

  defp validate( {:texture, {w, h, :g}, p} ) do
    case byte_size(p) == w * h do
      true -> :ok
      false -> {:error, :invalid}
    end
  end

  defp validate( {:texture, {w, h, :ga}, p} ) do
    case byte_size(p) == w * h * 2 do
      true -> :ok
      false -> {:error, :invalid}
    end
  end

  defp validate( {:texture, {w, h, :rgb}, p} ) do
    case byte_size(p) == w * h * 3 do
      true -> :ok
      false -> {:error, :invalid}
    end
  end

  defp validate( {:texture, {w, h, :rgba}, p} ) do
    case byte_size(p) == w * h * 4 do
      true -> :ok
      false -> {:error, :invalid}
    end
  end

  defp validate( {:texture, {_w, _h, :file}, data} ) do
    case is_binary(data) do
      true -> :ok
      false -> {:error, :invalid}
    end
  end


  # ============================================================================
  # Server API

  # --------------------------------------------------------
  @doc false
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # --------------------------------------------------------
  @doc false
  def init(nil) do
    # create the table. Optimized for reads
    __MODULE__ = :ets.new( __MODULE__, [:named_table, :public, {:read_concurrency, true}] )
    # the state is an empty {by_key, by_pid}
    {:ok, {%{}, %{}} }
  end


  # --------------------------------------------------------
  # a subscriber we are monitoring went down. Clean up.
  @doc false
  def handle_info( {:DOWN, _ref, :process, pid, _reason}, state ) do
    {:noreply, do_unsubscribe(pid, :all, state) }
  end



  # --------------------------------------------------------
  @doc false
  def handle_cast( {:delete, id}, {by_key, _by_pid} = state ) do
    with {:ok, {type_id, _meta, _bin}} <- fetch(id),
    true <- :ets.delete( __MODULE__, id ),
    {:ok, subs} <- Map.fetch(by_key, id) do
      send_subs( subs, :delete, type_id, id )
    end
    { :noreply, state }
  end


  # --------------------------------------------------------
  @doc false
  def handle_cast( {:put, id}, {by_key, _by_pid} = state ) do
    # send a message to this id's subscribers
    with {:ok, subs} <- Map.fetch(by_key, id),
    {:ok, {type_id, _meta, _bin}} <- fetch(id) do
      send_subs( subs, :put, type_id, id )
    end
    { :noreply, state }
  end



  def handle_cast( {:subscribe, pid, id}, {by_key, by_pid} ) do
    # add this id to the pid's subs list
    # also monitor this pid if necessary
    by_pid = case Map.fetch(by_pid, pid) do
      {:ok, {mon, subs}} ->
        Map.put( by_pid, pid, {mon, [id | subs]} )

      :error ->
        # This is a new subscriber
        mon = Process.monitor( pid )
        Map.put( by_pid, pid, {mon, [id]} )
      end

    # add this pid to the id's sub list
    by_key = Map.put( by_key, id, [pid | Map.get(by_key, id, [])] )

    { :noreply, {by_key, by_pid} }
  end

  def handle_cast( {:unsubscribe, pid, id}, state ) do
    state = do_unsubscribe( pid, id, state )
    { :noreply, state }
  end

  defp do_unsubscribe( pid, :all, {_, by_pid} = state ) do
    case Map.fetch( by_pid, pid ) do
      {:ok, {_, subs}} -> Enum.reduce(subs, state, &do_unsubscribe(pid, &1, &2) )
      _ -> state
    end
  end

  defp do_unsubscribe( pid, id, {by_key, by_pid} ) do
    # remove the pid from the by_key map
    pids = Map.get( by_key, id, [] ) |> List.delete( pid )
    by_key = Map.put( by_key, id, pids )

    # remove the id from the by_pid map
    by_pid = case Map.fetch( by_pid, pid ) do
      {:ok, {mon, subs}} ->
        subs
        |> List.delete( id )
        |> case do
          [] ->
            Process.demonitor( mon )
            Map.delete( by_pid, pid )

          subs ->
            Map.put( by_pid, pid, {mon, subs} )
        end

      _ ->
        by_pid
    end

    {by_key, by_pid}
  end


  defp send_subs( subs, verb, type_id, id ) do
    Enum.each(subs, &Process.send(&1, {{__MODULE__, verb}, type_id, id}, []) )
  end

end
