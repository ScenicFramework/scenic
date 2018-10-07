# Graph Overview

The most important state a Scene is responsible for is its Graph. The Graph
defines what is to be drawn to the screen, any referenced components, and the
overall draw order. When a Scene decides the graph is ready to be drawn to the
screen, it pushes it to the Viewport.

Graphs are made out of a handful of primitives, each of which knows how to draw
one thing. When multiple primitives are put together, almost any standard UI can be drawn.

For example, the graph below shows the words "Hello World" around them.

    @graph Graph.build(font: :roboto, font_size: 24)
      |> text("Hello World", text_align: center, translate: {300, 300})
      |> circle(100, stroke: {2, :green} translate: {300, 300})

In the example above, the first line creates a new graph and assigns two font styles to its root. The next two lines form a pipeline that adds primitives to the root
node of the new graph. Each of these primitives also assigns styles.

## Primitives

There is a fixed set of primitives that Scenic knows how to draw. These form the base set of things that you can do. While they seem simple, when combined you draw pretty much any 2D UI that you need.

[Read more about the primitives here.](overview_primitives.html)

In general, each primitive renders one thing to the screen. The Group primitive is
sort of like a `<div>` tag in html in that it creates a new node in the graph hierarchy that more primitives can be organized beneath.

Each primitive can also be assigned styles and transforms, which affect how (or whether) they are drawn and where.

## Styles

In addition to the fixed set of primitives, there is also a fixed set of primitive styles. (Some components support more styles, but they really get boiled down to the primitive styles when it is time to render)

[Read more about the styles here.](overview_styles.html)

Styles are inherited down the graph hierarchy. This means that if you set a style on the root of a graph, or in a group, then any primitives below that node inherit those styles without needing to explicitly set them on every single primitive.

For example, in the following graph, the font and font_size styles are set at the root. Both text primitives inherit those values, although the second one overrides the size with something bigger.

    @graph Graph.build(font: :roboto, font_size: 24)
      |> text("Hello World", translate: {300, 300})
      |> text("Bigger Hello", font_size: 40, translate: {400, 300})


## Transforms

The final type of primitive control is transforms. Unlike html, which uses auto-layout to position items on the screen, Scenic moves primitives around using matrix transforms. This is common in video games and provides powerful control of your primitives.

A [matrix](https://en.wikipedia.org/wiki/Matrix_(mathematics)) is an array of numbers that can be used to change the positions, rotations, scale and more of locations.

**Don’t worry!** You will not need to look at any matrices unless you want to get fancy. In Scenic, you will rarely (if ever) create matrices on your own (you can if you know what you are doing!), and will instead use the transform helpers.

[You can read about the transform types here.](overview_transforms.html)

Transforms are inherited down the graph hierarchy. This means that if you place a rotation transform at the root of a graph, then all the primitives will be rotated around a common point.

If you want to zoom in, scroll, or rotate a UI, or just pieces of the UI, you can do that very easily by applying transforms.

In the example below, the first text line is translated, and the second is scaled bigger, and the whole graph rotated 0.4 radians.

    @graph Graph.build(font: :roboto, font_size: 24, rotate: 0.4)
      |> text("Hello World", translate: {300, 300})
      |> text("Bigger Hello", font_size: 40, scale: 1.5)


## Modifying a graph

Scenic was written specifically for Erlang/Elixir, which is a functional programming model with immutable data.

As such, once you make a graph, it stays in memory unchanged - until you change it via `Graph.modify/3`. Technically you never change it (that's the immutable part), instead Graph.modify returns a new graph with different data in it.

[Graph.modify/3](Scenic.Graph.html#modify/3) is the single Graph function that you will use the most.

For example, lets go back to our graph with the two text items in it.

    @graph Graph.build(font: :roboto, font_size: 24, rotate: 0.4)
      |> text("Hello World", translate: {300, 300}, id: :small_text)
      |> text("Bigger Hello", font_size: 40, scale: 1.5, id: :big_text)

This time, we've assigned ids to both of the text primitives. This makes it easy to find and modify that primitive in the graph.

    graph =
      @graph
      |> Graph.modify( :small_text, &text(&1, "Smaller Hello", font_size: 16))
      |> Graph.modify( :big_text, &text(&1, "Bigger Hello", font_size: 60))
      |> push_graph()

Notice that the graph is modified multiple times in the pipeline. The `push_graph/1` function is relatively heavy when the graph references other scenes. The recommended pattern is to make multiple changes to the graph and then push once at the end.


## What to read next?

If you are exploring Scenic, then you should read the [Primitives Overview](overview_primitives.html) next.