defmodule Scenic.Test.Themes do
  # @theme_light %{
  #   text: :black,
  #   background: :white,
  #   border: :dark_grey,
  #   active: {215, 215, 215},
  #   thumb: :cornflower_blue,
  #   focus: :blue,
  #   highlight: :saddle_brown
  # }

  # @theme_dark %{
  #   text: :white,
  #   background: :black,
  #   border: :light_grey,
  #   active: {40, 40, 40},
  #   thumb: :cornflower_blue,
  #   focus: :cornflower_blue,
  #   highlight: :sandy_brown
  # }

  # @primary Map.merge(@theme_dark, %{background: {72, 122, 252}, active: {58, 94, 201}})
  # @secondary Map.merge(@theme_dark, %{background: {111, 117, 125}, active: {86, 90, 95}})
  # @success Map.merge(@theme_dark, %{background: {99, 163, 74}, active: {74, 123, 56}})
  # @danger Map.merge(@theme_dark, %{background: {191, 72, 71}, active: {164, 54, 51}})
  # @warning Map.merge(@theme_light, %{background: {239, 196, 42}, active: {197, 160, 31}})
  # @info Map.merge(@theme_dark, %{background: {94, 159, 183}, active: {70, 119, 138}})
  # @text Map.merge(@theme_dark, %{text: {72, 122, 252}, background: :clear, active: :clear})
  # @themes %{
  #   light: @theme_light,
  #   dark: @theme_dark,
  #   primary: @primary,
  #   secondary: @secondary,
  #   success: @success,
  #   danger: @danger,
  #   warning: @warning,
  #   info: @info,
  #   text: @text
  # }

  use Scenic.Themes,
    sources: [
      {:scenic, Scenic.Themes},
      {:custom_scenic, Scenic.Test.CustomThemes}
    ]
end
