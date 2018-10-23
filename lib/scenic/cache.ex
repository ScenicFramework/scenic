#
#  Created by Boyd Multerer on 2017-11-12.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#
defmodule Scenic.Cache do
  @moduledoc """
  In memory cache for larger assets.

  Static assets such as fonts, images and more tend to be relatively large compared to
  other data. These assets are often used across multiple scenes and may need to be shared
  with multiple drivers.

  These assets also tend to have a significant load cost. Fonts need to be rendered. Images
  interpreted into their final binary form, etc.

  ## Goals

  Given this situation, the Cache module has multiple goals.
  * __Reuse__ - assets used by multiple scenes should only be stored in memory once
  * __Load Time__- loading cost should only be paid once
  * __Copy time__ - assets are stored in ETS, so they don't need to be copied as they are used
  * __Pub/Sub__ - Consumers of static assets (drivers...) should be notified when an asset is
  loaded or changed. They should not poll the system.
  * __Security__ - Static assets can become an attack vector. Helper modules are provided
  to assist in verifying these files.

  ## Scope

  When an asset is loaded into the cache, it is assigned a scope. The scope is used to
  determine how long to hold the asset in memory before it is unloaded. Scope is either
  the atom `:global`, or a `pid`.

  The typical flow is that a scene will load an asset into the cache. A scope is automatically
  defined that tracks the asset against the pid of the scene that loaded it. When the scene
  is closed, the scope becomes empty and the asset is unloaded.

  If, while that scene is loaded, another scene (or any process...) attempts to load
  the same asset into the cache, a second scope is added and the duplicate load is
  skipped. When the first scene closes, the asset stays in memory as long as the second
  scope remains valid.

  When a scene closes, it's scope stays valid for a short time in order to give the next
  scene a chance to load its assets (or claim a scope) and possibly re-use the already
  loaded assets.

  This is also useful in the event of a scene crashing and being restarted. The delay
  in unloading the scope means that the replacement scene will use already loaded
  assets instead of loading the same files again for no real benefit.

  When you load assets you can alternately provide your own scope instead of taking the
  default, which is your processes pid. If you provide `:global`, then the asset will
  stay in memory until you explicitly release it.

  ## Keys

  At its simplest, accessing the cache is a key-value store. When inserting assets
  via the main Cache module, you can supply any term you want as the key. However,
  in most cases this is not recommended.

  The key for an item in the cache should almost always be a SHA hash of the item itself.

  Why? Read below...

  The main exception is dynamic assets, such as video frames coming from a camera.


  ## Security

  A lesson learned the hard way is that static assets (fonts, images, etc) that your app
  loads out of storage can easily become attack vectors.

  These formats are complicated! There is no guarantee (on any system) that a malformed
  asset will not cause an error in the C code that interprets it. Again - these are complicated
  and the renderers need to be fast...

  The solution is to compute a SHA hash of these files during build-time of your
  and to store the result in your applications code itself. Then during run time, you 
  compare then pre-computed hash against the run-time of the asset being loaded.

  Please take advantage of the helper modules [`Cache.File`](Scenic.Cache.File.html),
  [`Cache.Term`](Scenic.Cache.Term.html), and [`Cache.Hash`](Scenic.Cache.Hash.html) to
  do this for you. These modules load files and insert them into the cache while checking
  a precomputed hash.

  These scheme is much stronger when the application code itself is also signed and
  verified, but that is an exercise for the packaging tools.

  Full Example:

      defmodule MyApp.MyScene do
        use Scenic.Scene

        # build the path to the static asset file (compile time)
        @asset_path :code.priv_dir(:my_app) |> Path.join("/static/images/asset.jpg")

        # pre-compute the hash (compile time)
        @asset_hash Scenic.Cache.Hash.file!( @asset_path, :sha )

        # build a graph that uses the asset (compile time)
        @graph Scenic.Graph.build()
        |> rect( {100, 100}, fill: {:image, @asset_hash} )


        def init( _, _ ) {
          # load the asset into the cache (run time)
          Scenic.Cache.File.load(@asset_path, @asset_hash)

          # push the graph. (run time)
          push_graph(@graph)

          {:ok, @graph}
        end

      end

  When assets are loaded this way, the `@asset_hash` term is also used as the key in
  the cache. This has the additional benefit of allowing you to pre-compute
  the graph itself, using the correct keys for the correct assets.

  ## Pub/Sub

  Drivers (or any process...) listen to the Cache via a simple pub/sub api.

  Because the graph, may be computed during compile time and pushed at some
  other time than the assets are loaded, the drivers need to know when the assets
  become available.

  Whenever any asset is loaded into the cache, messages are sent to any
  subscribing processes along with the affected keys. This allows them to react in a
  loosely-coupled way to how the assets are managed in your scene.

  """
  use GenServer

  #  import IEx

  @name :scenic_cache

  @cache_table :scenic_cache_key_table
  @scope_table :scenic_cache_scope_table

  # notifications
  @cache_registry :scenic_cache_registry
  @cache_put :cache_put
  @cache_delete :cache_delete
  @cache_claim :cache_claim
  @cache_release :cache_release

  @default_release_delay 400

  # the format for an element in the cache is
  # {key, ref_count, data}

  # the refcount is needed because multiple scenes may be trying to load/cache
  # same item. Don't want to take the expense of re-loading them.
  # same if it was already set with the :global scope

  # The tables are public, not protected. This is becuase the data being set into
  # them is potentially quite large and I'd rather not send it as a message to this process.
  # If that turns out to be the wrong choice, then change put so that it is a call into
  # this process, passing the data and change the table to protected.

  # ===========================================================================
  defmodule Error do
    @moduledoc """
    Defines the exception thrown by the CacheModule
    """
    defexception message: nil
  end

  # client apis

  @doc """
  Retrieve an item from the Cache.

  This function accepts a key and a default both being any term in Elixir.

  If there is no item in the Cache that corresponds to the key the function will return nil else the
  function returns the term stored in the cache with the using the provided key

  ## Examples
      iex> Scenic.Cache.get("test_key")
      nil

      iex> :ets.insert(:scenic_cache_key_table, {"test_key", 1, :test_data})
      ...> true
      ...> Scenic.Cache.get("test_key")
      :test_data
  """
  @spec get(term(), term()) :: term() | nil
  def get(key, default \\ nil)

  def get(key, default) do
    :ets.lookup_element(@cache_table, key, 3)
  rescue
    ArgumentError ->
      default

    other ->
      reraise(other, __STACKTRACE__)
  end

  @doc """
  Retrieve an item from the cache and wrap it in an {:ok, _} tuple.

  This function ideal if you need to pattern match on the result of getting from the cache.

  ## Examples
      iex> Scenic.Cache.fetch("test_key")
      {:error, :not_found}

      iex> :ets.insert(:scenic_cache_key_table, {"test_key", 1, :test_data})
      ...> true
      ...> Scenic.Cache.fetch("test_key")
      {:ok, :test_data}
  """
  def fetch(key)

  def fetch(key) do
    {:ok, :ets.lookup_element(@cache_table, key, 3)}
  rescue
    ArgumentError ->
      {:error, :not_found}

    other ->
      reraise(other, __STACKTRACE__)
  end

  # --------------------------------------------------------
  @doc """
  Retrieve an item from the Cache and raises an error if it doesn't exist.

  This function accepts a key and a default both being any term in Elixir.

  If there is no item in the Cache that corresponds to the key the function will return nil else the
  function returns the term stored in the cache with the using the provided key

  ## Examples
      iex> Scenic.Cache.get("test_key")
      nil

      iex> :ets.insert(:scenic_cache_key_table, {"test_key", 1, :test_data})
      ...> true
      ...> Scenic.Cache.get("test_key")
      :test_data
  """

  def get!(key)

  def get!(key) do
    :ets.lookup_element(@cache_table, key, 3)
  rescue
    ArgumentError ->
      reraise(Error, [message: "Key #{inspect(key)} not found."], __STACKTRACE__)

    other ->
      reraise(other, __STACKTRACE__)
  end

  # --------------------------------------------------------
  @doc """
  Insert an item into the Cache.

  Parameters:
  * `key` - term to use as the retrieval key. Typically a hash of the data itself.
  * `data` - term to use as the stored data
  * `scope` - Optional scope to track the lifetime of this asset against. Can be `:global`
  but is usually nil, which defaults to the pid of the calling process.

  ## Examples
      iex> Scenic.Cache.get("test_key")
      nil

      iex> :ets.insert(:scenic_cache_key_table, {"test_key", 1, :test_data})
      ...> true
      ...> Scenic.Cache.get("test_key")
      :test_data
  """

  def put(key, data, scope \\ nil)
  def put(key, data, nil), do: do_put(self(), key, data)
  def put(key, data, :global), do: do_put(:global, key, data)
  def put(key, data, name) when is_atom(name), do: do_put(Process.whereis(name), key, data)
  def put(key, data, pid) when is_pid(pid), do: do_put(pid, key, data)

  # --------------------------------------------------------
  @doc """
  Add a scope to an existing asset in the cache.

  Claiming an asset in the cache adds a lifetime scope to it. This is essentially a
  refcount that is bound to a pid.

  Returns `true` if the item is loaded and the scope is added.
  Returns `false` if the asset is not loaded into the cache.
  """

  # return true if the ref was successful
  # return false if not - means the key doesn't exist anywhere and needs to be put
  def claim(key, scope \\ nil)
  def claim(key, nil), do: do_claim(self(), key)
  def claim(key, :global), do: do_claim(:global, key)
  def claim(key, name) when is_atom(name), do: do_claim(Process.whereis(name), key)
  def claim(key, pid) when is_pid(pid), do: do_claim(pid, key)

  # --------------------------------------------------------
  @doc """
  Release a scope claim on an asset.

  Usually the scope is released automatically when a process shuts down. However if you
  want to manually clean up, or unload an asset with the :global scope, then you should
  use release.

  Parameters:
  * `key` - the key to release.
  * `options` - options list

  Options:
  * `scope` - set to `:global` to release the global scope.
  * `delay` - add a delay of n milliseconds before releasing. This allows starting
  processes a chance to claim a scope before it is unloaded.
  """

  # return true if the deref was successful
  # return false if it wasn't ref'd in the first place
  def release(key, opts \\ [])

  def release(key, opts) do
    scope =
      case opts[:scope] do
        nil -> self()
        :global -> :global
        name when is_atom(name) -> Process.whereis(name)
        pid when is_pid(pid) -> pid
      end

    delay =
      case opts[:delay] do
        delay when is_integer(delay) and delay >= 0 -> delay
        nil -> @default_release_delay
      end

    delayed_release(scope, key, delay)
  end

  # --------------------------------------------------------
  @doc """
  Get the current status of an asset in the cache.

  This is used to test if the current process has claimed a scope on an asset.
  """

  def status(key, scope \\ nil)
  def status(key, nil), do: do_status(self(), key)
  def status(key, :global), do: do_status(:global, key)
  def status(key, name) when is_atom(name), do: do_status(Process.whereis(name), key)
  def status(key, pid) when is_pid(pid), do: do_status(pid, key)

  # --------------------------------------------------------
  @doc """
  Returns a list of asset keys claimed by the given scope.
  """
  def keys(scope \\ nil)
  def keys(nil), do: do_keys(self())
  def keys(:global), do: do_keys(:global)
  def keys(name) when is_atom(name), do: do_keys(Process.whereis(name))
  def keys(pid) when is_pid(pid), do: do_keys(pid)

  @doc """
  Tests if a key is claimed by the current scope.
  """
  def member?(key, scope \\ nil) do
    case status(key, scope) do
      {:ok, _} -> true
      {:err, :not_claimed} -> true
      {:err, :not_found} -> false
    end
  end

  # ============================================================================

  # --------------------------------------------------------
  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  # --------------------------------------------------------
  @doc false
  def init(_) do
    state = %{
      cache_table: :ets.new(@cache_table, [:set, :public, :named_table]),
      scope_table: :ets.new(@scope_table, [:bag, :public, :named_table])
    }

    {:ok, state}
  end

  # --------------------------------------------------------
  @doc false
  def handle_cast({:monitor_scope, :global}, state), do: {:noreply, state}

  def handle_cast({:monitor_scope, pid}, state) when is_pid(pid) do
    Process.monitor(pid)
    {:noreply, state}
  end

  # --------------------------------------------------------
  @doc false
  def handle_info({:DOWN, _, :process, scope_pid, _}, state) do
    # a scope process we are monitoring just went down. Clean up after it.
    do_keys(scope_pid)
    |> Enum.each(&delayed_release(scope_pid, &1, @default_release_delay))

    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_info({:delayed_release, key, scope}, state) do
    do_release(scope, key)
    {:noreply, state}
  end

  # ============================================================================
  # private helpers

  # --------------------------------------------------------
  defp do_put(scope, key, data) do
    # Check if the key already exists. If so, overrwrite the data, if not insert it.
    case :ets.member(@cache_table, key) do
      true ->
        :ets.update_element(@cache_table, key, {3, data})
        do_claim(scope, key)

      false ->
        :ets.insert(@cache_table, {key, 1, data})
        :ets.insert(@scope_table, {scope, key, self()})
        # dispatch message to self to monitor the scope
        GenServer.cast(@name, {:monitor_scope, scope})
        # dispatch a put message
        dispatch_notification(@cache_put, key)
    end

    {:ok, key}
  end

  # --------------------------------------------------------
  defp do_claim(scope, key) do
    case :ets.member(@cache_table, key) do
      # the key doesn't exist at all
      false ->
        false

      # they key does exist on some scope somewhere
      true ->
        # a release is happening whether or not there is a put. dispatch a message
        dispatch_notification(@cache_claim, key)

        case key_in_scope?(scope, key) do
          # the key exists, and so does the scoped reference. Do nothing.
          true ->
            true

          false ->
            # they key exists, but not on this scope.
            # add a scope reference and increment the key refcount.
            # the self() data is just for debugging...
            :ets.insert(@scope_table, {scope, key, self()})
            :ets.update_counter(@cache_table, key, {2, 1})
            GenServer.cast(@name, {:monitor_scope, scope})
            true
        end
    end
  end

  # --------------------------------------------------------
  defp delayed_release(scope, key, delay)
  defp delayed_release(scope, key, 0), do: do_release(scope, key)

  defp delayed_release(scope, key, delay) when is_integer(delay) and delay > 0 do
    Process.send_after(@name, {:delayed_release, key, scope}, delay)
  end

  # --------------------------------------------------------
  defp do_release(scope, key) do
    # make sure this reference is valid
    case key_in_scope?(scope, key) do
      false ->
        false

      true ->
        # delete the scope reference
        :ets.match_delete(@scope_table, {scope, key, :_})

        # a release is happening whether or not there is a delete. dispatch a message
        dispatch_notification(@cache_release, key)

        # decrement the key refcount. If it goes to zero, delete it too
        case :ets.update_counter(@cache_table, key, {2, -1}) do
          0 ->
            :ets.delete(@cache_table, key)
            # dispatch a delete message
            dispatch_notification(@cache_delete, key)

          _ ->
            true
        end

        true
    end
  end

  # --------------------------------------------------------
  defp do_status(:global, key) do
    case :ets.member(@cache_table, key) do
      false ->
        {:err, :not_found}

      true ->
        case key_in_scope?(:global, key) do
          true -> {:ok, :global}
          false -> {:err, :not_claimed}
        end
    end
  end

  defp do_status(scope, key) do
    case :ets.member(@cache_table, key) do
      false ->
        {:err, :not_found}

      true ->
        case key_in_scope?(scope, key) do
          true -> {:ok, scope}
          false -> do_status(:global, key)
        end
    end
  end

  # --------------------------------------------------------
  defp do_keys(scope) do
    @scope_table
    |> :ets.match({scope, :"$2", :_})
    |> List.flatten()
  end

  # --------------------------------------------------------
  defp key_in_scope?(scope, key) do
    :ets.match(@scope_table, {scope, key, :_}) != []
  end

  # ============================================================================
  # callback notifications

  # ----------------------------------------------
  @doc """
  Subscribe the calling process to cache messages.

  Pass in the type of messages you want to subscribe to.

  * `:cache_put` - sent when assets are put into the cache
  * `:cache_delete` - sent when assets are fully unloaded from the cache
  * `:cache_claim` - sent when a scope is claimed
  * `:cache_release` - sent when a scope is released
  * `:all` - all of the above message types
  """

  def subscribe(message_type)

  def subscribe(@cache_put), do: Registry.register(@cache_registry, @cache_put, @cache_put)

  def subscribe(@cache_delete),
    do: Registry.register(@cache_registry, @cache_delete, @cache_delete)

  def subscribe(@cache_claim), do: Registry.register(@cache_registry, @cache_claim, @cache_claim)

  def subscribe(@cache_release),
    do: Registry.register(@cache_registry, @cache_release, @cache_release)

  def subscribe(:all) do
    subscribe(@cache_put)
    subscribe(@cache_delete)
    subscribe(@cache_claim)
    subscribe(@cache_release)
  end

  @deprecated "Use Cache.subscribe/1 instead"
  def request_notification(message_type), do: subscribe(message_type)

  # ----------------------------------------------
  @doc """
  Unsubscribe the calling process from cache messages.

  Pass in the type of messages you want to unsubscribe from.

  * `:cache_put` - sent when assets are put into the cache
  * `:cache_delete` - sent when assets are fully unloaded from the cache
  * `:cache_claim` - sent when a scope is claimed
  * `:cache_release` - sent when a scope is released
  * `:all` - all of the above message types
  """
  def unsubscribe(message_type \\ :all)

  def unsubscribe(@cache_put), do: Registry.unregister(@cache_registry, @cache_put)
  def unsubscribe(@cache_delete), do: Registry.unregister(@cache_registry, @cache_delete)
  def unsubscribe(@cache_claim), do: Registry.unregister(@cache_registry, @cache_claim)
  def unsubscribe(@cache_release), do: Registry.unregister(@cache_registry, @cache_release)

  def unsubscribe(:all) do
    unsubscribe(@cache_put)
    unsubscribe(@cache_delete)
    unsubscribe(@cache_claim)
    unsubscribe(@cache_release)
  end

  @deprecated "Use Cache.unsubscribe/1 instead"
  def stop_notification(message_type \\ :all), do: unsubscribe(message_type)

  # ----------------------------------------------
  defp dispatch_notification(action, data) do
    # dispatch the call to any listening drivers
    Registry.dispatch(@cache_registry, action, fn entries ->
      for {pid, _} <- entries do
        try do
          GenServer.cast(pid, {action, data})
        catch
          kind, reason ->
            formatted = Exception.format(kind, reason, System.stacktrace())
            #            Logger.error "Registry.dispatch/3 failed with #{formatted}"
            IO.puts("Scenic.Cache Registry.dispatch/3 failed with #{formatted}")
        end
      end
    end)

    :ok
  end
end
