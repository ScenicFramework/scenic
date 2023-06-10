# Life-cycle of a Scene

A very important part of Scenic is the Scene life-cycle management. Most scenes' life-cycles will be managed automatically by their [ViewPort](overview_viewport.html). The ViewPort determines when to start and stop these dynamic scenes.

In effect, when you create a graph and add components like `button`, `checkbox` and more, you are doing more than just saying, "Draw a button here". You are instructing the `ViewPort` how and when to start and stop the processes that drive those components.

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

## What to read next?

If you are exploring Scenic, then you should read the [Graph Overview](overview_graph.html) next.
