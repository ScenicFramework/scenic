# Getting Started

This guide will walk you through installing the OpenGL related dependencies, then building your first Scenic application.

## Install Dependencies

The design of Scenic goes to great lengths to minimize its dependencies to just the minimum. Namely, it needs Erlang/Elixir and OpenGL.

Rendering your application into a window on your local computer (MacOS, Ubuntu and others) is done by the `scenic_driver_glfw` driver. It uses the GLFW and GLEW libraries to connect to OpenGL.

The instructions below assume you have already installed Elixir/Erlang. If you need to install Elixir/Erlang there are instructions on the [elixir-lang website](https://elixir-lang.org/install.html).


### Installing on MacOS

The easiest way to install on MacOS is to use Homebrew. Just run the following in a terminal:

      brew update
      brew install glfw3 glew pkg-config

Once these components have been installed, you should be able to build the `scenic_driver_glfw` driver.

### Installing on Ubuntu

The easiest way to install on Ubuntu is to use apt-get. Just run the following:

      apt-get update
      apt-get install pkgconf libglfw3 libglfw3-dev libglew2.0 libglew-dev

Once these components have been installed, you should be able to build the `scenic_driver_glfw` driver.

## Install `scenic.new`

The Scenic Archive is the home of the scenic.new mix task, which lays out a starter application for you. This is the easiest way to set up a new Scenic project.

Install the Scenic Archive like this

      mix archive.install hex scenic_new
s

## Build the Starter App


First, navigate the command-line to the directory where you want to create your new Scenic app. Then run the following commands:  (change my_app to the name of your app...)

      mix scenic.new

Thn move into the newly created directory

      cd my_app

Then get the dependencies and run your new application.

      mix do deps.get, scenic.run


## Running and Debugging

Once the app and its dependencies are set up, there are two main ways to run it.

If you want to run your app under IEx so that you can debug it, simply run

      iex -S mix

This works just like any other Elixir application.

If you want to run your app outside of iex, you should start it like this:

    mix scenic.run


## What to read next

Next, you should read about the [structure of a scene](scene_structure.html). This will explain the parts of a scene, how to send and receive messages and how to push the graph to the ViewPort.