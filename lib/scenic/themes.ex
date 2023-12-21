defmodule Scenic.Themes do
  use GenServer

  alias Scenic.Theme

  @ets_name __MODULE__

  @impl GenServer
  def init(_opts) do
    table_handle =
      :ets.new(@ets_name, [:set, :protected, :named_table, {:read_concurrency, true}])

    {:ok, table_handle}
  end

  @doc """
  Upserts a theme to the theme manager.
  """
  @spec put_theme(Theme.t()) :: :ok
  def put_theme(%Theme{} = theme), do: GenServer.call(__MODULE__, {:put_theme, theme})

  @doc """
  Removes a theme from the theme manager, either by name or by theme.

  N.B.: Succeeds even if theme doesn't exist.
  """
  @spec remove_theme(Theme.t() | :atom) :: :ok
  def remove_theme(%Theme{name: theme_name}), do: remove_theme(theme_name)

  def remove_theme(theme_name) when is_atom(theme_name),
    do: GenServer.call(__MODULE__, {:remove_theme, theme_name})

  @doc """
  Removes all themes from the theme manager.
  """
  @spec clear_themes() :: :ok
  def clear_themes(), do: GenServer.call(__MODULE__, {:clear_themes})

  @doc """
  Looks up a theme by name from the manager
  """
  @spec get_theme(:atom) :: {:ok, Theme.t()} | {:error, :not_found}
  def get_theme(name) do
    case :ets.lookup(@ets_name, name) do
      [theme] -> {:ok, theme}
      [] -> {:error, :not_found}
    end
  end

  @spec get_themes() :: {:ok, [Theme.t()]}
  def get_themes() do
    {:ok, :ets.tab2list(@ets_name)}
  end

  # Mutation callbacks
  @impl GenServer
  def handle_call({:put_theme, theme}, _from, table_handle) do
    :ets.insert(table_handle, {theme.name, theme})
    {:reply, :ok}
  end

  def handle_call({:remove_theme, theme_name}, _from, table_handle) do
    :ets.delete(table_handle, theme_name)
    {:reply, :ok}
  end

  def handle_call({:clear_themes}, _from, table_handle) do
    :ets.delete_all_objects(table_handle)
    {:reply, :ok}
  end
end
