defmodule Scenic.Mixfile do
  use Mix.Project

  @app_name :scenic
  @version "0.7.0"
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
      dialyzer: [plt_add_deps: :transitive, plt_add_apps: [:mix, :iex, :scenic_math]],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],

      name: "Scenic",
      description: description(),
      docs: [
        extras: doc_guides(),
        main: "welcome",
        groups_for_modules: groups_for_modules()
        # source_ref: "v#{@version}",
        # source_url: "https://github.com/boydm/scenic",
        # homepage_url: "http://kry10.com",
      ],
      package: [
        name: @app_name,
        contributors: ["Boyd Multerer"],
        maintainers: ["Boyd Multerer"],
        licenses: ["Apache 2"],
        links: %{github: @github}
      ]
    ]
  end

  defp description() do
    """
    Scenic -- The core Scenic library
    """
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      # mod: {Scenic, []},
      applications: [:logger]
    ]
  end

  defp deps do
    [
      {:scenic_math, "~> 0.7"},

      # Tools
      {:ex_doc, ">= 0.0.0", only: [:dev]},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, ">= 0.0.0", only: :test, runtime: false},
      {:inch_ex, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false}
    ]
  end

  defp doc_guides do
    [
      "guides/welcome.md",
      "guides/overview_general.md",
      "guides/getting_started.md",
      "guides/getting_started_nerves.md",
      "guides/scene_structure.md",
      "guides/scene_lifecycle.md",
      "guides/overview_graph.md",
      "guides/overview_viewport.md",
      "guides/overview_driver.md",
      "guides/styles_overview.md",
      "guides/transforms_overview.md",
      "CODE_OF_CONDUCT.md",
      "CONTRIBUTING.md"
    ]
  end

  defp groups_for_modules do
    # Ungrouped Modules
    #
    # Plug
    # Plug.Builder
    # Plug.Conn
    # Plug.Crypto
    # Plug.Debugger
    # Plug.ErrorHandler
    # Plug.Exception
    # Plug.HTML
    # Plug.Router
    # Plug.Test
    # Plug.Upload

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
        Scenic.Component.Input.Carat
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
      Animations: [
        Scenic.Animation,
        Scenic.Animation.Basic.Rotate
      ],
      ViewPort: [
        Scenic.ViewPort.Config,
        # Scenic.ViewPort.Input,
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
        Scenic.Cache.Hash
      ],
      Utilities: [
        Scenic.Utilities.Enum,
        Scenic.Utilities.Map
      ]
    ]
  end
end
