defmodule Mix.Tasks.Scenic.New do
  use Mix.Task

  import Mix.Generator

  import IEx


  @switches [
    app: :string,
    module: :string
  ]

  @scenic_version Mix.Project.config[:version]

  #--------------------------------------------------------
  def run(argv) do
    {opts, argv} = OptionParser.parse!(argv, strict: @switches)

    case argv do
      [] ->
        Mix.raise("Expected app PATH to be given, please use \"mix scenic.new PATH\"")

      [path | _] ->
        app = opts[:app] || Path.basename(Path.expand(path))
        check_application_name!(app, !opts[:app])
        mod = opts[:module] || Macro.camelize(app)
        check_mod_name_validity!(mod)
        check_mod_name_availability!(mod)

        unless path == "." do
          check_directory_existence!(path)
          File.mkdir_p!(path)
        end

        File.cd!(path, fn ->
          generate(app, mod, path, opts)
        end)
    end
  end


  #--------------------------------------------------------
  defp generate(app, mod, path, opts) do
    assigns = [
      app: app,
      mod: mod,
      elixir_version: get_version(System.version()),
      scenic_version: @scenic_version
    ]

    create_file("README.md", readme_template(assigns))
    create_file(".formatter.exs", formatter_template(assigns))
    create_file(".gitignore", gitignore_template(assigns))
    create_file("mix.exs", mix_exs_template(assigns))
    create_file("Makefile", makefile_template(assigns))

    create_directory("static")

    create_directory("config")
    create_file("config/config.exs", config_template(assigns))

    create_directory("lib")
    create_file("lib/#{app}.ex", lib_template(assigns))

    # if opts[:sup] do
    #   create_file("lib/#{app}/application.ex", lib_app_template(assigns))
    # end

    # create_directory("test")
    # create_file("test/test_helper.exs", test_helper_template(assigns))
    # create_file("test/#{app}_test.exs", test_template(assigns))

    # """

    # Your Mix project was created successfully.
    # You can use "mix" to compile it, test it, and more:

    #     #{cd_path(path)}mix test

    # Run "mix help" for more commands.
    # """
    # |> String.trim_trailing()
    # |> Mix.shell().info()
  end

  #--------------------------------------------------------
  defp get_version(version) do
    {:ok, version} = Version.parse(version)

    "#{version.major}.#{version.minor}" <>
      case version.pre do
        [h | _] -> "-#{h}"
        [] -> ""
      end
  end


  #============================================================================
  # template files

  #--------------------------------------------------------
  embed_template(:readme, """
  Readme text goes here
  """)

  #--------------------------------------------------------
  embed_template(:formatter, """
  # Used by "mix format"
  [
    inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
  ]
  """)

  #--------------------------------------------------------
  embed_template(:gitignore, """
  # The directory Mix will write compiled artifacts to.
  /_build/

  # If you run "mix test --cover", coverage assets end up here.
  /cover/

  # The directory Mix downloads your dependencies sources to.
  /deps/

  # Where 3rd-party dependencies like ExDoc output generated docs.
  /doc/

  # Ignore .fetch files in case you like to edit your project deps locally.
  /.fetch

  # If the VM crashes, it generates a dump, let's ignore it too.
  erl_crash.dump

  # Also ignore archive artifacts (built via "mix archive.build").
  *.ez
  <%= if @app do %>
  # Ignore package tarball (built via "mix hex.build").
  <%= @app %>-*.tar
  <% end %>

  # Ignore scripts marked as secret - usually passwords and such in config files
  *.secret.exs
  *.secrets.exs

  """)

  #--------------------------------------------------------
  embed_template(:mix_exs, """
  defmodule <%= @mod %>.MixProject do
    use Mix.Project

    def project do
      [
        app: :<%= @app %>,
        version: "0.1.0",
        elixir: "~> <%= @elixir_version %>",
        start_permanent: Mix.env() == :prod,
        deps: deps()
      ]
    end

    # Run "mix help compile.app" to learn about applications.
    def application do
      []
    end

    # Run "mix help deps" to learn about dependencies.
    defp deps do
      [
        {:elixir_make, "~> 0.4"},
        {:scenic, "~> <%= @scenic_version %>"},
        {:scenic_driver_glfw, "~> <%= @scenic_version %>"},

        # the ssh versions
        # { :scenic, git: "git@github.com:boydm/scenic.git" },
        # { :scenic_driver_glfw, git: "git@github.com:boydm/scenic_driver_glfw.git"},


        # {:dep_from_hexpm, "~> 0.3.0"},
        # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      ]
    end
  end
  """)

  #--------------------------------------------------------
  embed_template(:makefile, """
  # makefile copies files from static into priv during build
  .PHONY: all clean

  all: priv static

  priv:
    mkdir -p priv

  static: priv/
    ln -fs ../static priv/

  clean:
    $(RM) -r priv
  """)

  #--------------------------------------------------------
  embed_template(:config, """
  # This file is responsible for configuring your application
  # and its dependencies with the aid of the Mix.Config module.
  use Mix.Config


  # Configure the main viewport for the Scenic application
  config :<%= @app %>, :viewport, %{
        name: :main_viewport,
        size: {700, 600},
        default_scene: {<%= @mod %>.Scene.Example, nil},
        drivers: [
          %{
            module: Scenic.Driver.Glfw,
            name: :glfw,
            opts: [resizeable: false, title: "<%= @app %>"],
          }
        ]
      }


  # It is also possible to import configuration files, relative to this
  # directory. For example, you can emulate configuration per environment
  # by uncommenting the line below and defining dev.exs, test.exs and such.
  # Configuration from the imported file will override the ones defined
  # here (which is why it is important to import them last).
  #
  #     import_config "#{Mix.env}.exs"
  """)


  #--------------------------------------------------------
  embed_template(:lib, """
  defmodule <%= @mod %> do
    @moduledoc \"""
    Starter application using the Scenic framework.
    \"""

    def start(_type, _args) do
      import Supervisor.Spec, warn: false

      # load the viewport configuration from config
      viewport_config = Application.get_env(:<%= @app %>, :viewport)

      # start the application with the viewport
      opts = [strategy: :one_for_one, name: ScenicExample]
      children = [
        supervisor(Scenic, [viewports: [viewport_config]]),
      ]
      Supervisor.start_link(children, opts)
    end

  end


  """)





















  #============================================================================
  # validity functions taken from Elixir new task

    defp check_application_name!(name, inferred?) do
    unless name =~ Regex.recompile!(~r/^[a-z][a-z0-9_]*$/) do
      Mix.raise(
        "Application name must start with a lowercase ASCII letter, followed by " <>
          "lowercase ASCII letters, numbers, or underscores, got: #{inspect(name)}" <>
          if inferred? do
            ". The application name is inferred from the path, if you'd like to " <>
              "explicitly name the application then use the \"--app APP\" option"
          else
            ""
          end
      )
    end
  end

  defp check_mod_name_validity!(name) do
    unless name =~ Regex.recompile!(~r/^[A-Z]\w*(\.[A-Z]\w*)*$/) do
      Mix.raise(
        "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect(name)}"
      )
    end
  end

  defp check_mod_name_availability!(name) do
    name = Module.concat(Elixir, name)

    if Code.ensure_loaded?(name) do
      Mix.raise("Module name #{inspect(name)} is already taken, please choose another name")
    end
  end

  defp check_directory_existence!(path) do
    msg = "The directory #{inspect(path)} already exists. Are you sure you want to continue?"

    if File.dir?(path) and not Mix.shell().yes?(msg) do
      Mix.raise("Please select another directory for installation")
    end
  end

end