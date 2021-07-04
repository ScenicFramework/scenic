#
#  Created by Boyd Multerer on 2021-04-12
#  Copyright © 2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Assets.Stream do
  @moduledoc """
  Manage streaming assets (for now only compressed images and bitmaps) that are available
  to all Scenes and ViewPorts.

  The `Scenic.Assets.Stream` API gives to access to a running GenServer that manages an
  `:ets` table and subscriptions to changes to named streams. This means that streaming
  assets are available globally to all Scenes and ViewPorts.

  You should be aware that if you have a GenServer that is rapidly updating a stream,
  but no scene's are listening, then you are doing unnecessary work. If you have only a
  single Scene in a single ViewPort listening to that stream, then create the stream
  in the scene.

  If you have multiple Scenes listening to a stream, or the same stream in multiple
  ViewPorts, then create and update the stream in an independent GenServer that you
  manage outside of Scenic.
  """

  # behaviour
  # @callback valid?(asset :: any) :: boolean

  use GenServer

  alias Scenic.Assets.Stream.Image
  alias Scenic.Assets.Stream.Bitmap

  @type asset :: Image.t() | Bitmap.t()
  @type id :: String.t()

  # import IEx

  # ===========================================================================
  defmodule Error do
    @moduledoc false
    defexception message: nil, error: nil, id: nil
  end

  # ============================================================================
  # Client API

  @doc """
  Check if a named stream has been published.

  Returns a boolean indicating if the stream is published.
  """
  @spec exists?(id :: String.t()) :: boolean
  def exists?(id) when is_bitstring(id) do
    case :ets.lookup(__MODULE__, id) do
      [{^id, _, _}] -> true
      [] -> false
    end
  end

  @doc """
  Check if a named stream has been published.

  Returns a `:ok` if the stream is published. Raises an error if it is not.
  """
  @spec exists!(id :: String.t()) :: :ok
  def exists!(id) when is_bitstring(id) do
    case :ets.lookup(__MODULE__, id) do
      [{^id, _, _}] -> :ok
      [] -> raise Error, message: "Not Found: #{id}", error: :not_found, id: id
    end
  end

  @doc """
  Fetch the currently published asset in a named stream.

  Returns `{:ok, asset}` on success.

  Returns `{:error, :not_found}` if the stream is not available.
  """
  @spec fetch(id :: String.t()) :: {:ok, asset :: asset()} | {:error, :not_found}
  def fetch(id) when is_bitstring(id) do
    case :ets.lookup(__MODULE__, id) do
      [{_, asset, _}] -> {:ok, asset}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Put a streamable asset into a named stream.

  If the named stream does not exist yet, it is created. If it already exists, then
  it's content is updated with the asset.

  Returns `:ok` on success.

  Note: Once a stream is create, the asset being updated must be the same type as the
  asset that was originally created. I.e. you can't replace a Bitmap with an Image. This
  will make more sense in the future as other assets types (audio) become supported.

  The contents of the asset is (lightly) validated as it is put into the :ets table.
  If the content is invalid, or a different type than what is already in the stream,
  then it returns `{:error, :invalid, asset_type}`.
  """
  @spec put(id :: String.t(), asset :: asset()) ::
          :ok | {:error, atom} | {:error, atom, any}
  def put(id, {type, _meta, _bin} = asset) do
    case type.valid?(asset) do
      true ->
        case :ets.lookup(__MODULE__, id) do
          [{_, ^asset, _}] ->
            # no change. no work to do
            :ok

          [] ->
            # asset key does not yet exist
            true = :ets.insert(__MODULE__, {id, asset, self()})
            GenServer.cast(__MODULE__, {:put, id})

          [{_, {^type, _, _}, _}] ->
            # is the same type
            true = :ets.insert(__MODULE__, {id, asset, self()})
            GenServer.cast(__MODULE__, {:put, id})

          [{_, {type, _, _}, _}] ->
            # is a different type. reject the put
            {:error, :invalid, type}
        end

      false ->
        {:error, :invalid, type}
    end
  end

  @doc """
  Fully delete a named stream.

  If you recreate the stream after deleting it, you can place any asset type into
  the new stream.
  """
  @spec delete(id :: String.t()) :: :ok
  def delete(id) do
    GenServer.cast(__MODULE__, {:delete, id})
  end

  @doc """
  Subscribe to changes in a named stream.

  Call this from a GenServer, typically a `Driver` or something you manage yourself.

  When an asset stream is updated you will receive the following message.

  `{{Stream, :put}, stream_type, id}`

  You can match against stream_type to select certain kids of assets. Use the id
  to fetch the contents of the asset.

  When an asset stream is deleted, you will receive the following message.
  `{{Stream, :delete}, stream_type, id}`

  You can subscribe to an stream before it has been published. You will then start
  receiving put messages when it is created. Your subscription will not end if the
  stream is deleted.
  """
  # subscribing to a streaming asset that doesn't exist yet, still succeeds and
  # will start sending updates if it is published in the future
  @spec subscribe(id :: String.t()) :: :ok
  def subscribe(id) do
    GenServer.cast(__MODULE__, {:subscribe, self(), id})
  end

  @doc """
  Unsubscribe to changes in a named stream.

  Once your process unsubscribes to a named stream, it will stop receiving all
  messages related to it
  """
  @spec unsubscribe(id :: String.t() | :all) :: :ok
  def unsubscribe(id) do
    GenServer.cast(__MODULE__, {:unsubscribe, self(), id})
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
    __MODULE__ = :ets.new(__MODULE__, [:named_table, :public, {:read_concurrency, true}])
    # the state is an empty {by_key, by_pid}
    {:ok, {%{}, %{}}}
  end

  # --------------------------------------------------------
  # a subscriber we are monitoring went down. Clean up.
  @doc false
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {:noreply, do_unsubscribe(pid, :all, state)}
  end

  # --------------------------------------------------------
  @doc false
  def handle_cast({:delete, id}, {by_key, _by_pid} = state) do
    with {:ok, {type_id, _meta, _bin}} <- fetch(id),
         true <- :ets.delete(__MODULE__, id),
         {:ok, subs} <- Map.fetch(by_key, id) do
      send_subs(subs, :delete, type_id, id)
    end

    {:noreply, state}
  end

  # --------------------------------------------------------
  @doc false
  def handle_cast({:put, id}, {by_key, _by_pid} = state) do
    # send a message to this id's subscribers
    with {:ok, subs} <- Map.fetch(by_key, id),
         {:ok, {type_id, _meta, _bin}} <- fetch(id) do
      send_subs(subs, :put, type_id, id)
    end

    {:noreply, state}
  end

  def handle_cast({:subscribe, pid, id}, {by_key, by_pid}) do
    # add this id to the pid's subs list
    # also monitor this pid if necessary
    by_pid =
      case Map.fetch(by_pid, pid) do
        {:ok, {mon, subs}} ->
          Map.put(by_pid, pid, {mon, [id | subs]})

        :error ->
          # This is a new subscriber
          mon = Process.monitor(pid)
          Map.put(by_pid, pid, {mon, [id]})
      end

    # add this pid to the id's sub list
    by_key = Map.put(by_key, id, [pid | Map.get(by_key, id, [])])

    {:noreply, {by_key, by_pid}}
  end

  def handle_cast({:unsubscribe, pid, id}, state) do
    state = do_unsubscribe(pid, id, state)
    {:noreply, state}
  end

  defp do_unsubscribe(pid, :all, {_, by_pid} = state) do
    case Map.fetch(by_pid, pid) do
      {:ok, {_, subs}} -> Enum.reduce(subs, state, &do_unsubscribe(pid, &1, &2))
      _ -> state
    end
  end

  defp do_unsubscribe(pid, id, {by_key, by_pid}) do
    # remove the pid from the by_key map
    pids = Map.get(by_key, id, []) |> List.delete(pid)
    by_key = Map.put(by_key, id, pids)

    # remove the id from the by_pid map
    by_pid =
      case Map.fetch(by_pid, pid) do
        {:ok, {mon, subs}} ->
          subs
          |> List.delete(id)
          |> case do
            [] ->
              Process.demonitor(mon)
              Map.delete(by_pid, pid)

            subs ->
              Map.put(by_pid, pid, {mon, subs})
          end

        _ ->
          by_pid
      end

    {by_key, by_pid}
  end

  defp send_subs(subs, verb, type_id, id) do
    Enum.each(subs, &Process.send(&1, {{__MODULE__, verb}, type_id, id}, []))
  end
end
