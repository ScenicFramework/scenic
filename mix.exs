defmodule ScenicMath.Mixfile do
  use Mix.Project

  @github "https://github.com/boydm/scenic_math"

  @version "0.7.1"

  def project do
    [
      app: :scenic_math,
      version: @version,
      # build_path: "_build",
      # deps_path: "deps",
      elixir: "~> 1.6",
      description: description(),
      # build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      make_env: make_env(),
      deps: deps(),
      package: [
        name: :scenic_math,
        contributors: ["Boyd Multerer"],
        maintainers: ["Boyd Multerer"],
        licenses: ["Apache 2"],
        links: %{github: @github},
        files: ["Makefile", "c_src/*.[ch]", "lib", "mix.exs", "README.md"]
      ]
    ]
  end

  defp make_env() do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib"
        }

      _ ->
        %{}
    end
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp description() do
    """
    Scenic.Math - a NIF math support library for Scenic.
    """
  end

  # Dependencies can be Hex packages:
  defp deps do
    [
      {:elixir_make, "~> 0.4"},
      # { :benchwarmer, "~> 0.0.2", only: :dev }

      # Docs dependencies
      {:ex_doc, ">= 0.0.0", only: [:dev, :docs]},
      {:inch_ex, ">= 0.0.0", only: :docs},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end
end
