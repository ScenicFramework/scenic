defmodule Scenic.Mixfile do
  use Mix.Project

  @app_name :scenic

  @version "0.9.0"

  @elixir_version "~> 1.6"
  @github "https://github.com/boydm/scenic"

  def project do
    [
      app: @app_name,
      version: @version,
      elixir: @elixir_version,
      deps: deps(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      make_env: make_env(),
      name: "Scenic",
      description: description(),
      docs: docs(),
      package: package(),
      dialyzer: [plt_add_deps: :transitive, plt_add_apps: [:mix, :iex]],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env()
    ]
  end

  defp description do
    """
    Scenic -- a client application library written directly on the Elixir/Erlang/OTP stack
    """
  end

  defp make_env do
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

  def application do
    [
      # mod: {Scenic, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.4"},

      # Tools
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, ">= 0.0.0", only: :test, runtime: false},
      {:inch_ex, github: "rrrene/inch_ex", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end

  defp cli_env do
    [
      coveralls: :test,
      "coveralls.html": :test,
      "coveralls.json": :test
    ]
  end

  defp package do
    [
      name: @app_name,
      contributors: ["Boyd Multerer"],
      maintainers: ["Boyd Multerer"],
      licenses: ["Apache 2"],
      links: %{Github: @github},
      files: [
        "Makefile",
        "Makefile.win",
        # only include *.c and *.h files
        "c_src/*.[ch]",
        # only include *.ex files
        "lib/**/*.ex",
        "mix.exs",
        "guides/**/*.md",
        # don't include the bird for now
        # "guides/**/*.png",
        "README.md",
        "LICENSE",
        "CHANGELOG.md"
      ]
    ]
  end

  defp docs do
    [
      extras: doc_guides(),
      main: "welcome",
      groups_for_modules: groups_for_modules(),
      source_ref: "v#{@version}",
      source_url: "https://github.com/boydm/scenic"
      # homepage_url: "http://kry10.com",
    ]
  end

  defp doc_guides do
    [
      "guides/welcome.md",
      "guides/install_dependencies.md",
      "guides/overview_general.md",
      "guides/getting_started.md",
      "guides/getting_started_nerves.md",
      "guides/overview_scene.md",
      "guides/scene_lifecycle.md",
      "guides/overview_graph.md",
      "guides/overview_viewport.md",
      "guides/overview_driver.md",
      "guides/overview_styles.md",
      "guides/overview_transforms.md",
      "guides/overview_primitives.md",
      ".github/CODE_OF_CONDUCT.md",
      ".github/CONTRIBUTING.md"
    ]
  end

  defp groups_for_modules do
    [
      Components: [
        Scenic.Component,
        Scenic.Component.Button,
        Scenic.Component.Input.Checkbox,
        Scenic.Component.Input.Dropdown,
        Scenic.Component.Input.RadioButton,
        Scenic.Component.Input.RadioGroup,
        Scenic.Component.Input.Slider,
        Scenic.Component.Input.TextField,
        Scenic.Component.Input.Caret,
        Scenic.Component.Input.Toggle
      ],
      Primitives: [
        Scenic.Primitive,
        Scenic.Primitive.Arc,
        Scenic.Primitive.Circle,
        Scenic.Primitive.Ellipse,
        Scenic.Primitive.Group,
        Scenic.Primitive.Line,
        Scenic.Primitive.Path,
        Scenic.Primitive.Quad,
        Scenic.Primitive.Rectangle,
        Scenic.Primitive.RoundedRectangle,
        Scenic.Primitive.SceneRef,
        Scenic.Primitive.Sector,
        Scenic.Primitive.Text,
        Scenic.Primitive.Triangle
      ],
      Styles: [
        Scenic.Primitive.Style,
        Scenic.Primitive.Style.Cap,
        Scenic.Primitive.Style.ClearColor,
        Scenic.Primitive.Style.Fill,
        Scenic.Primitive.Style.Font,
        Scenic.Primitive.Style.FontBlur,
        Scenic.Primitive.Style.FontSize,
        Scenic.Primitive.Style.Hidden,
        Scenic.Primitive.Style.Join,
        Scenic.Primitive.Style.MiterLimit,
        Scenic.Primitive.Style.Scissor,
        Scenic.Primitive.Style.Stroke,
        Scenic.Primitive.Style.TextAlign,
        Scenic.Primitive.Style.TextHeight,
        Scenic.Primitive.Style.Theme
      ],
      "Style.Paint": [
        Scenic.Primitive.Style.Paint,
        Scenic.Primitive.Style.Paint.Color,
        Scenic.Primitive.Style.Paint.Image,
        Scenic.Primitive.Style.Paint.BoxGradient,
        Scenic.Primitive.Style.Paint.LinearGradient,
        Scenic.Primitive.Style.Paint.RadialGradient
      ],
      Transforms: [
        Scenic.Primitive.Transform,
        Scenic.Primitive.Transform.Matrix,
        Scenic.Primitive.Transform.Pin,
        Scenic.Primitive.Transform.Rotate,
        Scenic.Primitive.Transform.Scale,
        Scenic.Primitive.Transform.Translate
      ],
      Math: [
        Scenic.Math,
        Scenic.Math.Line,
        Scenic.Math.Matrix,
        Scenic.Math.Matrix.Utils,
        Scenic.Math.Quad,
        Scenic.Math.Vector2
      ],
      Animations: [
        Scenic.Animation,
        Scenic.Animation.Basic.Rotate
      ],
      ViewPort: [
        Scenic.ViewPort.Config,
        Scenic.ViewPort.Input,
        Scenic.ViewPort.Context,
        Scenic.ViewPort.Tables
      ],
      Drivers: [
        Scenic.ViewPort.Driver,
        Scenic.ViewPort.Driver.Config,
        Scenic.ViewPort.Driver.Info
      ],
      Cache: [
        Scenic.Cache,
        Scenic.Cache.File,
        Scenic.Cache.Term,
        Scenic.Cache.Hash,
        Scenic.Cache.Supervisor
      ],
      Utilities: [
        Scenic.Utilities.Enum,
        Scenic.Utilities.Map
      ]
    ]
  end
end
