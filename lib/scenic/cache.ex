#
#  Created by Boyd Multerer on 2017-11-12.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#
defmodule Scenic.Cache do
  @moduledoc """
  The Cache module serves several purposes at the same time.

  First, static assets such as fonts, images and more tend to be relatively large compared to other data in the system.
  It is good to have one place to load and access them for use by multiple scenes and drivers.

  Second, the scenes are in control on when things are loaded. However, multiple scenes (across multiple viewports) may
  try to load the same assets at the same time. The Cache does it’s best to manage the lifetime of these assets to
  minimize memory used and work done to load and unload them.

  Finally, the drivers react to the cache as assets are loaded and unloaded. They use a pub/sub interface to get changes
  to items in the cache as they come and go.

  In addition to the core cache/pub-sub features, the helper modules such as Cache.File, Cache.Hash and Cache.Term
  enforce that the files being loaded are the ones the developer intended at build time. This helps reduce an attack
  vector on devices and should be used consistently.
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
    defexception message: nil
  end

  # ============================================================================
  # client apis

  # --------------------------------------------------------
  def get(key, default \\ nil)

  def get(key, default) do
    :ets.lookup_element(@cache_table, key, 3)
  rescue
    ArgumentError ->
      default

    other ->
      reraise(other, __STACKTRACE__)
  end

  # --------------------------------------------------------
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
  def put(key, data, scope \\ nil)
  def put(key, data, nil), do: do_put(self(), key, data)
  def put(key, data, :global), do: do_put(:global, key, data)
  def put(key, data, name) when is_atom(name), do: do_put(Process.whereis(name), key, data)
  def put(key, data, pid) when is_pid(pid), do: do_put(pid, key, data)

  # --------------------------------------------------------
  # return true if the ref was successful
  # return false if not - means the key doesn't exist anywhere and needs to be put
  def claim(key, scope \\ nil)
  def claim(key, nil), do: do_claim(self(), key)
  def claim(key, :global), do: do_claim(:global, key)
  def claim(key, name) when is_atom(name), do: do_claim(Process.whereis(name), key)
  def claim(key, pid) when is_pid(pid), do: do_claim(pid, key)

  # --------------------------------------------------------
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
  def status(key, scope \\ nil)
  def status(key, nil), do: do_status(self(), key)
  def status(key, :global), do: do_status(:global, key)
  def status(key, name) when is_atom(name), do: do_status(Process.whereis(name), key)
  def status(key, pid) when is_pid(pid), do: do_status(pid, key)

  # --------------------------------------------------------
  def keys(scope \\ nil)
  def keys(nil), do: do_keys(self())
  def keys(:global), do: do_keys(:global)
  def keys(name) when is_atom(name), do: do_keys(Process.whereis(name))
  def keys(pid) when is_pid(pid), do: do_keys(pid)

  def member?(key, scope \\ nil) do
    case status(key, scope) do
      {:ok, _} -> true
      {:err, :not_claimed} -> true
      {:err, :not_found} -> false
    end
  end

  # ============================================================================

  # --------------------------------------------------------
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  # --------------------------------------------------------
  def init(_) do
    state = %{
      cache_table: :ets.new(@cache_table, [:set, :public, :named_table]),
      scope_table: :ets.new(@scope_table, [:bag, :public, :named_table])
    }

    {:ok, state}
  end

  # --------------------------------------------------------
  def handle_cast({:monitor_scope, :global}, state), do: {:noreply, state}

  def handle_cast({:monitor_scope, pid}, state) when is_pid(pid) do
    Process.monitor(pid)
    {:noreply, state}
  end

  # --------------------------------------------------------
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
  def request_notification(message_type)

  def request_notification(@cache_put),
    do: Registry.register(@cache_registry, @cache_put, @cache_put)

  def request_notification(@cache_delete),
    do: Registry.register(@cache_registry, @cache_delete, @cache_delete)

  def request_notification(@cache_claim),
    do: Registry.register(@cache_registry, @cache_claim, @cache_claim)

  def request_notification(@cache_release),
    do: Registry.register(@cache_registry, @cache_release, @cache_release)

  # ----------------------------------------------
  def stop_notification(message_type \\ :all)

  def stop_notification(:all) do
    stop_notification(@cache_put)
    stop_notification(@cache_delete)
    stop_notification(@cache_claim)
    stop_notification(@cache_release)
  end

  def stop_notification(@cache_put), do: Registry.unregister(@cache_registry, @cache_put)
  def stop_notification(@cache_delete), do: Registry.unregister(@cache_registry, @cache_delete)
  def stop_notification(@cache_claim), do: Registry.unregister(@cache_registry, @cache_claim)
  def stop_notification(@cache_release), do: Registry.unregister(@cache_registry, @cache_release)

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
