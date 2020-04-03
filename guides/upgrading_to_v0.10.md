# Upgrading to v0.10

Version 0.10 of Scenic contains breaking changes, which will need to be updated in your app in order to run. This is all good through as it enables goodness in the forms of proper font metrics and dynamic raw pixel textures.

## Overview

Version v0.10 contains two fairly major changes in how things work.
  
  * `Scenic.Cache` has been reorganized into asset-specific caches. **This is a breaking change.**
  * `push_graph` is deprecated and replaced with a more functional-style return value. This is not a breaking change, but it throws warnings as going forward, the new return values are the way to go.

The changes to the cache are described first as they are breaking changes. The non-breaking push_graph deprecation will probably be more work to integrate, but you don't need to do it as immediately.

## Changes to the Cache

The most important (and immediate) change you need to deal with is to the cache. In order to handle static items with different life-cycle requirements, the cache has been broken out into multiple smaller caches, each for a specific type of content.

The module `Scenic.Cache` is gone and should be replace with the appropriate cache in your code.

| Asset Type | Module |
| --- | --- |
| Static Textures | `Scenic.Cache.Static.Texture` |
| Fonts | `Scenic.Cache.Static.Font` |
| Font Metrics | `Scenic.Cache.Static.FontMetrics` |
| Dynamic Textures | `Scenic.Cache.Dynamic.Texture` |

## Static vs. Dynamic Caches

Note that caches are marked as either static or dynamic. Things that do not change and can be referred to by a hash of their content go into Static caches. This allows for future optimizations, such as caching these assets on a CDN.

The Dynamic.Texture cache is for images that change over time. For example, this could be an image coming off of a camera, or something that you generate directly in your own code. Note that Dynamic caches are more expensive overall as they will not get the same level of optimization in the future.

### Custom Fonts

If you have used custom fonts in your application, you need to use a new process to get them to load and render.

1. Use the `truetype_metrics` tool in hex to generate a `\*.metrics` file for your custom font. This will live in the same folder as your font.
2. Make sure the name of the font file itself ends with the hash of its content. If you use the `-d` option in `truetype_metrics`, then that will be done for you.
3. Load the font metrics file into the `Scenic.Cache.Static.FontMetrics` cache. The hash of this file is the hash that you will use to refer to the font in the graphs.
4. Load the font itself into the `Scenic.Cache.Static.Font`

## Deprecation of push_graph()

The `push-graph/1` function is now deprecated. It still works, but has been replaced with a much more functional-style `{:push, graph}` return value.

This has several immediate benefits. The main advantage is that you can now use all the standard OTP 21+ callbacks, including handle_continue, timeouts and the like. If you call push_graph(), it sends a message back to the scene, so the timeouts will not work. The new form corrects this situation.

It also lowers the overall draw latency a little bit. There is one less passed-message for rendering to serialize on.

### Changes to make

Making the switch is fairly straight forward. A typical scene pattern with push_graph would look like this

```elixir
defmodule MyApp.Scene.Example do
  use Scenic.Scene
  alias Scenic.Graph
  import Scenic.Primitives
  import Scenic.Components

  @graph Graph.build()
    |> text("Hello World", id: :my_text, font_size: 22, translate: {20, 80})
    |> button({"Do Something", :my_btn}, translate: {20, 180})

  def init( _scene_args, _options ) do
    push_graph( @graph )
    {:ok, {:could_be_any_state, @graph}}
  end

  def handle_event({:click, :my_btn}, _, {inner_state,graph}) do
    graph = Graph.modify(graph, :my_text, &text(&1, "Hello Scene"))
    |> push_graph()
    {:noreply, {inner_state,graph}}
  end
end

```

This same scene would now look like this

```elixir
defmodule MyApp.Scene.Example do
  use Scenic.Scene
  alias Scenic.Graph
  import Scenic.Primitives
  import Scenic.Components

  @graph Graph.build()
    |> text("Hello World", id: :my_text, font_size: 22, translate: {20, 80})
    |> button({"Do Something", :my_btn}, translate: {20, 180})

  def init( _scene_args, _options ) do
    {:ok, {:could_be_any_state, @graph}, push: @graph}
  end

  def handle_event({:click, :my_btn}, _, {inner_state,graph}) do
    graph = Graph.modify(graph, :my_text, &text(&1, "Hello Scene"))
    {:noreply, {inner_state,graph}, push: graph}
  end
end
```

This may not look like a very big change, but the impact is significant, and simpler under the covers.

The key is that you indicate that you want to push a graph by returning a `{:push, graph}` option when you exit any scene handler function. This optional value can be combined with `timeout` or `{:continue, term}` options as well (although not both at the same time...)

```elixir
defmodule MyApp.Scene.Example do
  use Scenic.Scene
  alias Scenic.Graph
  import Scenic.Primitives
  import Scenic.Components

  @graph Graph.build()
    |> text("Hello World", id: :my_text, font_size: 22, translate: {20, 80})
    |> button({"Do Something", :my_btn}, translate: {20, 180})

  def init( _scene_args, _options ) do
    {:ok, {:could_be_any_state, @graph}, push: @graph, continue: :some_term}
  end

  def handle_event({:click, :my_btn}, _, {inner_state,graph}) do
    graph = Graph.modify(graph, :my_text, &text(&1, "Hello Scene"))
    {:noreply, {inner_state,graph}, push: graph, timeout: 1000}
  end
end
```

The [callbacks section of the scene documentation](Scenic.Scene.html#callbacks) is now properly filled out, so please refer to that for more information on each of the available return values.
