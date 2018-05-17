defmodule ScenicMath.Mixfile do
  use Mix.Project

  def project do
    [app: :scenic_math,
     version: "0.1.0",
     build_path: "_build",
     config_path: "config/config.exs",
     deps_path: "deps",
     elixir: "~> 1.6",
     description: description(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     compilers: [:elixir_make] ++ Mix.compilers,
     make_env: make_env(),
     make_clean: ["clean"],
     deps: deps()]
  end

  defp make_env() do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib",
          "MIX_ENV" => to_string(Mix.env)
        }

      _ ->
        %{"MIX_ENV" => to_string(Mix.env)}
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
    ScenicMath - a NIF math support library for Scenic.
    """
  end

  # Dependencies can be Hex packages:
  defp deps do
    [
      { :elixir_make, "~> 0.4" },
      { :benchwarmer, "~> 0.0.2", only: :dev }
    ]
  end
end
