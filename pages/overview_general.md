# General Overview

Scenic is a client application and UI framework\* written directly on the Elixir/Erlang/OTP stack. With it you can build applications that operate identically across all supported operating systems, including MacOS, Ubuntu, Nerves and more.

\* Framework. Library. Whatever. It is opinionated on how UI should be built in a functional and highly available world. Other parts of the application are still up to you.

## Goals
(Not necessarily in order)

* **Highly Available**: Scenic takes full advantage of OTP supervision trees to create applications that are fault-tolerant, self-healing, and operational under adverse conditions.

* **Small and Fast**: The only core dependencies are Erlang/OTP and OpenGL.

* **Self Contained**: “Never trust a device if you don’t know where it keeps its brain.” The logic to run a device should be on the device and it should remain operational even if the service it talks to is unavailable.

* **Maintainable**: Each device knows how to run itself. This lets teams focus on new products and only updating the old ones as the business needs.

* **Remotable**: Scenic devices know how to run themselves, but can still be accessed remotely. Remote traffic attempts to be as small so it can be used over the internet, cellular modems, bluetooth, etc.

* **Reusable**: Collections of UI can be packaged up for reuse with, and across applications. I expect to see Hex packages of controls, graphs, and more available for Scenic applications.

* **Flexible**: Scenic uses matrices similar to game development  to position everything. This makes reuse, scale, positioning and more very flexible and simple.

* **Secure**: Scenic is designed with an eye towards security. For now, the main effort is to keep it simple. No browser, javascript and other complexity presenting vulnerabilities. There will have much more to say about security later.

## Non-Goals

* **Browser**: Scenic is **not** a web browser. It is aimed at fixed screen devices and certain types of windowed apps. It knows nothing about HTML.

* **3D**: Scenic is a 2D UI framework. It uses techniques from game development (such as transform matrices), but it does not support 3D drawing at this time.

* **Immediate Mode**: In graphics speak, Scenic is a retained mode system. If you need immediate mode, then Scenic isn’t for you. If you don’t know what retained and immediate mode are, then you are probably just fine. For reference: HTML is a retained mode model.

## Architecture

Scenic is built as a three-layer architectural cake.

At the top is the **Scene Layer**, which encapsulates all application business logic. The developer will do most of their Scenic work in the Scene layer.

At the bottom is the **Driver layer**, which is where knowledge of the graphics hardware and/or remote configuration lives. Drivers draw everything on the screen and originate the raw user input. Developers can write their own drivers, but that will be rare if at all. Dealing with Sensors and other hardware is a different problem space.

In the middle is the **ViewPort Layer**, which acts as bridge between the Scenes and the Drivers. It shuttles data back and forth between them. The ViewPort also maintains the dynamic scene supervision hierarchy. (More on that in the [Scene Overview](overview_scene.html) page) and routes incoming user input from the drivers up to the correct scene.

## Mental Model

Scenic is definitely not a browser and has nothing to do with HTML. However, its design attempts to draw analogies to web design so that a developer with experience building web pages will catch on very quickly.

The following terms include HTML analogies as appropriate…

## Terms (with analogies):

* **Scene**: Scenes are sort of like a web page. Each scene is a GenServer process that contains state and business logic to handle user input. As the device navigates to different screens, it is moving between scenes.

* **Graph**: A Graph is sort of like the DOM. It is a hierarchical graph of data that describes everything that is drawn on the screen. The Graph is immutable in the functional coding sense and is manipulated through transform functions.

* **Primitive**: Each drawable node in a graph is a Primitive. There is relatively small, fixed set of primitives, but they can be combined to draw almost any UI you need.

* **Component**: A component is just a Scene, with a little extra sugar so that it can be referenced/used by other Scenes. This allows you to build libraries of reusable components that contain their own Graph and event handling that you can easy re-use from top-level scenes. Standard controls such as Button, RadioGroup, Slider and more are written as components. In HTML, these are typically input controls. Scenic is more flexible as you can wrap any scene up into a reusable component, even it wraps other components inside of itself!

* **Style**: Styles are sort of analogous to CSS styles, minus the classes. Styles are optional configurations you can add to any primitive in a graph. They are inherited down the hierarchical tree. For example, if you set a font style at the top of a graph, all text will be rendered in that font, unless it is overridden by another font style further down the graph. Components may or may not use the inherited styles.

* **Transform**: All positioning, rotation, scale and such is expressed by applying transform matrices to nodes in a Graph. Transforms are inherited down the graph and always affect referenced components. You will almost never interact directly with the matrices, as there are very easy helpers that manage them for you.

* **ViewPort**: A ViewPort is sort of like a tab in your favorite browser. A ViewPort has a root scene, which may in turn use many components in a deep tree of scenes. If you want multiple windows of UI open on your Mac, then you need to start multiple ViewPorts. Each ViewPort routes incoming User Input to the correct scene or component and sends graphs down to the drivers.

* **Driver**: Drivers know nothing about scenes, but are able to render Graphs to a specific device. That could be a graphics chip, or the network… Drivers also collect raw user input and route it back up to the ViewPort.

* **User Input**: There is a fix set of user input types (mouse, keyboard, touch, etc…) that drivers generate and hand up to the ViewPort. The ViewPort in turn sends the input as a message to the appropriate Scene. Scene’s handle raw user input via the ‘handle_input/3’ callback.

* **Event**: In response to user input (or timers or any other message), a component can generate an event message that it sends up to it’s parent scene. Unlike raw user input, if the parent doesn’t handle it, it is passed up again to that component’s parent until it reaches the root scene. Scenes handle events that are bubbling up the chain via the ‘filter_event/3’ callback. The ViewPort takes care of sending events to the correct parent. This is analogous to event bubbling on a web page.



# Positions, rotation, scale and more


