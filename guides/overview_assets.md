# Assets Overview

The assets system has been completely overhauled as of Scenic v0.11. 

Any good-looking UI is a combination of vector drawing via primitives and/or scripts and assets. Assets are the fonts, images, or other types of art that are displayed to the user. These tend to be standard formats, such as a .jpg, .png, or .ttf files.

We can split the world of assets into two categories. These are Static and Streaming assets. Static assets, as the name implies, are set up in advance and never change. They are cache-able, both in memory and via servers. Streaming assets, on the other hand, change over time. They are named, but not cache-able.


## Static Assets

The new static asset pipeline is designed to feel familiar to the Phoenix static asset system. With a bit of configuration, you end up with an "assets" directory in your project directory. The supported files in this directory
are "built" during the compilation process and automatically end up as hashed files that can be loaded at run time.

The Static Assets Library consists of several parts
  * An asset module that you create in your project. This is where the actual library is stored and built.
  * A source directory that contains the assets you want to use in your project.
  * A config.exs item that links Scenic to you Assets module.


Once those pieces are configured, then your assets are built when you compile your application. You can add more assets by simply dropping them into the assets directory. Note, they must be one of the supported types.

Example directory structure
```
my_cool_project
  assets
    fonts
      custom_font.ttf
      another_font.ttf
    images
      parrot.jpg
```

Example Assets Module
```elixir
defmodule MyApplication.Assets do
  use Scenic.Assets.Static,
    otp_app: :my_application,
    alias: [
      parrot: "images/parrot.jpg"
    ]
end

```

Example config
```elixir
config :scenic, :assets, module: MyApplication.Assets
```

Example use in a Scene
```elixir
Graph.build()
  |> text( "Some Text", font: "fonts/custom_font.ttf" )
  |> rect( {100, 200}, fill: {:image, "images/parrot.jpg"} )
  |> rect( {100, 200}, fill: {:image, :parrot} )                # uses the alias set up in MyApplication.Assets
```

Both of the rectangles in the above example render the same image. One uses a string that gives the local path in your assets folder. The other uses an alias that is configured to point to the same image in the Assets Module.

The main "gotcha" left in the static assets system is that Scenic does not yet have a filesystem watcher. When you add or change a font or image in your assets folder, you may need to touch your Assets module (`MyApplication.Assets` in the above example) to get it to recompile.

### Under the covers

Several things happen under the covers when you build your project
1) The use Scenic.Assets.Static part of your Assets module, activates some code that scans your assets directory - looking for assets of known types.
2) It computes a cryptographic hash for asset, parses out metadata, and builds a library of metadata and hashes.
3) That library is stored as a term in Assets module.
4) The contents of the assets file is copied into a new file in your build directory. The name of that file is the bin-hex of the computed hash.

If you want to see the contents of your asset library, you can get to it like this:

```elixir
MyApplication.Assets.library()

# or

Scenic.Assets.Static.library()
```

When you add new assets to your assets directory, you need to kick off this process by touching your assets module. Add a return or a space or something. Eventually, we will have a file watcher that does this for you.


## Streaming Assets

What used to be called the `Scenic.Cache.Dynamic`, is now Scenic.Assets.Stream and Scenic.Assets.Stream.Texture. This is for images that you generate on the fly (charts, bit rendered game screens, rotating colors, etc...) or frames that you capture live from a camera.

The goal is to separate the source of these images from the consumers (the drivers) in a way that is latency/bandwidth friendly and is easy to use.

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