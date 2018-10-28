# Getting Started with [Nerves](https://nerves-project.org/)

[Nerves](https://nerves-project.org/) is a tool chain that builds your application
into a minimal boot image that you can use to run on devices such as the Raspberry Pi, 
BeagleBone Black, and many more.

Scenic has everything you need to run on in this environment. In fact, this is the
type of system that Scenic was made for! When built with Nerves, the boot-image (this
includes Linux, Erlang, Elixir, Scenic, several fonts, etc) is on the order of 30Mb in
size, which is a welcome relief.

This guide assumes you have some familiarity with [Nerves](https://nerves-project.org/).

## Install `scenic.new`

The Scenic Archive is the home of the `scenic.new` mix task, which lays out a
starter application for you. This is the easiest way to set up a new Scenic
project.

Install the Scenic Archive like this

```bash
mix archive.install hex scenic_new
```

## Create the Basic Nerves App

First, navigate the command-line to the directory where you want to create your
new Scenic app. Then run the following commands:  (change `my_app` to the name
of your app...)

```bash
mix scenic.new.nerves my_app
cd my_app
```

At this point you have a choice. Do you want to build it locally to run on your
dev machine (device specific things won't be there or need to be emulated), or
do you want to build a boot image

## Build and Run on Your Dev Machine

The first time you build a nerves app, you need to set the `MIX_TARGET`, which tells
it where you intend to run your app. Then you can install the dependencies. Do that on the command line like this:

```bash
export MIX_TARGET=host
mix deps.get
```

Then you can run the app on your dev machine the same way you would a non-nervs app.

```bash
mix scenic.run
```

## Build and Run on a Raspberry Pi 3

The first time you build a nerves app, you need to set the `MIX_TARGET`, which tells
it where you intend to run your app. Then you can install the dependencies. When targeting
an embedded device, you will also need to create a release file.

Do that on the command line like this:

```bash
export MIX_TARGET=rpi3
mix deps.get
mix compile
mix nerves.release.init
```

Then you can build the boot image and burn it to your micro-SD card.

```bash
mix firmware.burn
```

## Supported Devices

At the moment, the only supported devices are Raspberry Pis. In fact, the only one I've really tested is the Raspberry Pi 3, although it should work on the others.

Support for the BeagleBone is coming, but isn't ready yet.

## What to read next?

Next, you should read about the [structure of a scene](overview_scene.html).
This will explain the parts of a scene, how to send and receive messages and how
to push the graph to the ViewPort.
