# Structure of a Scene

A Scene is a `GenServer` process. They create the Graphs that get drawn to the
screen and respond to user input and other events.

Scenes can reference each other, creating a logical hierarchy that lives above
the Graphs themselves. This allows scenes to be reusable, small, and simple. A
properly designed scene should do one job, and do it well. Then it can be reused
along with other simple scenes to create a complex screen of UI.

Scenes that are specifically meant to be reused are called components. Components
have sugar apis that make them very easy to use inside of a parent scene.

For example, if you create a dashboard. It may have buttons, text input,
sliders, or other input controls in it. Each of those controls is a component scene
that is dynamically created when the dashboard scene is started. This collection
of scenes forms a graph, which can be quite deep (scenes using scenes using scenes).

All these scenes communicate with each other by generating events and passing
them as messages. This is [explained more below](#events).

The lifecycle of scenes (when they start, stop, etc.) is explained in the
[lifecycle of a scene](scene_lifecycle.html) guide.


## The Graph

The most important state a Scene is responsible for is its Graph. The Graph defines
what is to be drawn to the screen, any referenced components, and the overal draw
order. When the Scene decides the graph is ready to be drawn to the screen, it pushes
it to the Viewport.

In general, a graph is immutable data structure that you manipulate through transform
functions. In the example below `Graph.build()` creates an empty graph, which is piped
into functions that add things to it. The `text/3` function accepts a graph, adds some
text to it, then applies a list of options to the text.

The `button/3` is similar to `text/3`. It accepts a graph, adds a button and applies
a list of options to.

Text is a [Primitive](overview_primitives.html), which can be drawn directly to the
screen. The `text/3` helper function is imported from the `Scenic.Primitives` module.
Button is a [component](standard_components.html) whose helper function is imported
from the `Scenic.Components` module.


      defmodule MyApplication.Scene.Example do
        use Scenic.Scene
        alias Scenic.Graph
        import Scenic.Primitives
        import Scenic.Components

        @graph Graph.build()
          |> text("Hello World", font_size: 22, translate: {20, 80})
          |> button({"Do Something", :btn_something}, translate: {20, 180})

        #--------------------------------------------------------
        def init( _scene_args, _viewport ) do
          push_graph( @graph )
          {:ok, @graph}
        end

        ...

      end

If you can, build your graphs at compile time instead of at run time. This both reduces
load/power use on the device and surfaces any errors early instead of when the
device is in use.

In the above example, the graph is built at run time, then pushed to the ViewPort during
`init/2` callback function.

There is more detail on how to build and manipulate Graph data in the [Graph Overview]().

## Initialization

The only required callback a Scene must implement is `init/2`. This function is called when
the scene is started and is where you should initialize your state. Pushing the graph here
is optional, but recommended. If you wait too long to build and push your first graph, the
user will see a blank space or screen until you are ready.

    def init( _scene_args, viewport ) do
      push_graph( @graph )

      state = %{
        graph: @graph
        viewport: viewport
      }

      {:ok, state}
    end


The first argument, `scene_args`, is any term that you pass to your scene when you reference
it or otherwise configure it in the ViewPort. Look at an example configuration of a
ViewPort from the config.exs file...

      use Mix.Config

      # Configure the main viewport for the Scenic application
      config :my_application, :viewport, %{
            name: :main_viewport,
            size: {700, 600},
            default_scene: {MyApplication.Scene.Example, :scene_init_data},
            drivers: [
              %{
                module: Scenic.Driver.Glfw,
                name: :glfw,
                opts: [resizeable: false, title: "Example Application"],
              }
            ]
          }

The line `default_scene: {MyApplication.Scene.Example, :scene_init_data}` configures the
ViewPort to always start the scene defined by the `MyApplication.Scene.Example` module
and to pass in `:scene_init_data` as the first argument of its `init/2` function.

That `:scene_init_data` term could be any data structure you want. It will be passed to
the scene's `init/2` function unchanged.

The second parameter, `viewport` is the pid of the ViewPort that is managing the
[lifecycle](scene_lifecycle.html) of this Scene. If you are supervising the scene yourself,
this will be `nil`.


## Pushing a Graph

`push_graph/1` is a "magic" function. Magic functions embody knowledge of the system
outside of the data passed into them and are not purely "functional" the
programming sense. I am against using magic functions, however, after much thought and
experimentation, I landed on this one bit of magic to accomplish a difficult job.

`push_graph/1` is a private function that is injected into your scene by the
`use Scenic.Scene` macro. Your scene will not work without it.

In a nutshell, `push_graph/1` does two jobs.

First, it triggers the [lifecycle](scene_lifecycle.html) of any components the graph
references. This means that Component processes may start or stop if when you push
a graph. This will only happen if you change components used in the graph.

Second, it prepares the graph for use by the Drivers and the input path of the ViewPort.
This mostly involves stripping internal data and caching the resulting term in
an [ets](https://elixirschool.com/en/lessons/specifics/ets/) table so that it can be
used very quickly, on demand by those systems.

`push_graph/1` returns the original graph passed in to it. This is so you can hang
the call off the end of a pipe chain that transforms the graph. This isn't really
necessary, but I like it as it visually indicates that the graph was transformed
and pushed as a logical unit.

      graph
      |> Graph.modify(:background, &update_opts(&1, fill: clear_color) )
      |> push_graph()

More on `Graph.modify` in the [input](#user-input) and [events](#events) sections below. Also see the [Graph Overview](overview_graph.html) page.


As you can guess, `push_graph/1` is relatively heavy since it scans every node in
your graph every time you call it. You should only call it once per input or event
that you handle. A best practice is to make multiple modifications to a graph and
then call `push_graph/1` once at the end.

      graph = graph
      |> Graph.modify(:text, &text(&1, "I've been modified") )
      |> Graph.modify(:a_box, &rect(&1, {100, 200}) )
      |> Graph.modify(:a_circle, &update_opts(&1, fill: :blue) )
      |> push_graph()


## Components



## User Input

A Scene also responds to messages. The two types of messages Scenic will send to
scene are user input, and events.


## Events

You are free to send your own messages to scenes just as you would with any other
GenServer process. You can use the handle_info/2, handle_cast/2 and handle_call/3
callbacks as you would normally.



# What to read next

Next, you should read about the [lifecycle of a scene](scene_lifecycle.html). This will explain how scenes get started, when the stop, and how they relate to each other.