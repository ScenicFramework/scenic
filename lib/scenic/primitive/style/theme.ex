#
#  Created by Boyd Multerer on 2018-08-18.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Theme do
  @moduledoc """
  The theme style is a way to bundle up default colors that are intended to be used by dynamic components invoked by a scene.

  There is a set of pre-defined themes.
  You can also pass in a map of theme values.

  Unlike other styles, these are a guide to the components.
  Each component gets to pick, choose, or ignore any colors in a given style.

  ## Main Predefined Themes
  * `:dark` - This is the default and most common. Use when the background is dark.
  * `:light` - Use when the background is light colored.

  ## Specialty Themes

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
    focus: :blue
  }

  @theme_dark %{
    text: :white,
    background: :black,
    border: :light_grey,
    active: {40, 40, 40},
    thumb: :cornflower_blue,
    focus: :cornflower_blue
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

  # --------------------------------------------------------
  @doc false
  def info(data),
    do: """
      #{IO.ANSI.red()}#{__MODULE__} data must either a preset theme or a map of named colors
      #{IO.ANSI.yellow()}Received: #{inspect(data)}

      The predefined themes are:
      :dark, :light, :primary, :secondary, :success, :danger, :warning, :info, :text

      If you pass in a map of colors, the common ones used in the controls are:
      :text, :background, :border, :active, :thumb, :focus

      #{IO.ANSI.default_color()}
    """

  # --------------------------------------------------------
  @doc false
  def verify(name) when is_atom(name), do: Map.has_key?(@themes, name)

  def verify(custom) when is_map(custom) do
    Enum.all?(custom, fn {_, color} -> Color.verify(color) end)
  end

  def verify(_), do: false

  # --------------------------------------------------------
  @doc false
  def normalize(theme) when is_atom(theme), do: Map.get(@themes, theme)
  def normalize(theme) when is_map(theme), do: theme

  # --------------------------------------------------------
  @doc false
  def preset(theme), do: Map.get(@themes, theme)
end
