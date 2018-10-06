# Life-cycle of a Scene

A very important part of Scenic is the Scene life-cycle management. Most scenes' life-cycles will be managed automatically by their [ViewPort](overview_viewport.html). The ViewPort determines when to start and stop these dynamic scenes.

In effect, when you create a graph and add components like `button`, `checkbox` and more, you are doing more than just saying, "Draw a button here". You instructing the `ViewPort` how and when to start and stop the processes that drive those components.

## The Root Scene

This process starts when you set a root scene into the ViewPort. This is first done when you configure your ViewPort in `config.exs`

      config :my_app, :viewport, %{
        name: :main_viewport,
        size: {700, 600},
        default_scene: {MyApp.Scene.MyFancyScene, :some_init_data},
        ...
      }

In the above configuration, when Scenic first starts up, it will start the configured ViewPort. This ViewPort will, in turn, start up the scene defined in the module `MyApp.Scene.MyFancyScene` and pass in `:some_init_data` as the first parameter to its `init/2` function.

Afterwards, you can dynamically change the root scene by calling `Scenic.ViewPort.set_root/3`. Both ways of setting the root scene effectively do the same thing.

## Dynamically Supervised Scenes

As `MyApp.Scene.MyFancyScene` initializes, it eventually calls its `push_graph/1` function.

When a scene calls `push_graph/1`, the primitives in the graph are sent out for rendering and the components in the graph are started or stopped as needed.

To say it another way, when you reference components like `button`, `checkbox` and the others, you are programming the supervision tree for your scene.

Your scene has an internal `DynamicSupervisor`, which supervises these dynamic scenes that you asked for in your graph. Each of these can also have a dynamic supervisor and spin up more scenes in a nested tree.

At some point, depending on your target processor, you will start to have performance issues if you nest too many components too deeply.

The good news is that as you switch away to different root scenes, all the old components are automatically cleaned up for you.


## App Supervised Scenes

If you have a component scene that is used by may other scenes, or even in multiple ViewPorts at the same time, you can save memory and reduce load by supervising those scenes yourself.

To do this, create a supervisor in your application and start one or more scenes under it. You can give these scenes names, which is how you will reference them from your graphs.

    defmodule MyApp.Scene.Supervisor do
      use Supervisor

      def start_link() do
        Supervisor.start_link(__MODULE__, :ok)
      end

      def init(:ok) do
        children = [
          {MyApp.Scene.AppScene, {:some_init_data, [name: :app_scene]}},
          {Scenic.Clock.Digital, {[], [name: :clock]}}
        ]
        Supervisor.init(children, strategy: :one_for_one)
      end
    end

When you build your graphs, you can now use this statically supervised scene directly through the `scene_ref/3` helper in `Scenic.Primitives`.

    @graph Graph.build()
      |> scene_ref(:app_scene, translate: {300, 300})
      |> scene_ref(:clock, translate: {400, 20})

The main trade-off you make when you supervise a scene yourself is that the scene no longer knows which ViewPort it is running in. It could be several at the same time! You will not be able to use functions like `ViewPort.set_root` from these scenes.

The second tradeoff is that if the root scene _doesn't_ reference a scene you are supervising yourself, then that scene is still taking up memory in both the scene and the driver even though it isn't being drawn.


## What to read next?

If you are exploring Scenic, then you should read the [Graph Overview](overview_graph.html) next.
