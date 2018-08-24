defmodule Temp.MixProject do
  use Mix.Project

  def project do
    [
      app: :temp,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers,
      make_env: %{"MIX_ENV" => to_string(Mix.env)},
      make_clean: ["clean"],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Temp, []},
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.4"},
      # {:scenic, "~> 0.7.0"},
      # {:scenic_driver_glfw, "~> 0.7.0"},

      # this clock is optional. It is. included as an example of a set
      # of components wrapped up in their own Hex package
      # {:scenic_clock, ">= 0.0.0"},

      # the ssh versions
      { :scenic, git: "git@github.com:boydm/scenic.git" },
      { :scenic_driver_glfw, git: "git@github.com:boydm/scenic_driver_glfw.git"},
      { :scenic_clock, git: "git@github.com:boydm/scenic_clock.git"},


      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
