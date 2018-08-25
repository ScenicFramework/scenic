# Structure of a Scene

A Scene is a GenServer process. They create the Graphs that get drawn to the
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
them as messages. This is explained more below.

The lifecycle of scenes (when they start, stop, etc.) is explained in the
[lifecycle of a scene](scene_lifecycle.html) guide.



## The Graph

The most important state a Scene is responsible for is its Graph. The Graph defines
what is to be drawn to the screen, any referenced components, and the overal draw
order. When the Scene decides the graph is ready to be drawn to the screen, it pushes
it to the Viewport.


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