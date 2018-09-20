# Primitives Overview

Primitives are the simplest thing that Scenic know how to draw to the screen. Everything that you see in a Scenic application is drawn by combining multiple primitives together to make complex UIs.

There is a fixed set of primitives. This simplifies the internals of Scenic, particularly when it comes to communicating to the drivers. New primitives may be added in the future, but those require serious thought and coordination.

* [`Arc`](Scenic.Primitive.Arc.html) draws an arc. This would be a line cut out of a part of the edge of a circle. If you want a shape that looks like a piece of pie, then you should use the [`Sector`](Scenic.Primitive.Sector.html).
* [`Circle`](Scenic.Primitive.Circle.html) draws a circle. 
* [`Ellipse`](Scenic.Primitive.Ellipse.html) draws an ellipse.
* [`Group`](Scenic.Primitive.Group.html) doesn't draw anything. Instead, it creates a node in the graph that you can insert more primitives into. Any styles or transforms you apply to the Group are inherited by all the primitives below it.
* [`Line`](Scenic.Primitive.Line.html) draws a line.
* [`Path`](Scenic.Primitive.Path.html) is sort of an escape valve for complex shapes not covered by the other primitives. You supply a list of instructions, such as :move_to, :line_to, :bezier_to, etc to generate a complex shape.
* [`Quad`](Scenic.Primitive.Quad.html) draws polygon with four sides.
* [`Rectangle`](Scenic.Primitive.Rectangle.html) draws a rectangle.
* [`RoundedRectangle`](Scenic.Primitive.RoundedRectangle.html) draws a rectangle with the corners rounded by a given radius.
* [`SceneRef`](Scenic.Primitive.SceneRef.html) doesn't draw anything by itself. Instead it points to another scene/graph and tells the driver to draw that here.
* [`Sector`](Scenic.Primitive.Sector.html) draws a shape that looks like a piece of pie. If you want to stroke just the curved edge, then combine it with an [`Arc`](Scenic.Primitive.Arc.html).
* [`Text`](Scenic.Primitive.Text.html) draws a string of text.
* [`Triangle`](Scenic.Primitive.Triangle.html) draws a triangle.

## Using Primitives

The easiest way to insert primitives into your graph is to import the functions in `Scenic.Primitives` into your scene module. This adds a helper function for each primitive that you can use in a pipeline to build a graph.

      defmodule MyApp.Scene.Example do
        use Scenic.Scene
        alias Scenic.Graph
        import Scenic.Primitives

        @graph Graph.build(font: :roboto, font_size: 22)
          |> text("Hello World", text_align: :center, translate: {300, 350})
          |> circle(150, fill: :green, translate: {300, 350})

        ...

      end

In the example above, the scene calls `import Scenic.Primitives`, which imports helpers for all the primitives. Since the graph only uses text and circle, you could save a tiny bit of memory by just importing what you need.

        import Scenic.Primitives, only: [{:text,3}, {:circle, 3}]

Once the helpers are imported, you call each call appends a primitive to the graph.

## Styles

In addition to the fixed set of primitives, there is also a fixed set of primitive styles. (Some components support more styles, but they really get boiled down to the primitive styles when it is time to render)

[Read more about the styles here.](overview_styles.html)

Styles are inherited down the graph hierarchy. This means that if you set a style on the root of a graph, or in a group, then any primitives below that node inherit those styles without needing to explicitly set them on every single primitive.

For example, in the following graph, the font and font_size styles are set at the root. Both text primitives inherit those values, although the second one overrides the size with something bigger.

    @graph Graph.build(font: :roboto, font_size: 24)
      |> text("Hello World", translate: {300, 300})
      |> text("Bigger Hello", font_size: 40, translate: {400, 300})


## Transforms

The final type of primitive control is transforms. Unlike html, which uses auto-layout to position items on the screen, Scenic moves primitives around using matrix based transforms. This is common in video games and provides powerful control of your primitives.

A [matrix](https://en.wikipedia.org/wiki/Matrix_(mathematics)) is an array of numbers that can be used to change the positions, rotations, scale and more of locations.

**Don’t worry!** You will not need to look at any matrices unless you want to get fancy. In Scenic, you will rarely (if ever) create matrices on your own (you can if you know what you are doing!), and will instead use the transform helpers.

[You can read about the transform types here.](overview_transforms.html)

Transforms are inherited down the graph hierarchy. This means that if you place a rotation transform at the root of a graph, then all the primitives will be rotated around a common point.

If you want to zoom in, scroll, or rotate a UI, or just pieces of the UI, you can do that very easily by applying transforms.

In the example below, the first text line is translated, and the second is scaled bigger, and the whole graph rotated 0.4 radians.

    @graph Graph.build(font: :roboto, font_size: 24, rotate: 0.4)
      |> text("Hello World", translate: {300, 300})
      |> text("Bigger Hello", font_size: 40, scale: 1.5)


## Modifying a Primitive

Scenic was written specifically for Erlang/Elixir, which is a functional programming model with immutable data.

As such, once you make a graph, it stays in memory unchanged - until you change it via `Graph.modify/3`. Technically you never change it (that's the immutable part), instead Graph.modify returns a new graph with different data in it.

    @graph Graph.build(font: :roboto, font_size: 24, rotate: 0.4)
      |> text("Hello World", translate: {300, 300}, id: :small_text)
      |> text("Bigger Hello", font_size: 40, scale: 1.5, id: :big_text)

In the above graph, we've assigned `:id` values to both primitives. This makes it easy to find and modify that primitive in the graph. `Graph.modify/3` is very fast at finding primitives marked with an `:id`. If you marked multiple primitives withe `id: :small_text`, then they would all be modified by the call to  `Graph.modify/3`

    graph =
      @graph
      |> Graph.modify( :small_text, &text(&1, "Smaller Hello", font_size: 16))
      |> Graph.modify( :big_text, &text(&1, "Bigger Hello", font_size: 60))
      |> push_graph()

Notice that the graph is modified multiple times in the pipeline. The `push_graph/1` function is relatively heavy when the graph references other scenes. The recommended pattern is to make multiple changes to the graph and then push once at the end.

The last parameter to `Graph.modify/3` is a pointer to a function that receives a primitive and returns the the new primitive that should be inserted in its place.

The following is the same as one of the calls above, but in expanded form to make it easier to see what is going on

    graph = Graph.modify( graph, :small_text, fn(primitive) ->
      text(primitive, "Smaller Hello", font_size: 16)
    end)


## What to read next?

If you are exploring Scenic, then you should read the [Styles Overview](overview_styles.html) next.
