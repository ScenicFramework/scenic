# Upgrading to v0.11

## Overview

Version v0.11 is a MAJOR overhaul from the top to the bottom. For the first time, Scenic feels like something approaching a 1.0 in design.
  
  * `Scenic.Cache` is gone. It is replaced by a **much** easier to use asset pipeline.
  * `push_graph` is back. WHAT! Didn't it go away last time? Yes. I've been struggling with the way scene state is handled. Coupled with the scene state change (next in this list), it finally makes sense.
  * State for a scene is now tracked similar to how you add state to a socket in a Phoenix Channel or a Plug conn. The state is always a `%Scene{}` object and you can assign() state into it.
  * The driver engine is a complete re-write. Existing drivers that render will need to be re-written. Sorry. The good news is that they all pretty much did the same thing in generating a "script" of draw commands that was sent over to some renderer. This is now standardized and moved to the ViewPort layer. Drivers are MUCH simpler as a result and more portable.
  * The ViewPort, and even the Scene engines themselves are also re-writes, but their API is very similar to the old version, so not much news there except for the way Scene state is tracked.
  * There is an entirely new Script engine for generating draw scripts that can be sent to drivers. This is quite powerful
  * There are numerous other additions to Scenic
    * The Component primitive is used to refer to, and start components.
    * The Script primitive refers to arbitrary scripts that you can send to drivers.
    * The `:line_height` style now sets the spacing between lines of text. Works like CSS.
    * The `:text_align` style lets you align text vertically.
    * There is a new Scenic.Asset.Stream type for dynamic textures.
    * New Sprite Sheet support via the Sprites primitive
  * There are multiple smaller deprecations. Notably
    * The `:text_height` style is replaced by :line_height, which works the same way line_height does in CSS.
    * The `Path` primitive (which almost got cut, but survived) no longer has the solid and hole commands.
    * The Box Gradient fill is gone.
    * The `:clear_color` style (which was always weird) is gone. You can now set a theme on the viewport (in config), which sets the background color.
    * The SceneRef primitive is gone, and replaced with a combination of Component and Script primitives.
    * The `:font_blur` primitive is gone. Sorry. Didn't have a close enough analog in Canvas
    * The format of the input messages have changed - see the docs
    * The optional styles on some of the standard components (Button) have changed to be more consistent with the standard styles. See documentation.

__Important__
  * `:scenic_driver_local` is the new standard renderer for Scenic. Both `:scenic_driver_glfw` and `:scenic_drives_nerves_rpi` are retired as of v0.11.

The options for the new local driver are NOT the same as they were for the glfw driver. Please read the docs for it. Please see the new [driver overview](overview_driver.html).


I'm sure there's more. Feel free to add any notes if you find something that isn't covered.

## Motivation

The primary motivation for Scenic has always been to provide control surface UI for devices that don't necessarily have a human nearby watching over them. This means IoT, Industrial Control, Critical Systems, Infrastructure, etc... It can be used for other thing (and has been!), but the design choices are more about devices than flash.

I like to say that there are 3 kinds of UI. Think of these as 3 layers, with highest fidelity and lowest latency requirements at the top, and lowest fidelity but best latency tolerance at the bottom.

* __Category 1:__ At the top are games and anything else that uses all the available resources, renders to maximum fidelity. These applications are power hungry, run on local hardware due to latency sensitivity (although there is a lot of research going into cloud hosting) and they strive for the maximum in visual fidelity.
* __Category 2:__ The middle layer is still UI that has latency sensitivity and is meant to be used by consumers in real-time, but the fidelity is dialed way back. Examples in this category are Flutter, QT, and most modern client-heavy web frameworks. When you see consumer appliances with a pretty interface that seems slightly sluggish, but is still trying to be pretty, that is in this layer. They walk the line between using the least expensive hardware they can, and still being pretty for everyday consumers.
* __Category 3:__ The bottom layer knows it is running on inexpensive hardware and usually doesn't have a human using the actual device it runs on directly. It is designed up front to be latency tolerant, consume few resources, to be functional over flashy. Examples include old-school web 1.0 servers, X11 and... Scenic.

Scenic's prime target has always been devices that are deployed in the field. They may or may not have a screen / human interface directly attached (most often don't) and are operated remotely.

Category 3 devices do jobs that are more valuable than the device is. The small controller device that operates the solar farm is worth less than the farm or the electricity it produces. In contrast, our fancy Thermomix blender has a Category 2 UI, and is way more expensive than any of the meals it makes. Or even many meals put together.

The requirements for a category 3 UI on devcies are
* Must be highly robust. Or at least recover quickly and not affect the rest of the device.
* Must be conservative with resources.
* Must be remotable. (The UI can be displayed and used on a different device)
* Must be latency tolerant.

In versions 0.10 and early, Scenic did well on robustness and conservative resource use. It was designed to be latency tolerant, but that was never put to the test as it was not at all remotable. - yet.

Version 0.11 finally takes a crack at making Scenic remotable. Enough time and use has passed that usage patterns have become visible. Some things have worked well (the pattern of scene/primitives/styles/transforms/components) and some things have not (the driver model repeated the same basic complicated code in every driver and the static assets cache was a constant struggle).

Now that the Kry10 Operating System is operational (Scenic long awaited design target), it was time to fix the things that didn't work so well and properly build remoting. These are the sorts of changes that have ripples up the stack and create breaking changes. So best to get it all done in fell swoop.


## Scene State
The most immediate change that you will need to be addressed is now state in a scene is stored and how scenes are started up.

In the old system, I was trying to hard to keep the developer focused on the functionality of their scene, and less with the mechanics of how it worked in the deeper layers. This created a state problem. Essentially, the scene developer needs to keep state for whatever the scene is supposed to be doing. But, the scene engine itself also needs to keep state in order track child components, its `ViewPort`, push graphs to the ViewPort, etc. I've tried various things to keep these states separate and clean. In end... it was all messy.

The only thing that really works is to adopt the same state model as sockets/conns from Phoenix and Plug. That is, there is no state kept under the covers. The state presented to a scene is always now a `%Scenic.Scene{}` struct. Just like Plug and Sockets, there is an `:assigns` map in the struct that the scene developer uses to store their state. Just like those others systems, `assigns()` helpers are provided.

This will require some porting work as you move to v0.11, but at least it feels like the right long-term solution.

```elixir
defmodule MyDevice.Scene.Example do
  use Scenic.Scene
  import Primitives

  def init(scene, _param, _opts) do
    graph = Scenic.Graph.build( font: :roboto )
      |> text( "This is an example", id: :text )

    scene =
      scene
      |> assign( some_state: 123, graph: graph )
      |> push_graph( graph )

    {:ok, scene }
  end

  # display any received events
  def handle_event(event, _, %{assigns: %{graph: graph}} = scene) do
    graph = Graph.modify( graph, :text, &text(&1, inspect(event))

    scene =
      scene
      |> assign( graph: graph )
      |> push_graph( graph )

    {:noreply, scene}
  end

end
```


## `push_graph` is back!
As part of my struggles to find the right scene state model, the `push_graph` function came, and went, and is now back again.

`push_graph/2` is the way you send a graph from a scene to the scene's `ViewPort` for compilation and eventual display through the drivers. Now that all of the scene's state is stored in one place it is finally clear that push_graph can take a scene and a graph, and return a modified scene. It is important to track the scene that is returned, as that is how any components that the graph may spin up are accounted for.


```elixir
  def init(scene, _param, _opts) do

    graph = Scenic.Graph.build( font: :roboto )
      |> button( "Press Me", id: :press_me )

    scene = push_graph( scene, graph )

    {:ok, scene }
  end
end
```

In the above example, the scene/process that runs the button labeled `:press_me` is not started until it is pushed to the ViewPort. This function does quite a bit of work and can start or stop child component processes, tracks pids, compiles the graph for rendering, prepares any input records for input events and more. You can call it as often as you want, but be aware that you may end up causing work to no benefit as the drivers all update on their own heartbeat. In other words, you can push a graph 1000 times per second, but it will still only be drawn 30 times per second or less as as the driver sees fit.

## `handle_input` signature has changed

This is another breaking changed. The old version of handle_input in a scene or component included the relevant id in the input message, which was mixing metaphors, and include a fairly opaque context object that was only there because of the way scene state was handled.

Now that scene state is completely explicit and passed through to the scene, this can be cleaned up. The new `handle_input` function takes three parameters and looks like this.

```elixir
  def handle_input( input_event, hit_id, scene )
```

The input event is now just that. Nothing else is added to it. The hit id in your graph (if any) is passed as the second parameter. It is `nil` if there was nothing hit or if the input event didn't make sense for that sort of thing.

Here is an example from the Button control. In this case, update_color calls the push_graph function and returns the updated state.

```elixir
  # pressed in the button
  @impl Scenic.Scene
  def handle_input( {:cursor_button, {0, :press, _, _}}, :btn, scene ) do
    :ok = capture_input( scene, :cursor_button )

    scene = 
      scene
      |> update_color( true, true )
      |> assign( pressed: true )

    {:noreply, scene}
  end
```

Also notice that which mouse button was clicked is now a number instead of :left or :right. it was presumptive to assume that :left was the primary button. This is neutral and no longer handedness-biased.


## [The Static Asset Library](overview_assets.html)


I, and everybody else, always struggled with the various attempts at the `Scenic.Cache modules`. It was close, but not quite right. The goal is to sensibly load and use static assets like images and fonts, while maintaining cryptographic hashes for security purposes. The old system worked, but required byzantine steps to get it running.

The new asset pipeline is designed to feel familiar to the Phoenix static asset system.

You create an "assets" directory in the root of your project, set up some config to point to it, and create your own Assets module to hold the data. (This part is more like NimblePublisher than Phoenix, but it works really well.)

Then you can just drop images or fonts into you assets folder and they show up and are usable.

Example directory structure
```
my_cool_project
  assets
    fonts
      roboto.ttf
      my_font.ttf
    images
      parrot.jpg
```

Example config
```elixir
config :scenic, :assets, module: MyCoolProject.Assets
```

Example Assets Module
```elixir
defmodule MyCoolProject.Assets do
  use Scenic.Assets.Static,
    otp_app: :my_cool_project,
    alias: [
      parrot: "images/parrot.jpg"
    ]
end

```

Example use in a Scene
```elixir
Graph.build()
  |> text( "Some Text", font: "fonts/my_font.ttf" )
  |> rect( {100, 200}, fill: {:image, "images/parrot.jpg"} )
  |> rect( {100, 200}, fill: {:image, :parrot} )                # uses the alias set up in config
```

## The Streaming Asset Pipeline

What used to be called the `Scenic.Cache.Dynamic`, is now Scenic.Assets.Stream and Scenic.Assets.Stream.Texture. This is for images that you generate on the fly (charts, bit rendered game screens, rotating colors, etc) or frames that you capture live from a camera.

The goal is to seperate the source of these images from the consumers (the drivers) in a way that is latency/bandwidth friendly and is easy to use.

The `Scenic.Assets.Stream` module is a process/api that manages an `:ets` table of streaming assets. This allows a camera to capture frames at whatever rate makes sense for it and to put them into the table when it sees fit. This data is then distributed to any listening drivers, who can do the right thing with it.

Example camera source - ( from some camera source... tbd by developer... )
```elixir
def handle_info( {:camera_0, texture}, state ) do
  :ok = Stream.put( "camera_0", texture )
end
```

Example use in a Scene
```elixir
Graph.build()
  |> rect( {100, 200}, fill: {:stream, "camera_0"} )
```

## Texture API

The old `Scenic.Utilities.Texture` API has been improved and promoted to `Scenic.Assets.Stream.Texture`.

The changes center around the fact that the NIF behind the `put` and `clear` functions breaks the immutable assumptions of the Erlang and Elixir languages. In other words, they operate directly on the backing memory of the texture instead of making a new copy and then changing it. This is for performance reasons. It also create several very hard to track down bugs.

The new API fits better into the erlang world adding the `mutable/1` and `commit/1` function calls. When a texture is mutable, it is not usable by the Stream api. When it is commited, it is usable by Stream, but no longer editable.

```elixir
    t = Texture.build( :rgb, 10, 20 )
      |> Texture.clear( :blue )
      |> Texture.commit()

    :ok = Stream.put( "example", t )
```

You can also specify new textures to be cleared with a specific color and/or committed as build options

```elixir
    t = Texture.build( :rgb, 10, 20, clear: blue, commit: true )
    :ok = Stream.put( "example", t )
```

## Standard Driver

The new standard render driver for all Scenic apps is `:scenic_driver_local`, which is being published to hex at roughly the same time as the beta for Scenic v0.11.

Both `:scenic_driver_glfw` and `:scenic_drives_nerves_rpi` are retired.

This driver provides a single rendering code base for both hosted (Mac/PC/Linux) and Nerves environments. The seperate drivers were 95% the same anyway and it was getting difficult to keep fixes for them in sync.


## Driver Model

Another big change to Scenic is the re-write of the driver model. If your work is all at the scene layer, then this shouldn't affect you. But if you have a custom driver that renders graphs, it will need to be re-written.

The old model sent graphs directly to the drivers. They would then traverse these graphs, translating them into some render specific linear list of commands, which when then, in turn, be passed on to the actual renderer. It was complicated, repeated the same difficult code in every driver, and was difficult to maintain.

The new model moves the traversal or "compilation" of the graphs into the ViewPort layer and standardizes the set of draw commands in the form a linear script. This means the difficult part of all drivers has been done once in the ViewPort layer and drivers themselves have become much simpler.

Drivers are still in charge of how often to render, how to deal with latency, and can intercept/customize the serialization of these scripts into binary form.

See driver documentation for more details. (may not be complete yet...)


## Scripts

As part of the driver re-write, the concept of Draw Scripts has been introduced. When you use `push_graph/2` to send a graph to the ViewPort, it is being compiled into a standard draw script and that is what is actually stored for distribution to the drivers.

This script API is also exposed to scenes, so you can make your own scripts that go outside the confines of the primitives. In fact, that I almost cut the Path primitive as a custom script is almost always a better way to go, but it lives on as a way to insert a limited inline script.

Scripts can be created, and referred to in a graph as an easy to way to use them.

```elixir
  alias Scenic.Script

  def init(scene, _param, _opts) do

    script = Script.start()
      |> Script.fill_color( :green )
      |> Script.draw_rect( 100, 200, :fill )
      |> Script.finish()

    scene = push_graph( scene, graph )

    {:ok, scene }
  end
```

See the `Scenic.Script` module for the full API.


## Scripts vs Scenes

An important point to call out is Scripts are top level objects at the ViewPort. This means that when a Scene creates a script and then refers to it in a graph, the graph and the script are tracked & send to drivers separately. This is a way of separating concerns. A script that is changing rapidly doesn't cause the potentially large and complex graph that references it to update, and vice versa.

In fact, Graphs are now just compiled into scripts. They are no longer stored directly on the ViewPort at all. It is scripts all the way down.


