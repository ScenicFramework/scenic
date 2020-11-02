#
#  Created by Boyd Multerer on 2019-03-04.
#  Copyright © 2019 Kry10 Industries. All rights reserved.
#
defmodule Scenic.Cache.Base do
  @moduledoc """
  Base module for static asset caches.

  This module is not intended to be used directly. To access items in the
  static cache, refer to the modules for the type of data you are
  interested in.

  | Asset Class   | Module  |
  | ------------- | -----|
  | Fonts      | `Scenic.Cache.Static.Font` |
  | Font Metrics | `Scenic.Cache.Static.FontMetrics` |
  | Textures (images in a fill) | `Scenic.Cache.Static.Texture` |
  | Raw Pixel Maps | `Scenic.Cache.Dynamic.Texture` |

  Some of the Cache support modules have moved

  | Old Module   | New Module  |
  | ------------- | -----|
  | `Scenic.Cache.Hash` | `Scenic.Cache.Support.Hash` |
  | `Scenic.Cache.File` | `Scenic.Cache.Support.File` |
  | `Scenic.Cache.Supervisor` | `Scenic.Cache.Support.Supervisor` |

  ## Overview

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

  A lesson learned the hard way is that static assets (fonts, images, etc.) that your app
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
        import Scenic.Primitives

        # build the path to the static asset file (compile time)
        @asset_path :code.priv_dir(:my_app)
        |> Path.join("/static/images/asset.jpg")

        # pre-compute the hash (compile time)
        @asset_hash Scenic.Cache.Hash.file!( @asset_path, :sha )

        # build a graph that uses the asset (compile time)
        @graph Scenic.Graph.build()
        |> rect( {100, 100}, fill: {:image, @asset_hash} )


        def init( _, _ ) do
          # load the asset into the cache (run time)
          Scenic.Cache.Static.Texture.load(@asset_path, @asset_hash)

          {:ok, :some_state, push: @graph}
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

  # import IEx

  @type hash :: String.t()

  @type sub_types ::
          :put
          | :delete
          | :all

  @default_release_delay 400

  # ===========================================================================
  defmodule Error do
    @moduledoc """
    Defines the exception thrown by the CacheModule
    """
    defexception message: nil
  end

  # ============================================================================
  # callback definitions

  @callback load(file_path :: String.t(), hash_name :: String.t(), options :: list) ::
              {:ok, data :: any()} | {:error, error :: atom}

  @callback load!(file_path :: String.t(), hash_name :: String.t(), options :: list) ::
              data :: any()

  # ============================================================================
  # using macro

  # ===========================================================================
  # the using macro for scenes adopting this behavior
  defmacro __using__(using_opts \\ []) do
    quote do
      if unquote(using_opts)[:static] do
        @behaviour Scenic.Cache.Base
      end

      unless unquote(using_opts)[:name] do
        raise "You must supply a :name option to the \"use Scenic.Cache.Base\" macro."
      end

      # --------------------------------------------------------
      @doc """
      Retrieve a #{unquote(using_opts)[:name]} from the Cache.

      If there is no item in the Cache that corresponds to the hash the function will return
      either nil or the supplied default value

      ## Examples
          iex> #{__MODULE__}.get("missing_hash")
          nil

          ...> #{__MODULE__}.fetch("valid_hash")
          {:ok, :test_data}
      """
      @spec get(hash :: Scenic.Cache.Base.hash(), default :: term()) :: term() | nil
      def get(hash, default \\ nil) do
        Scenic.Cache.Base.get(__MODULE__, hash, default)
      end

      # --------------------------------------------------------
      @doc """
      Retrieve a #{unquote(using_opts)[:name]} from the cache and wrap it in an `{:ok, _}` tuple.

      This function ideal if you need to pattern match on the result.

      ## Examples
          iex> #{__MODULE__}.fetch("missing_hash")
          ...> {:error, :not_found}

          iex> #{__MODULE__}.fetch("valid_hash")
          ...> {:ok, :test_data}
      """
      @spec fetch(hash :: Scenic.Cache.Base.hash()) :: term() | {:error, :not_found}
      def fetch(hash) do
        Scenic.Cache.Base.fetch(__MODULE__, hash)
      end

      # --------------------------------------------------------
      @doc """
      Retrieve a #{unquote(using_opts)[:name]} from the Cache and raise an error if it doesn't exist.

      If there is no item in the Cache that corresponds to the hash the function will raise an error.
      """
      @spec get!(hash :: Scenic.Cache.Base.hash()) :: term()
      def get!(hash) do
        Scenic.Cache.Base.get!(__MODULE__, hash)
      end

      # put is not to be inserted into static-item caches
      unless unquote(using_opts)[:static] do
        # --------------------------------------------------------
        @doc """
        Insert #{unquote(using_opts)[:name]} into the Cache.

        If the #{unquote(using_opts)[:name]} is already in the cache, its data
        is overwritten.

        Parameters:
        * `hash` - term to use as the retrieval key. Typically a hash of the data itself.
          It will be required to be a hash of the data in the future.
        * `data` - term to use as the stored data
        * `scope` - Optional scope to track the lifetime of this asset against. Can be `:global`
        but is usually nil, which defaults to the pid of the calling process.

        Returns: `{:ok, hash}`
        """
        @spec put(
                hash :: Scenic.Cache.Base.hash(),
                data :: term(),
                scope :: :global | nil | GenServer.server()
              ) :: term()
        def put(hash, data, scope \\ nil) do
          Scenic.Cache.Base.put(__MODULE__, hash, data, scope)
        end
      end

      # --------------------------------------------------------
      @doc """
      Insert a new #{unquote(using_opts)[:name]} into the Cache.

      If the #{unquote(using_opts)[:name]} is already in the cache, put_new
      does nothing and just returns {:ok, hash}

      Parameters:
      * `hash` - term to use as the retrieval key. Typically a hash of the data itself.
        It will be required to be a hash of the data in the future.
      * `data` - term to use as the stored data
      * `scope` - Optional scope to track the lifetime of this asset against. Can be `:global`
      but is usually nil, which defaults to the pid of the calling process.

      Returns: `{:ok, hash}`
      """
      @spec put_new(
              hash :: Scenic.Cache.Base.hash(),
              data :: term(),
              scope :: :global | nil | GenServer.server()
            ) :: term()
      case unquote(using_opts)[:static] do
        true ->
          def put_new(hash, data, scope \\ nil) do
            case member?(hash) do
              false -> Scenic.Cache.Base.put(__MODULE__, hash, data, scope)
              true -> {:ok, hash}
            end
          end

        false ->
          def put_new(hash, data, scope \\ nil) do
            case member?(hash) do
              false -> put(hash, data, scope)
              true -> {:ok, hash}
            end
          end
      end

      # --------------------------------------------------------
      @doc """
      Add a scope to an existing #{unquote(using_opts)[:name]} in the cache.

      Claiming an asset in the cache adds a lifetime scope to it. This is essentially a
      refcount that is bound to a pid.

      Returns `true` if the item is loaded and the scope is added.
      Returns `false` if the asset is not loaded into the cache.
      """
      @spec claim(
              hash :: Scenic.Cache.Base.hash(),
              scope :: :global | nil | GenServer.server()
            ) :: term()
      def claim(hash, scope \\ nil) do
        Scenic.Cache.Base.claim(__MODULE__, hash, scope)
      end

      # --------------------------------------------------------
      @doc """
      Release a scope claim on an #{unquote(using_opts)[:name]}.

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

      # returns :ok
      @spec release(
              hash :: Scenic.Cache.Base.hash(),
              opts :: list
            ) :: :ok

      def release(hash, opts \\ []) do
        Scenic.Cache.Base.release(__MODULE__, hash, opts)
      end

      # --------------------------------------------------------
      @doc """
      Get the current status of a #{unquote(using_opts)[:name]} in the cache.

      This is used to test if the current process has claimed a scope on an asset.
      """
      @spec status(
              hash :: Scenic.Cache.Base.hash(),
              scope :: :global | nil | GenServer.server()
            ) :: :ok
      def status(hash, scope \\ nil) do
        Scenic.Cache.Base.status(__MODULE__, hash, scope)
      end

      # --------------------------------------------------------
      @doc """
      Returns a list of keys claimed by the given scope.
      """
      @spec keys(scope :: :global | nil | GenServer.server()) :: list
      def keys(scope \\ nil) do
        Scenic.Cache.Base.keys(__MODULE__, scope)
      end

      # --------------------------------------------------------
      @doc """
      Tests if a key is claimed by *any* scope.
      """
      @spec member?(hash :: Scenic.Cache.Base.hash()) :: true | false
      def member?(hash) do
        Scenic.Cache.Base.member?(__MODULE__, hash)
      end

      # --------------------------------------------------------
      @doc """
      Tests if a key is claimed by the given scope.
      """
      @spec claimed?(
              hash :: Scenic.Cache.Base.hash(),
              scope :: :global | nil | GenServer.server()
            ) :: true | false
      def claimed?(hash, scope \\ nil) do
        Scenic.Cache.Base.claimed?(__MODULE__, hash, scope)
      end

      # ----------------------------------------------
      @doc """
      Subscribe the calling process to cache messages.

      Parameters
      * `hash` - The hash key of the asset you want to listen to messages about. Pass
        in :all for messages about all keys
      * `sub_type` - Pass in the type of messages you want to unsubscribe from.
        * `:put` - sent when assets are put into the cache
        * `:delete` - sent when assets are fully unloaded from the cache
        * `:claim` - sent when a scope is claimed
        * `:release` - sent when a scope is released
        * `:all` - all of the above message types
      """
      @spec subscribe(
              hash :: Scenic.Cache.Base.hash() | :all,
              sub_type :: Scenic.Cache.Base.sub_types()
            ) :: :ok

      def subscribe(hash, sub_type \\ :all) do
        Scenic.Cache.Base.subscribe(__MODULE__, hash, sub_type)
      end

      # ----------------------------------------------
      @doc """
      Unsubscribe the calling process from cache messages.

      Parameters
      * `hash` - The hash key of the asset you want to listen to messages about. Pass
        in :all for messages about all keys
      * `sub_type` - Pass in the type of messages you want to unsubscribe from.
        * `:put` - sent when assets are put into the cache
        * `:delete` - sent when assets are fully unloaded from the cache
        * `:claim` - sent when a scope is claimed
        * `:release` - sent when a scope is released
        * `:all` - all of the above message types

      """
      @spec unsubscribe(
              hash :: Scenic.Cache.Base.hash() | :all,
              sub_type :: Scenic.Cache.Base.sub_types()
            ) :: :ok

      def unsubscribe(hash, sub_type \\ :all) do
        Scenic.Cache.Base.unsubscribe(__MODULE__, hash, sub_type)
      end

      # --------------------------------------------------------
      # child spec that really starts up the cache
      @doc false
      def child_spec(_) do
        %{
          # make_ref(),
          id: __MODULE__,
          start: {Scenic.Cache.Base, :start_link, [__MODULE__, unquote(using_opts)[:name]]},
          type: :worker,
          restart: :permanent,
          shutdown: 500
        }
      end

      # --------------------------------------------------------
      # add local shortcuts to things like get/put graph and modify element
      # do not add a put element. keep it at modify to stay atomic
      # --------------------------------------------------------
      case unquote(using_opts)[:static] do
        true -> [get: 1, get: 2, get!: 1, fetch: 1, put_new: 3]
        _ -> [get: 1, get: 2, get!: 1, fetch: 1, put_new: 3, put: 3]
      end
      |> defoverridable()
    end
  end

  # ============================================================================
  # client API

  # --------------------------------------------------------
  @doc """
  Retrieve an item from the Cache.

  If there is no item in the Cache that corresponds to the hash the function will return
  either nil or the supplied default value
  """
  @spec get(
          service :: atom,
          hash :: Scenic.Cache.Base.hash(),
          default :: term()
        ) :: term() | nil

  def get(service, hash, default \\ nil) do
    :ets.lookup_element(service, hash, 2)
  rescue
    ArgumentError ->
      default

    other ->
      reraise(other, __STACKTRACE__)
  end

  # --------------------------------------------------------
  @doc """
  Retrieve an item from the cache and wrap it in an `{:ok, _}` tuple.

  This function ideal if you need to pattern match on the result.
  """
  @spec fetch(
          service :: atom,
          hash :: Scenic.Cache.Base.hash()
        ) :: term() | {:error, :not_found}
  def fetch(service, hash)

  def fetch(service, hash) do
    {:ok, :ets.lookup_element(service, hash, 2)}
  rescue
    ArgumentError ->
      {:error, :not_found}

    other ->
      reraise(other, __STACKTRACE__)
  end

  # --------------------------------------------------------
  @doc """
  Retrieve an item from the Cache and raise an error if it doesn't exist.

  If there is no item in the Cache that corresponds to the hash the function will raise an error.
  """
  @spec get!(
          service :: atom,
          hash :: Scenic.Cache.Base.hash()
        ) :: term()

  def get!(service, hash)

  def get!(service, hash) do
    :ets.lookup_element(service, hash, 2)
  rescue
    ArgumentError ->
      reraise(Error, [message: "Hash #{inspect(hash)} not found."], __STACKTRACE__)

    other ->
      reraise(other, __STACKTRACE__)
  end

  # --------------------------------------------------------
  @doc """
  Insert an item into the Cache. If it is already in the cache, then it
  overwrites the data {:ok, hash}

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
  @spec put(
          service :: atom,
          hash :: Scenic.Cache.Base.hash(),
          data :: term(),
          scope :: :global | nil | GenServer.server()
        ) :: term()

  def put(service, key, data, scope \\ nil)
      when service != nil and (is_atom(service) or is_pid(service)) do
    GenServer.call(service, {:put, normalize_scope(scope), key, data})
  end

  # --------------------------------------------------------
  @doc """
  Add a scope to an existing asset in the cache.

  Claiming an asset in the cache adds a lifetime scope to it. This is essentially a
  refcount that is bound to a pid.

  Returns `true` if the item is loaded and the scope is added.
  Returns `false` if the asset is not loaded into the cache.
  """
  @spec claim(
          service :: atom,
          hash :: Scenic.Cache.Base.hash(),
          scope :: :global | nil | GenServer.server()
        ) :: {:ok, Scenic.Cache.Base.hash()}

  def claim(service, key, scope \\ nil) do
    case :ets.member(service, key) do
      true ->
        GenServer.call(service, {:claim, normalize_scope(scope), key})

      false ->
        {:error, :not_found}
    end
  end

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

  # returns `:ok`
  @spec release(
          service :: atom,
          hash :: Scenic.Cache.Base.hash(),
          opts :: list
        ) :: :ok
  def release(service, hash, opts \\ []) do
    case :ets.member(service, hash) do
      true ->
        scope = normalize_scope(opts[:scope])
        msg = {:release, scope, hash}

        case opts[:delay] do
          nil ->
            Process.send_after(service, msg, @default_release_delay)

          0 ->
            Process.send(service, msg, [])

          delay when is_integer(delay) and delay >= 0 ->
            Process.send_after(service, msg, delay)
        end

        :ok

      false ->
        {:error, :not_found}
    end
  end

  # --------------------------------------------------------
  @doc """
  Get the current status of an asset in the cache.

  This is used to test if the current process has claimed a scope on an asset.

  Pass in the service, hash, and a scope.

  Returns one of:
  ```elixir
  {:ok, hash}           # it is claimed by the given scope
  {:ok, :global}        # it is NOT claimed by the given scope, but is :global
  {:error, :not_found}  # it is not in the cache at all
  ```
  """
  @spec status(
          service :: atom,
          hash :: Scenic.Cache.Base.hash(),
          scope :: :global | nil | GenServer.server()
        ) :: :ok
  def status(service, hash, scope \\ nil) do
    case :ets.member(service, hash) do
      true ->
        GenServer.call(service, {:status, normalize_scope(scope), hash})

      false ->
        {:error, :not_found}
    end
  end

  # --------------------------------------------------------
  @doc """
  Returns a list of asset keys claimed by the given scope.

  Pass in the service and a scope.

  Returns a list of claimed keys.
  """
  @spec keys(
          service :: atom,
          scope :: :global | nil | GenServer.server()
        ) :: list
  def keys(service, scope \\ nil) do
    GenServer.call(service, {:keys, normalize_scope(scope)})
  end

  @doc """
  Tests if a key is claimed by *any* scope.

  Pass in the service and a hash.

  Returns `true` or `false`.
  """
  @spec member?(
          service :: atom,
          hash :: Scenic.Cache.Base.hash()
        ) :: true | false
  def member?(service, key) do
    :ets.member(service, key)
  end

  @doc """
  Tests if a key is claimed by the scope.

  Pass in the service, hash, and scope.

  Returns `true` or `false`.
  """
  @spec claimed?(
          service :: atom,
          hash :: Scenic.Cache.Base.hash(),
          scope :: :global | nil | GenServer.server()
        ) :: true | false
  def claimed?(service, key, scope \\ nil) do
    case :ets.member(service, key) do
      true ->
        GenServer.call(service, {:claimed?, normalize_scope(scope), key})

      false ->
        {:error, :not_found}
    end
  end

  # ----------------------------------------------
  @doc """
  Subscribe the calling process to cache messages.

  Parameters
  * `sub_type` - Pass in the type of messages you want to unsubscribe from.
    * `:put` - sent when assets are put into the cache
    * `:delete` - sent when assets are fully unloaded from the cache
    * `:claim` - sent when a scope is claimed
    * `:release` - sent when a scope is released
    * `:all` - all of the above message types
  * `hash` - The hash key of the asset you want to listen to messages about. Pass
    in :all for messages about all keys
  """
  @spec subscribe(
          service :: atom,
          hash :: hash() | :all,
          sub_type :: sub_types()
        ) :: :ok

  def subscribe(service, hash, sub_type \\ :all)

  # explicit calls to enforce incoming types
  def subscribe(service, hash, :all), do: do_subscribe(service, hash, :all)
  def subscribe(service, hash, :put), do: do_subscribe(service, hash, :put)
  def subscribe(service, hash, :delete), do: do_subscribe(service, hash, :delete)

  def subscribe(service, hash, :cache_put), do: deprecated_sub(service, hash, :cache_put, :put)

  def subscribe(service, hash, :cache_delete),
    do: deprecated_sub(service, hash, :cache_delete, :delete)

  defp do_subscribe(service, key, type) do
    GenServer.cast(service, {:subscribe, type, key, self()})
  end

  defp deprecated_sub(service, hash, old, new) do
    IO.ANSI.yellow() <>
      """
      Cache subscription type #{inspect(old)} is deprecated
      Please use #{inspect(new)} instead
      """ <>
      IO.ANSI.default_color()

    do_subscribe(service, hash, new)
  end

  # ----------------------------------------------
  @doc """
  Unsubscribe the calling process from cache messages.

  Parameters
  * `sub_type` - Pass in the type of messages you want to unsubscribe from.
    * `:put` - sent when assets are put into the cache
    * `:delete` - sent when assets are fully unloaded from the cache
    * `:claim` - sent when a scope is claimed
    * `:release` - sent when a scope is released
    * `:all` - all of the above message types
  * `hash` - The hash key of the asset you want to listen to messages about. Pass
    in :all for messages about all keys

  """
  @spec unsubscribe(
          service :: atom,
          hash :: hash() | :all,
          sub_type :: sub_types()
        ) :: :ok

  def unsubscribe(service, sub_type, hash \\ :all)

  # explicit calls to enforce incoming types
  def unsubscribe(service, hash, :all), do: do_unsubscribe(service, hash, :all)
  def unsubscribe(service, hash, :put), do: do_unsubscribe(service, hash, :put)
  def unsubscribe(service, hash, :delete), do: do_unsubscribe(service, hash, :delete)

  def unsubscribe(service, hash, :cache_put),
    do: deprecated_unsub(service, hash, :cache_put, :put)

  def unsubscribe(service, hash, :cache_delete),
    do: deprecated_unsub(service, hash, :cache_delete, :delete)

  defp do_unsubscribe(service, key, type) do
    GenServer.cast(service, {:unsubscribe, type, key, self()})
  end

  defp deprecated_unsub(service, hash, old, new) do
    IO.ANSI.yellow() <>
      """
      Cache subscription type #{inspect(old)} is deprecated
      Please use #{inspect(new)} instead
      """ <>
      IO.ANSI.default_color()

    do_unsubscribe(service, hash, new)
  end

  # ============================================================================

  # --------------------------------------------------------
  @doc false
  def start_link(module, friendly_name) do
    GenServer.start_link(__MODULE__, {module, friendly_name}, name: module)
  end

  # --------------------------------------------------------
  @doc false
  def init({module, friendly_name}) do
    state = %{
      table: :ets.new(module, [:set, :protected, :named_table]),
      module: module,
      name: friendly_name,
      scopes: %{},
      claims: %{},
      subs: %{}
    }

    {:ok, state}
  end

  # --------------------------------------------------------
  @doc false
  def handle_info({:DOWN, _, :process, scope_pid, _}, %{scopes: scopes} = state) do
    # a scope process we are monitoring just went down. Clean up after it.
    Map.get(scopes, scope_pid, [])
    |> Enum.each(
      &Process.send_after(
        self(),
        {:release, scope_pid, &1},
        @default_release_delay
      )
    )

    {:noreply, state}
  end

  # --------------------------------------------------------
  def handle_info({:release, scope, key}, state) do
    {:noreply, internal_release(scope, key, state)}
  end

  # ============================================================================
  @doc false

  # --------------------------------------------------------
  def handle_call({:put, scope, key, data}, _, %{table: table} = state) do
    unless :ets.member(table, key) do
      # monitor the scope
      monitor_scope(scope)
    end

    # update the item
    :ets.insert(table, {key, data})
    state = internal_claim(scope, key, state)
    dispatch_notification(:put, key, state)

    {:reply, {:ok, key}, state}
  end

  # # --------------------------------------------------------
  def handle_call({:put_new, scope, key, data}, _, %{table: table} = state) do
    # Check if the key already exists. If so, overwrite the data, if not insert it.
    case :ets.member(table, key) do
      true ->
        # already there. only need to claim it
        {:reply, {:ok, key}, internal_claim(scope, key, state)}

      false ->
        :ets.insert(table, {key, data})

        # monitor the scope
        monitor_scope(scope)

        # dispatch a put message
        dispatch_notification(:put, key, state)
        state = internal_claim(scope, key, state)
        {:reply, {:ok, key}, state}
    end
  end

  # --------------------------------------------------------
  def handle_call({:claim, scope, key}, _, state) do
    state = internal_claim(scope, key, state)
    {:reply, :ok, state}
  end

  # --------------------------------------------------------
  def handle_call({:status, scope, key}, _, %{table: table, scopes: scopes} = state) do
    reply =
      case :ets.member(table, key) do
        true -> internal_status(scope, key, scopes)
        false -> {:error, :not_found}
      end

    {:reply, reply, state}
  end

  # --------------------------------------------------------
  def handle_call({:keys, scope}, _, %{scopes: scopes} = state) do
    {:reply, Map.get(scopes, scope, []), state}
  end

  # --------------------------------------------------------
  def handle_call({:claimed?, scope, key}, _, %{scopes: scopes} = state) do
    reply = Map.get(scopes, scope, []) |> Enum.member?(key)
    {:reply, reply, state}
  end

  # --------------------------------------------------------
  if Scenic.mix_env() == :test do
    def handle_call(:reset, _, %{table: table} = state) do
      :ets.delete_all_objects(table)

      state =
        state
        |> Map.put(:scopes, %{})
        |> Map.put(:claims, %{})
        |> Map.put(:subs, %{})

      {:reply, :ok, state}
    end
  end

  # ============================================================================
  @doc false

  # --------------------------------------------------------
  def handle_cast({:subscribe, type, target, pid}, state) do
    {:noreply, internal_subscribe(state, type, target, pid)}
  end

  # --------------------------------------------------------
  def handle_cast({:unsubscribe, type, target, pid}, state) do
    {:noreply, internal_unsubscribe(state, type, target, pid)}
  end

  # ============================================================================
  # private helpers

  # --------------------------------------------------------
  defp normalize_scope(scope)
  defp normalize_scope(nil), do: self()
  defp normalize_scope(:global), do: :global
  defp normalize_scope(name) when is_atom(name), do: Process.whereis(name)
  defp normalize_scope(pid) when is_pid(pid), do: pid

  # --------------------------------------------------------
  defp monitor_scope(:global), do: :ok
  defp monitor_scope(scope_pid), do: Process.monitor(scope_pid)

  # --------------------------------------------------------
  defp internal_claim(scope, key, %{table: table, scopes: scopes, claims: claims} = state) do
    scope_keys = Map.get(scopes, scope, [])
    key_scopes = Map.get(claims, key, [])

    with true <- :ets.member(table, key),
         false <- Enum.member?(key_scopes, scope) do
      scopes = Map.put(scopes, scope, Enum.uniq([key | scope_keys]))
      claims = Map.put(claims, key, Enum.uniq([scope | key_scopes]))
      %{state | scopes: scopes, claims: claims}
    else
      _ -> state
    end
  end

  # --------------------------------------------------------
  defp internal_release(scope, key, %{table: table, scopes: scopes, claims: claims} = state) do
    scope_keys = Map.get(scopes, scope, [])
    key_scopes = Map.get(claims, key, [])

    # first, cleanup the scope tracking
    scopes =
      case Enum.member?(scope_keys, key) do
        false ->
          scopes

        true ->
          case Enum.reject(scope_keys, &Kernel.==(&1, key)) do
            [] -> Map.delete(scopes, scope)
            keys -> Map.put(scopes, scope, keys)
          end
      end

    # second, clean up the claim tracking
    # if claims go to zero, delete the row in the table
    claims =
      case Enum.member?(scope_keys, key) do
        false ->
          claims

        true ->
          case Enum.reject(key_scopes, &Kernel.==(&1, scope)) do
            [] ->
              dispatch_notification(:delete, key, state)
              :ets.delete(table, key)
              Map.delete(claims, key)

            ks ->
              Map.put(claims, key, ks)
          end
      end

    %{state | scopes: scopes, claims: claims}
  end

  # --------------------------------------------------------
  defp internal_status(:global, key, scopes) do
    scopes
    |> Map.get(:global, [])
    |> Enum.member?(key)
    |> case do
      true -> {:ok, :global}
      false -> {:error, :not_claimed}
    end
  end

  defp internal_status(scope, key, scopes) do
    scopes
    |> Map.get(scope, [])
    |> Enum.member?(key)
    |> case do
      true -> {:ok, scope}
      false -> internal_status(:global, key, scopes)
    end
  end

  # ============================================================================
  # subscriptions

  # @deprecated "Use Cache.unsubscribe/1 instead"

  # ----------------------------------------------
  defp internal_subscribe(state, :all, target, pid) do
    state
    |> internal_subscribe(:put, target, pid)
    |> internal_subscribe(:delete, target, pid)
  end

  defp internal_subscribe(%{subs: subs} = state, type, target, pid) do
    targets = Map.get(subs, type, %{})

    subscribers =
      Map.get(targets, target, [])
      |> List.insert_at(0, pid)
      |> Enum.uniq()

    targets = Map.put(targets, target, subscribers)
    subs = Map.put(subs, type, targets)
    %{state | subs: subs}
  end

  # ----------------------------------------------
  defp internal_unsubscribe(state, :all, target, pid) do
    state
    |> internal_unsubscribe(:put, target, pid)
    |> internal_unsubscribe(:delete, target, pid)
  end

  defp internal_unsubscribe(%{subs: subs} = state, type, target, pid) do
    targets = Map.get(subs, type, %{})

    subscribers =
      Map.get(targets, target, [])
      |> Enum.reject(&Kernel.==(&1, pid))

    targets =
      case subscribers do
        [] -> Map.delete(targets, target)
        s -> Map.put(targets, target, s)
      end

    subs = Map.put(subs, type, targets)
    %{state | subs: subs}
  end

  # ----------------------------------------------
  defp dispatch_notification(type, target, %{subs: subs, module: module}) do
    type_map = Map.get(subs, type, %{})

    subs =
      [Map.get(type_map, target, []) | Map.get(type_map, :all, [])]
      |> List.flatten()
      |> Enum.uniq()

    for pid <- subs do
      try do
        GenServer.cast(pid, {module, type, target})
      catch
        kind, reason ->
          formatted = Exception.format(kind, reason, __STACKTRACE__)
          IO.puts("dispatch_notification/3 failed with #{formatted}")
      end
    end

    :ok
  end
end
