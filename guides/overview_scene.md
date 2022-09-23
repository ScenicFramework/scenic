# Structure of a Scene

A `Scenic.Scene` is a `GenServer` process which creates and manages a [Graph](overview_graph.html) that gets drawn to the screen. Scenes also respond to user input and other events.

Scenes can reference each other, creating a logical hierarchy that lives above
the Graphs themselves. This allows scenes to be reusable, small, and simple. A
properly designed scene should do one job, and do it well. Then it can be reused
along with other simple scenes to create a complex screen of UI.

Scenes that are specifically meant to be reused are called components.
Components have sugar apis that make them very easy to use inside of a parent
scene.

For example, if you create a dashboard, it may have buttons, text input,
sliders, or other input controls in it. Each of those controls is a component
scene that is dynamically created when the dashboard scene is started. This
collection of scenes forms a graph, which can be quite deep (scenes using scenes
using scenes).

All these scenes communicate with each other by generating events and passing
them as messages. This is [explained more below](#events).

The life-cycle of scenes (when they start, stop, etc.) is explained in the
[life-cycle of a scene](scene_lifecycle.html) guide.

## The Graph

The most important state a Scene is responsible for is its Graph. The Graph
defines what is to be drawn to the screen, any referenced components, and the
overall draw order. When the Scene decides the graph is ready to be drawn to the
screen, it pushes it to the ViewPort.

In general, a graph is an immutable data structure that you manipulate through
transform functions. In the example below `Graph.build()` creates an empty
graph, which is piped into functions that add things to it. The `text/3`
function accepts a graph, adds some text to it, then applies a list of options
to the text.

The `button/3` is similar to `text/3`. It accepts a graph, adds a button and
applies a list of options to.

Text is a [Primitive](overview_primitives.html), which can be drawn directly to
the screen. The `text/3` helper function is imported from the
`Scenic.Primitives` module. Button is a [component](Scenic.Components.html)
whose helper function is imported from the `Scenic.Components` module.

      defmodule MyApp.Scene.Example do
        use Scenic.Scene
        alias Scenic.Graph
        import Scenic.Primitives
        import Scenic.Components

        @graph Graph.build()
          |> text("Hello World", font_size: 22, translate: {20, 80})
          |> button("Do Something", translate: {20, 180})

        def init( scene, _param, _opts ) do
          scene = push_graph( scene, @graph )
          {:ok, scene}
        end

        ...

      end

If you can, **build your graphs at compile time instead of at run time**. This
both reduces load/power use on the device and surfaces any errors early instead
of when the device is in use. In the example above, the graph is built at
compile time by assigning it to the module attribute `@graph`. You can read more
about module attributes in [Elixir's module attribute
documentation](https://elixir-lang.org/getting-started/module-attributes.html).

In the above example, the graph is pushed to the ViewPort during the `init/2`
callback function.

There is more detail on how to build and manipulate Graph data in the [Graph
Overview](overview_graph.html).

## Initialization

The only required callback a Scene must implement is `init/3`. This function is
called when the scene is started and is where you should initialize your state.
Pushing the graph here is optional, but recommended. If you wait too long to
build and push your first graph, the user will see a blank space or screen until
you are ready.

Note that a Scene's state is always a %Scenic.Scene{} struct. Just like Socket in
phoenix, it has an `:assigns` field that is used to store your state

    def init( scene, _param, _opts ) do
      graph =  @graph

      scene =
        scene
        |> assign( graph: graph, my_value: 123 )
        |> push_graph( graph )

      {:ok, scene}
    end

The second argument, `param`, is any term that you pass to your scene when
you reference it or otherwise configure it in the ViewPort. Look at an example
configuration of a ViewPort from the config.exs file...

      import Config

      # Configure the main viewport for the Scenic application
      config :my_app, :viewport, [
            name: :main_viewport,
            size: {700, 600},
            default_scene: {MyApp.Scene.Example, :scene_init_data},
            drivers: [
              [
                module: Scenic.Driver.Local,
                name: :local,
                window: [resizeable: false, title: "Example Application"],
              ]
            ]
          ]

The line `default_scene: {MyApp.Scene.Example, :scene_init_data}`
configures the ViewPort to always start the scene defined by the
`MyApp.Scene.Example` module and to pass in `:scene_init_data` as the
`param` argument of its `init/3` function.

That `:scene_init_data` term could be any data structure you want. It will be
passed to the scene's `init/3` function unchanged.

The `opts` parameter is a Keyword list of contextual/optional data that
is generated by the ViewPort and passed to your scene. The main options are:

option      | description
----------- | -----------
`:id`       | If this scene is a component, then the id that was assigned to its reference in the parent's graph is passed in as the `:id` option. Typically, controls that generate and send events to its parent scene use this id to identify themselves. If this is the root scene, the id will not be set.

## User Input

A Scene also responds to messages. The two types of messages Scenic will send to
the scene are user input and events.

Input is usually comes from the driver, such as mouse clicks and key presses, it
can be handled with `c:Scenic.Scene.handle_input/3`.

Messages are generally sent from child components (such as a button) and can be
handled with `c:Scenic.Scene.handle_event/3`.

## Events

You are free to send your own messages to scenes just as you would with any
other GenServer process. You can use the `handle_info/2`, `handle_cast/2` and
`handle_call/3` callbacks as you would normally.

## Components

Components are simply scenes with a little extra sugar added to make them easy
to use from within another scene. To make a component, call the
`use Scenic.Component` macro instead of the Scene version.

You will then need to add `info/0` and `verify/1` callbacks. The `verify/1`
accepts the `scene_args` parameter that will be passed to the `init/2` function
and verifies that it is correctly formatted. If it is correct, return
`{:ok, data}`. If it is not ok, return `:invalid_data`.

In the event that `verify/1` returns `:invalid_data`, then the `info/1` callback
is called to get a bitstring describing useful information to the developer.
This will be included in the error that gets raised.

      defmodule MyApp.MyComponent do
        use Scenic.Component
        import Scenic.Primitives, only: [{:text, 3}, {:update_opts, 2}]

        def verify( text ) when is_bitstring(text), do: {:ok, text}
        def verify( _ ), do: :invalid_data

        def init( scene, text, opts ) do

          # modify the already built graph
          graph = Graph.build()
            |> text("", text_align: :center, translate: {100, 200}, id: :text)

          scene =
            scene
            |> assign( graph: graph, my_value: 123 )
            |> push_graph( graph )

          {:ok, scene}
        end

        ...

      end

Other than verifying the incoming information, Components work the same as any
other scene.

## Adding Components to a Parent Scene

You can add a component (like the one above) to a scene's graph via the
`add_to_graph/3` public function that is added to your component via the `use
Scenic.Component` macro.

      defmodule MyApp.Scene.ExampleScene do
        @graph Graph.build()
        |> MyApp.MyComponent.add_to_graph(:init_data, translate: {10, 20})
        ...
      end

The first time this graph is submitted to the ViewPort via `push_graph/1`, that
will trigger the [life-cycle](scene_lifecycle.html) management of the
`MyApp.MyComponent` scene process.

If this is a component you intend to make available to other developers, then
you should also create a helper function to make this more compact. Look at the
source code for the `Scenic.Components` module for examples. This entire module
is a collection of helper functions whose job is to provide sugary access to the
basic components' `add_to_graph/3` functions.

With helper functions, the above graph would be re-written like this:

        @graph Graph.build()
        |> my_component( :init_data, translate: {10, 20} )

## What to read next?

Next, you should read about the [life-cycle of a scene](scene_lifecycle.html).
This will explain how scenes get started, when they stop, and how they relate to
each other.
