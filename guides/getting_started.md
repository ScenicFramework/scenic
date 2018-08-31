# Getting Started

This guide will walk you through installing the OpenGL related dependencies, then building your first Scenic application.

## Install Dependencies

The design of Scenic goes to great lengths to minimize its dependencies to just the minimum. Namely, it needs Erlang/Elixir and OpenGL. The OpenGl dependency on the Mac, Ubuntu and other windowed systems takes the form of the GLFW libraries.

The instructions below assume you have already installed Elixir/Erlang. If you need to install Elixir/Erlang there are instructions on the [elixir-lang website](https://elixir-lang.org/install.html).

Rendering your application into a window on your local computer is done by the `scenic_driver_glfw` driver. It needs the GLFW libraries and a little more to build and link to them.

### Installing on MacOS

The easiest way to install on MacOS is to use Homebrew. Just run the following in a terminal:

      brew update
      brew install glfw3 glew pkg-config

Once these components have been installed, you should be able to build the `scenic_driver_glfw` driver.

### Installing on Ubuntu

Similar to the Mac, you will need to install a few components.

The easiest way to install on Ubuntu is to use apt-get. Just run the following:

      apt-get update
      apt-get install glfw3 glew pkg-config 


## Install `scenic.new`

The Scenic Archive is the home of the scenic.new mix task, which lays out a starter application for you. This is the easiest way to set up a new Scenic project.

Install the Scenic Archive like this

      mix archive.install hex scenic_new



## Build the Starter App


## What to read next

Next, you should read about the [structure of a scene](scene_structure.html). This will explain the parts of a scene, how to send and receive messages and how to push the graph to the ViewPort.