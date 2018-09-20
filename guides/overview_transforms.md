# Transforms Overview

Unlike html, which uses auto-layout to position items on the screen, Scenic moves primitives around using matrix transforms. This is common in video games and provides powerful control of your primitives.

A [matrix](https://en.wikipedia.org/wiki/Matrix_(mathematics)) is an array of numbers that can be used to change the positions, rotations, scale and more of locations.

**Don’t worry!** You will not need to look at any matrices unless you want to get fancy. In Scenic, you will rarely (if ever) create matrices on your own (you can if you know what you are doing!), and will instead use the transform helpers.

Multiple transforms can be applied to any primitive. Transforms combine down the graph to create a very flexible way to manage your scene.

There are a fixed set of transform helpers that create matrices for you.

* [`Matrix`](Scenic.Primitive.Transform.Matrix.html) hand specify a matrix.
* [`Pin`](Scenic.Primitive.Transform.Pin.html) set a pin to rotate or scale around. Most primitives define a sensible default pin.
* [`Rotate`](Scenic.Primitive.Transform.Rotate.html) rotate around the pin.
* [`Scale`](Scenic.Primitive.Transform.Scale.html) scale larger or smaller. Centered around the pin.
* [`Translate`](Scenic.Primitive.Transform.Translate.html) move/translate horizontally and veritcally.

### Specifying Transforms

You apply transforms to a primitive the same way you specify styles.

    graph =
      Graph.build
      |> circle( 100, fill: {:color, :green}, translate: {200, 200} )
      |> ellipse( {40, 60, fill: {:color, :red}, rotate: 0.4, translate: {100, 100} )

Don't worry about the order you apply transforms to a single object. Scenic will multiply them together in the correct way when it comes time to render them.

## What to read next?

If you are exploring Scenic, then you should read the [ViewPort Overview](overview_viewport.html) next.
