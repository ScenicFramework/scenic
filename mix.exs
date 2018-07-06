defmodule Scenic.Mixfile do
  use Mix.Project

  def project do
    [
      app: :scenic,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      elixir: "~> 1.6",

      name: "Scenic",
      source_url: "https://github.com/boydm/scenic",
      homepage_url: "http://kry10.com",

      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      #mod: {Scenic, []},
      applications: [:logger]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:scenic_math, git: "git@github.com:boydm/scenic_math.git"},
      # {:mox, "~> 0.3.2"}

      # Docs dependencies
      {:ex_doc, ">= 0.0.0", only: [:dev, :docs]},
      {:inch_ex, ">= 0.0.0", only: :docs}
    ]
  end
end
