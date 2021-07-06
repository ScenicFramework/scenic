#
#  Created by Boyd Multerer on 2018-08-18.
#  Copyright © 2018 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style.Theme do
  @moduledoc """
  Themes are a way to bundle up a set of colors that are intended to be used
  by components invoked by a scene.

  There are a set of pre-defined themes.
  You can also pass in a map of color values.

  Unlike other styles, The currently set theme is given to child components.
  Each component gets to pick, choose, or ignore any colors in a given style.

  ### Predefined Themes
  * `:dark` - This is the default and most common. Use when the background is dark.
  * `:light` - Use when the background is light colored.

  ### Specialty Themes

  The remaining themes are designed to color the standard components and don't really
  make much sense when applied to the root of a graph. You could, but it would be...
  interesting.

  The most obvious place to use them is with [`Button`](Scenic.Component.Button.html)
  components.

  * `:primary` - Blue background. This is the primary button type indicator.
  * `:secondary` - Grey background. Not primary type indicator.
  * `:success` - Green background.
  * `:danger` - Red background. Use for irreversible or dangerous actions.
  * `:warning` - Orange background.
  * `:info` - Lightish blue background.
  * `:text` - Transparent background.
  """

  use Scenic.Primitive.Style
  alias Scenic.Primitive.Style.Paint.Color

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

  # specialty themes
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


  # ============================================================================
  # data verification and serialization
  @doc false
  def validate(theme)
  def validate(:light), do: {:ok, :light}
  def validate(:dark), do: {:ok, :dark}
  def validate(:primary), do: {:ok, :primary}
  def validate(:secondary), do: {:ok, :secondary}
  def validate(:success), do: {:ok, :success}
  def validate(:danger), do: {:ok, :danger}
  def validate(:warning), do: {:ok, :warning}
  def validate(:info), do: {:ok, :info}
  def validate(:text), do: {:ok, :text}

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

  def validate(name) when is_atom(name) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid theme name
      Received: #{inspect(name)}
      #{IO.ANSI.yellow()}
      Named themes must be from the following list:
        :light, :dark, :primary, :secondary, :success, :danger, :warning, :info, :text#{IO.ANSI.default_color()}
      """
    }
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
      Themes can be a name from this list:
        :light, :dark, :primary, :secondary, :success, :danger, :warning, :info, :text

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

  # --------------------------------------------------------
  @doc false
  def normalize(theme) when is_atom(theme), do: Map.get(@themes, theme)
  def normalize(theme) when is_map(theme), do: theme

  # --------------------------------------------------------
  @doc false
  def preset(theme), do: Map.get(@themes, theme)
end
