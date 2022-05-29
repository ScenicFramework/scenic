# Driver Overview

Drivers live at the bottom of the scenic stack. Drivers know nothing about the scenes you are running. They receive compiled scripts and assets from the viewport and are responsible for rendering them into pretty pictures on the screen.

Drivers also receive input from the user and send that into the ViewPort for processing.

## Scenic.Driver.Local

In Scenic v0.11 the main driver you use to render locally (meaning on a screen attached to the same computer your app is running on) is the `:scenic_driver_local`.

In older versions of Scenic, you used a glfw specific driver to render on a Mac/PC/Linux machine and a separate driver to render on Nerves. These drivers were 95% the same and only really differed in how it initialized the graphics sub systems.

This create a situation that was difficult to maintain and difficult to explain.

These drivers have been combined into a new driver that covers both scenarios. So you can use `:scenic_driver_local` on Mac, PC, Linux, and Nerves.

## Configuration of Scenic.Driver.Local

The configuration options for `:scenic_driver_local` are similar to, but not the same as, those for the previous drivers. This is because as a unified driver, we can't make certain assumptions.

For example, the window title, or whether or not it is resizable has no meaning on an embedded device, but is still used on a PC.

Another example is that the actions it should take when the driver closes is different. An embedded device should always do its best to stay running, whereas closing the window on a Mac should probably cause it to stop the app.

You will need to make a few config tweaks.

There are a few new options that probably make more sense on an embedded device but are very cool... You can now rotate the UI, scale it to fit a screen, center it, etc, just by setting config options.

This is an example of a config (which is in turn part of a ViewPort config) that is oriented toward running on a Mac/PC/Linux machine.

```elixir
[
  module: Scenic.Driver.Local,
  window: [title: "Local Window", resizeable: true],
  on_close: :stop_system
]
```

This is an example of a embedded style config.

```elixir
[
  module: Scenic.Driver.Local,
  position: [scaled: true, centered: true, orientation: :normal]
],
```

Please see the docs for `:scenic_driver_local` for the full set of options.
