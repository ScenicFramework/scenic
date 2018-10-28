# Getting Started

This guide will walk you through installing the new project generator, then
building your first Scenic application.

## Install `scenic.new`

The Scenic Archive is the home of the `scenic.new` mix task, which lays out a
starter application for you. This is the easiest way to set up a new Scenic
project.

Install the Scenic Archive like this

```bash
mix archive.install hex scenic_new
```

## Build the Basic App

First, navigate the command-line to the directory where you want to create your
new Scenic app. Then run the following commands:  (change `my_app` to the name
of your app...)

```bash
mix scenic.new my_app
cd my_app
mix do deps.get, scenic.run
```

If you want to explore the more full-on example, then follow the instructions below.

## Build the Example App

First, navigate the command-line to the directory where you want to create your
new Scenic app. Then run the following commands:  (change `my_app` to the name
of your app...)

```bash
mix scenic.new.example my_app
cd my_app
mix do deps.get, scenic.run
```

## Configure Scenic

In order to start Scenic, you should first build a configuration for one or more
ViewPorts.

These configuration maps will be passed in to the main Scenic supervisor. These
configurations should live in your app's config.exs file.

    use Mix.Config

    # Configure the main viewport for the Scenic application
    config :my_app, :viewport, %{
      name: :main_viewport,
      size: {700, 600},
      default_scene: {MyApp.Scene.Example, nil},
      drivers: [
        %{
          module: Scenic.Driver.Glfw,
          name: :glfw,
          opts: [resizeable: false, title: "Example Application"],
        }
      ]
    }

Then use that config to start your supervisor with the `Scenic` supervisor.

```elixir
defmodule MyApp do
  # ...

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # 1. Load the viewport configuration from config
    main_viewport_config = Application.get_env(:my_app, :viewport)

    # 2. Start the application with the viewport
    children = [
      # ...
      supervisor(Scenic, [viewports: [main_viewport_config]]),
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

end
```

In the ViewPort configuration you can do things like set a name for the ViewPort
process, its size, the default scene and start one or more drivers.

See the documentation for [ViewPort Configuration](Scenic.ViewPort.Config.html)
to learn more about how to set the options on a viewport.

Note that all the drivers are in separate Hex packages as you should choose the
correct one for your application. For example, the `Scenic.Driver.Glfw` driver
draws your scenes into a window under MacOS and Ubuntu. It should work on other
OS's as well, such as other flavors of Unix or Windows, but I haven't worked on
or tested those yet.

## Running and Debugging

Once the app and its dependencies are set up, there are two main ways to run it.

If you want to run your app under IEx so that you can debug it, simply run

```bash
iex -S mix
```

This works just like any other Elixir application.

If you want to run your app outside of iex, you should start it like this:

```bash
mix scenic.run
```

## The Starter App

The starter app created by the generator above shows the basics of building a
Scenic application. It has four scenes, two components, and a simulated sensor.

- **Splash:** The Splash scene is configured to run when the app is started in
  the `config/config.exs` file. It runs a simple animation, then transitions to
  the Sensor scene. It also shows how to intercept basic user input to exit the
  scene early.

- **Sensor:** The Sensor scene depicts a simulated temperature sensor. The
  sensor is always running and updates its data through the
  `Scenic.SensorPubSub` server.

- **Primitives:** The Primitives scenes displays an overview of the basic
  primitive types and some of the styles that can be applied to them.

- **Components:** The Components scene shows the basic components that come with
  Scenic. The crash button will cause a match error that will crash the scene,
  showing how the supervision tree restarts the scene. It also shows how to
  receive events from components.

### Components

- **Nav:** The nav bar at the top of the main scenes shows how to navigate
  between scenes and how to construct a simple component and pass a parameter to
  it. Note that it references a clock, creating a nested component. The clock is
  positioned by dynamically querying the width of the ViewPort

- **Notes:** The notes section at the bottom of each scene is very simple and
  also shows passing in custom data from the parent.

The simulated temperature sensor doesn't collect any actual data, but does show
how you would set up a real sensor and publish data from it into the
Scenic.SensorPubSub service.

## What to read next?

Next, you should read about the [structure of a scene](overview_scene.html).
This will explain the parts of a scene, how to send and receive messages and how
to push the graph to the ViewPort.
