defmodule Scenic.Themes do
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

  @callback load() :: list

  defmacro __using__(using_opts \\ []) do
    quote do
      alias Scenic.Primitive.Style.Paint.Color
      @behaviour Scenic.Themes
      @sources Keyword.get(unquote(using_opts), :sources, [])
      @library_themes Enum.reduce(@sources, %{}, fn
        {lib, module}, acc when is_atom(module) ->
          themes = module.load()
          Map.put_new(acc, lib, themes)
        {lib, themes}, acc ->
          Map.put_new(acc, lib, themes)
        _, acc -> acc
      end)

      def validate(theme)
      def validate({lib, theme} = lib_theme) when is_atom(theme) do
        case normalize(lib_theme) do
          map when is_map(map) ->
            {:ok, lib_theme}
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

      @doc false
      def normalize({lib, theme}) when is_atom(theme), do: Map.get(Map.get(@library_themes, lib), theme)
      def normalize(theme) when is_map(theme), do: theme

      @doc false
      def preset({lib, theme}), do: Map.get(Map.get(@library_themes, lib), theme)
    end
  end

  @moduledoc false
  def module() do
    with {:ok, config} <- Application.fetch_env(:scenic, :themes),
         {:ok, module} <- Keyword.fetch(config, :module) do
      module
    else
      _ ->
        raise """
        No Themes module is configured.
        You need to create themes module in your application.
        Then connect it to Scenic with some config.

        Example Themes module that includes an optional alias:

          defmodule MyApplication.Themes do
            use Scenic.Assets.Static,
              otp_app: :my_application,
              alias: [
                scenic: Scenic.Themes,
              ]
          end

        Example configuration script (this goes in your config.exs file):

          config :scenic, :themes,
            module: MyApplication.Themes
        """
    end
  end

  def validate(theme), do: module().validate(theme)

  def normalize(theme), do: module().normalize(theme)

  def preset(theme), do: module().preset(theme)

  @doc false
  def load(), do: @themes
end
