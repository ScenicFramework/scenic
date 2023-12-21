defmodule Scenic.Test.CustomThemes do
  @theme_light %{
    text: :black,
    background: :white,
    surface: :gainsboro,
    border: :dark_grey,
    active: {215, 215, 215},
    thumb: :cornflower_blue,
    focus: :blue,
    highlight: :saddle_brown
  }

  @theme_dark %{
    text: :white,
    background: :black,
    surface: :gainsboro,
    border: :light_grey,
    active: {40, 40, 40},
    thumb: :cornflower_blue,
    focus: :cornflower_blue,
    highlight: :sandy_brown
  }

  @theme_dark_invalid %{
    text: :white,
    background: :black,
    border: :light_grey,
    active: {40, 40, 40},
    thumb: :cornflower_blue,
    focus: :cornflower_blue
  }

  @primary Map.merge(@theme_dark, %{surface: :gainsboro, background: {72, 122, 252}, active: {58, 94, 201}})
  @secondary Map.merge(@theme_dark, %{surface: :gainsboro, background: {111, 117, 125}, active: {86, 90, 95}})
  @success Map.merge(@theme_dark, %{surface: :gainsboro, background: {99, 163, 74}, active: {74, 123, 56}})
  @danger Map.merge(@theme_dark, %{surface: :gainsboro, background: {191, 72, 71}, active: {164, 54, 51}})
  @warning Map.merge(@theme_light, %{surface: :gainsboro, background: {239, 196, 42}, active: {197, 160, 31}})
  @info Map.merge(@theme_dark, %{surface: :gainsboro, background: {94, 159, 183}, active: {70, 119, 138}})
  @text Map.merge(@theme_dark, %{text: {72, 122, 252}, surface: :gainsboro, background: :clear, active: :clear})

  @themes %{
    custom_light: @theme_light,
    custom_dark: @theme_dark,
    custom_primary: @primary,
    custom_secondary: @secondary,
    custom_success: @success,
    custom_danger: @danger,
    custom_warning: @warning,
    custom_info: @info,
    custom_text: @text,
    custom_invalid: @theme_dark_invalid
  }

  @schema [:surface]

  @colors %{
    yellow_1: {0xFF, 0xF6, 0x00}
  }

  use Scenic.Themes, []

  def load(), do: [themes: @themes, schema: @schema, palette: @colors]
end
