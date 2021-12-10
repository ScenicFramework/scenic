defmodule Scenic.Themes do
  alias Scenic.Palette
  alias Scenic.Primitive.Style.Paint.Color
  @moduledoc """
  Manages theme libraries by registering your map of themes to a library key.
  By registering themes in this way you can safely pull in themes from external libraries,
  without theme names colliding, as well as get all the validation.

  You can add additional keys to be validated on your custom themes by returning a tuple with your map of themes and a list of keys to be validated
  from your load function.

  All themes will validate against the default schema. If you provide additional keys, the list will get merged with the list of default keys.

  ### Required Configuration
  Setting up themes requires some initial setup.

  Example:

   ```elixir
  defmodule MyApplication.Themes do
    @themes %{
      light: @theme_light,
      dark: @theme_dark,
      primary: @primary,
      secondary: @secondary,
      success: @success,
      danger: @danger,
      warning: @warning,
      info: @info,
      text: @text
    }

    schema [:surface] # add additional required keys to your theme

    use Scenic.Themes,
      [
        {:scenic, Scenic.Themes},
        {:my_app, load()}
      ]

    def load(), do: [name: :my_library, themes: @themes, schema: @schema, palette: @palette]
  end
  ```

  After the Themes modules has been defined you need to configure it in your config file.any()

  ```elixir
  config :scenic, :themes,
    module: MyApplication.Themes
  ```

  Now themes are passed around scenic in the form of `{:library_name, :theme_name}` as opposed to just :theme_name.
  """
  @callback load() :: keyword
  @optional_callbacks load: 0

  defmacro __using__(sources \\ []) do
    quote do
      @behaviour Scenic.Themes
      @opts_schema [
        name: [required: true, type: :atom],
        themes: [required: true, type: :any],
        schema: [required: false, type: :any],
        palette: [required: false, type: :any]
      ]
      @default_schema [:text, :background, :border, :active, :thumb, :focus]
      @_palette %{}

      @library_themes Enum.reduce(unquote(sources), %{}, fn lib_opts, acc ->
        case NimbleOptions.validate(lib_opts, @opts_schema) do
          {:ok, lib_opts} ->
            name = lib_opts[:name]
            themes = lib_opts[:themes]
            schema = lib_opts[:schema] || []
            palette = lib_opts[:palette] || %{}
            @_palette Map.merge(@_palette, palette)
            case themes do
              themes when is_map(themes) ->
                # not a module so we can load in the settings directly
                Map.put_new(acc, name, {themes, List.flatten([@default_schema | schema])})
              themes ->
                # this is a module so we have to load the settings
                lib_opts = themes.load()
                themes = lib_opts[:themes]
                schema = lib_opts[:schema] || []
                palette = lib_opts[:palette] || %{}
                @_palette Map.merge(@_palette, palette)
                Map.put_new(acc, name, {themes, List.flatten([@default_schema | schema])})
            end
          {:error, error} ->
            raise Exception.message(error)
        end
      end)

      # validate the passed options
      def library(), do: @library_themes

      def _get_palette(), do: @_palette
    end
  end

  @doc false
  def module() do
    with {:ok, config} <- Application.fetch_env(:scenic, :themes),
         {:ok, module} <- Keyword.fetch(config, :module) do
      module
    else
      _ ->
        # No module configure return the default
        __MODULE__
    end
  end

  def validate(theme)
  def validate({lib, theme_name} = lib_theme) when is_atom(theme_name) do
    themes = module().library()
    case Map.get(themes, lib) do
      {themes, schema} ->
        # validate against the schema
        case Map.get(themes, theme_name) do
          nil ->
            {
              :error,
              """
              #{IO.ANSI.red()}Invalid theme specification
              Received: #{inspect(theme_name)}
              #{IO.ANSI.yellow()}
              The theme could not be found in library #{inspect(lib)}.
              Ensure you got the name correct.
              #{IO.ANSI.default_color()}
              """
            }
          theme ->
            case validate(theme, schema) do
              {:ok, _} -> {:ok, lib_theme}
              error -> error
            end
        end
      nil ->
        {
          :error,
          """
          #{IO.ANSI.red()}Invalid theme specification
          Received: #{inspect(lib_theme)}
          #{IO.ANSI.yellow()}
          You passed in a tuple representing a library theme, but it could not be found.
          Please ensure you've imported the the library correctly in your Themes module.
          #{IO.ANSI.default_color()}
          """
        }
    end
  end

  def validate(
        %{
          text: _,
          background: _,
          border: _,
          active: _,
          thumb: _,
          focus: _
        } = theme
      ) do
    # we dont have the schema so validate against the default,
    # this is not ideal, but should be fine for now.
    # we know all the required colors are there.
    # now make sure they are all valid colors, including any custom added ones.
    theme
    |> Enum.reduce({:ok, theme}, fn
      _, {:error, msg} ->
        {:error, msg}

      {key, color}, {:ok, _} = acc ->
        case Color.validate(color) do
          {:ok, _} -> acc
          {:error, msg} -> err_color(key, msg)
        end
    end)
  end

  def validate(%{} = map) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid theme specification
      Received: #{inspect(map)}
      #{IO.ANSI.yellow()}
      You passed in a map, but it didn't include all the required color specifications.
      It must contain a valid color for each of the following entries.
        :text, :background, :border, :active, :thumb, :focus
      If you're using a custom theme please check the documentation for that specific theme.
      #{IO.ANSI.default_color()}
      """
    }
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid theme specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      Themes can be a tuple represent a theme for example:
        {:scenic, :light}, {:scenic, :dark}

      Or it may also be a map defining colors for the values of
          :text, :background, :border, :active, :thumb, :focus

      If you pass in a map, you may add your own colors in addition to the required ones.#{IO.ANSI.default_color()}
      """
    }
  end

  def validate(
        theme,
        schema
      ) do
    # we have the schema so we can validate against it.
    schema
    |> Enum.reduce({:ok, theme}, fn
      _, {:error, msg} ->
        {:error, msg}
      key, {:ok, _} = acc ->
        case Map.has_key?(theme, key) do
          true -> acc
          false -> err_key(key, theme)
        end
    end)
  end

  @spec get_schema(atom) :: list
  @doc """
  Retrieve a library's schema
  """
  def get_schema(lib) do
    themes = module().library()
    case Map.get(themes, lib) do
      {_, schema} -> schema
      nil -> nil
    end
  end

  @spec get_palette() :: map
  @doc """
  Retrieve the color palette
  """
  def get_palette() do
    module()._get_palette()
  end

  @spec normalize({atom, atom} | map) :: map | nil
  @doc """
  Converts a theme from it's tuple form to it's map form.
  """
  def normalize({lib, theme_name}) when is_atom(theme_name) do
    themes = module().library()
    case Map.get(themes, lib) do
      {themes, _schema} -> Map.get(themes, theme_name)
      nil -> nil
    end
  end

  def normalize(theme) when is_map(theme), do: theme

  @spec preset({atom, atom} | map) :: map | nil
  @doc """
  Get a theme.
  """
  def preset({lib, theme_name}) do
    themes = module().library()
    case Map.get(themes, lib) do
      {themes, _schema} -> Map.get(themes, theme_name)
      nil -> nil
    end
  end

  def preset(theme) when is_map(theme), do: theme

  @theme_light %{
    text: :black,
    background: :white,
    border: :dark_grey,
    active: {215, 215, 215},
    thumb: :cornflower_blue,
    focus: :blue,
    highlight: :saddle_brown
  }

  @theme_dark %{
    text: :white,
    background: :black,
    border: :light_grey,
    active: {40, 40, 40},
    thumb: :cornflower_blue,
    focus: :cornflower_blue,
    highlight: :sandy_brown
  }

  @primary Map.merge(@theme_dark, %{background: {72, 122, 252}, active: {58, 94, 201}})
  @secondary Map.merge(@theme_dark, %{background: {111, 117, 125}, active: {86, 90, 95}})
  @success Map.merge(@theme_dark, %{background: {99, 163, 74}, active: {74, 123, 56}})
  @danger Map.merge(@theme_dark, %{background: {191, 72, 71}, active: {164, 54, 51}})
  @warning Map.merge(@theme_light, %{background: {239, 196, 42}, active: {197, 160, 31}})
  @info Map.merge(@theme_dark, %{background: {94, 159, 183}, active: {70, 119, 138}})
  @text Map.merge(@theme_dark, %{text: {72, 122, 252}, background: :clear, active: :clear})
  @themes %{
    light: @theme_light,
    dark: @theme_dark,
    primary: @primary,
    secondary: @secondary,
    success: @success,
    danger: @danger,
    warning: @warning,
    info: @info,
    text: @text
  }
  @default_schema [:text, :background, :border, :active, :thumb, :focus]
  @palette Palette.get()

  def _get_palette(), do: @palette

  def library(), do: %{scenic: {@themes, @default_schema}}

  @doc false
  def load(), do: [name: :scenic, themes: @themes, palette: @palette]

  defp err_key(key, map) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid theme specification
      Received: #{inspect(map)}
      #{IO.ANSI.yellow()}
      Map entry: #{inspect(key)}
      #{IO.ANSI.default_color()}
      """
    }
  end

  defp err_color(key, msg) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid color in map
      Map entry: #{inspect(key)}
      #{msg}
      """
    }
  end
end
