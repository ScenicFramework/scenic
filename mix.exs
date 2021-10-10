defmodule Scenic.Mixfile do
  use Mix.Project

  @app_name :scenic

  @version "0.11.0"

  @elixir_version "~> 1.11"
  @github "https://github.com/boydm/scenic"

  def project do
    [
      app: @app_name,
      version: @version,
      elixir: @elixir_version,
      deps: deps(),
      build_embedded: true,
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      name: "Scenic",
      description: description(),
      docs: docs(),
      package: package(),
      dialyzer: [plt_add_deps: :transitive, plt_add_apps: [:mix, :iex]],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    """
    Scenic -- a client application library written directly on the Elixir/Erlang/OTP stack
    """
  end

  def application do
    [extra_applications: [:logger, :crypto, :iex]]
  end

  defp deps do
    [
      {:font_metrics, "~> 0.5.0"},
      {:nimble_options, "~> 0.3.4"},
      {:ex_image_info, "~> 0.2.4"},

      # Tools
      {:elixir_make, "~> 0.6.2", runtime: false},
      {:truetype_metrics, "~> 0.5", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:excoveralls, ">= 0.0.0", only: :test, runtime: false},
      {:inch_ex, "~> 2.0", only: [:dev, :docs], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false}
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
        "CHANGELOG.md",
        "static/**/*.metrics"
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
      "guides/upgrading_to_v0.11.md",
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
      # "guides/overview_cache.md",
      # "guides/custom_fonts.md",
      ".github/CODE_OF_CONDUCT.md",
      ".github/CONTRIBUTING.md"
    ]
  end

  defp groups_for_modules do
    [
      Assets: [
        Scenic.Assets,
        Scenic.Assets.Static,
        Scenic.Assets.Stream,
        Scenic.Assets.Stream.Bitmap,
        Scenic.Assets.Stream.Image
      ],
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
        Scenic.Primitive.Component,
        Scenic.Primitive.Ellipse,
        Scenic.Primitive.Group,
        Scenic.Primitive.Line,
        Scenic.Primitive.Path,
        Scenic.Primitive.Quad,
        Scenic.Primitive.Rectangle,
        Scenic.Primitive.RoundedRectangle,
        Scenic.Primitive.Sector,
        Scenic.Primitive.Script,
        Scenic.Primitive.Sprites,
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
        Scenic.Primitive.Style.Input,
        Scenic.Primitive.Style.Join,
        Scenic.Primitive.Style.LineHeight,
        Scenic.Primitive.Style.MiterLimit,
        Scenic.Primitive.Style.Scissor,
        Scenic.Primitive.Style.Stroke,
        Scenic.Primitive.Style.TextAlign,
        Scenic.Primitive.Style.TextBase,
        Scenic.Primitive.Style.Theme
      ],
      "Style.Paint": [
        Scenic.Primitive.Style.Paint,
        Scenic.Primitive.Style.Paint.Color,
        Scenic.Primitive.Style.Paint.Image,
        Scenic.Primitive.Style.Paint.Dynamic,
        Scenic.Primitive.Style.Paint.LinearGradient,
        Scenic.Primitive.Style.Paint.RadialGradient,
        Scenic.Primitive.Style.Paint.Stream
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
      Drivers: [
        Scenic.ViewPort.Driver,
        Scenic.ViewPort.Driver.Config,
        Scenic.ViewPort.Driver.Info
      ],
      Cache: [
        Scenic.Cache.Static.Texture,
        Scenic.Cache.Dynamic.Texture,
        Scenic.Cache.Static.Font,
        Scenic.Cache.Static.FontMetrics,
        Scenic.Cache.Base,
        Scenic.Cache.Support.File,
        Scenic.Cache.Support.Hash,
        Scenic.Cache.Support.Supervisor,
        Scenic.Cache.Hash
      ],
      Utilities: [
        Scenic.Utilities.Texture,
        Scenic.Utilities.Enum,
        Scenic.Utilities.Map
      ]
    ]
  end
end
