#
#  Created by Boyd Multerer 2018-04-30.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

# convenience functions for adding basic primitives to a graph.
# this module should be updated as new primitives are added

defmodule Scenic.Primitives do
  alias Scenic.Primitive
  alias Scenic.Graph
  alias Scenic.Math

  # import IEx

  @moduledoc """
  A set of helper functions to make it easy to add to, or modify,
  a graph.

  In general, each helper function is of the form
      def name_of_primitive( graph, data, opts \\\\ [] )

  When adding primitives to a graph, each helper function accepts a
  graph as the first parameter and returns the transformed graph. This
  makes is very easy to build a complex graph by piping helper functions
  together.

      @graph Graph.build()
      |> text( "Hello World" )
      |> rectangle( {100, 200} )
      |> line( {{10,20}, {100, 20}})


  When modifying a graph, you can again use the helpers by passing
  in the primitive to be modified. The transformed primitive will
  be returned.

      Graph.modify(graph, :rect, fn(p) ->
        rectangle(p, {200, 300})
      end)

      # or, more compactly...

      Graph.modify(graph, :rect, &rectangle(&1, {200, 300}) )

  In each case, the second parameter is a data term that is specific
  to the primitive being acted on. See the documentation below. If you
  pass in invalid data for the second parameter an error will be
  thrown along with some explanation of what it expected.

  The third parameter is a keyword list of options that are to be
  applied to the primitive. This includes setting the id, styles,
  transforms and such.

      @graph Graph.build()
      |> text( "Hello World", id: :hello, font_size: 24, rotate: 0.4 )
      |> rectangle( {100, 200}, translate: {10, 30}, fill: :yellow)
      |> line( {{10,20}, {100, 20}}, id: :a_line, stroke: {4, :green})

  ### Style options

  Style options affect the way primitives are drawn. They include options such
  as :fill, :stroke, :font and many more. See the Styles documentation
  for the full list. Style options are inherited down the graph. In other words,
  if you set a style on the root of the graph like this:
  Graph.build( font_size: 24, then all text items in all groups will be
  rendered with a point size of 24 unless they set a different size.

  Not every primitive accepts every style. For example, it doesn't make much
  sense to apply a font to a rectangle. If you try, the rectangle will ignore
  that value. See the documentation for each primitive for a list of what styles
  they pay attention to.

  Transforms that are applied to a Group are inherited by all primitives in
  that group's branch of the tree. Note that style inheritance does not
  cross SceneRef boundaries.

  ### Transform options

  Transform options affect the size, position and rotation of elements in the
  graph. Any transform you can express as a 4x4 matrix of floats, you can apply
  to any primitive in the graph, including groups and scene_refs.

  Transform options are applied on the element they are specified on. If
  you specify a transform on a group, then it is applied to everything
  rendered in that branch of the graph tree.

  This is done mathematically as a "stack" of transforms. As the renderer
  traverses up and down the graph, transforms are pushed and popped from the
  matrix stack as appropriate. Transform inheritance does cross SceneRef
  boundaries.

  ## Draw Order

  Primitives will be drawn in the order you add them to the graph.
  For example, the graph below draws text on top of a filled rectangle. If the order
  of the text and rectangle were reversed, they would both still be rendered, but
  the text would not be visible because the rectangle would cover it up.

      @graph Graph.build( font: {:roboto, 20} )
      |> rect( {100, 200}, color: :blue )
      |> text( "Hello World", id: :hello, translate: {10, 10} )

  ## SceneRef primitives

  The scene_ref/3 helper creates/modifies a SceneRef primitive. This is
  the other special case primitive. Instead of drawing anything directly
  it says something like, "render the graph from another scene here".

  The SceneRef allows you to compose together components made of other
  pre-made scenes, or independently supervised scenes, into a single image.

  The SceneRef follows the same style/transform inheritance as the Group.
  """

  # --------------------------------------------------------
  @doc """
  Add an arc to a graph

  An arc is the outer edge of a part of a circle or ellipse. It
  is the sort of thing you would use a compass to draw on a piece
  of paper. It has a radius, a start angle and an ending angle. The
  angles are specified in radians.

  Data:

      {radius, start, finish}

  If you want something that looks like a piece of pie (maybe for a
  pie chart??), then you want a Sector, not an Arc.

  To create an arc of an ellipse, create a normal arc, and apply
  a `:scale` transform with unequal x and y sizing.

  The following example will draw a simple arc with a radius of 100,
  starting straight out to the right, then going down 0.4 radians.

      graph
      |> arc( {100, 0, 0.4} )

  ### Styles

  Arcs honor the following styles

  * `:hidden` - If true the primitive is rendered. If false, it is skipped. The default
    is true.
  * `:fill` - Fills in the interior with the specified paint. If not set, the
    default is to not draw anything in the interior. This is similar to specifying
    fill: :clear, except optimized out to do nothing.
  * `:stroke` - Draws the outline with the specified width and paint. The default
    if not set is `{1, :white}`

  Example:

      graph
      |> arc( {100, 0, 0.4}, stroke: {4, :blue} )

  """
  @spec arc(
          source :: Graph.t() | Primitive.t(),
          arc :: {radius :: number, start :: number, finish :: number},
          options :: list
        ) :: Graph.t() | Primitive.t()

  def arc(graph_or_primitive, arc, opts \\ [])

  def arc(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.Arc, data, opts)
  end

  def arc(%Primitive{module: Primitive.Arc} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Add a Circle to a graph

  Circles are defined by a radius
  Data:

      100

  The following example will draw circle.

      graph
      |> circle( 100 )

  ### Styles

  Circles honor the following styles

  * `:hidden` - If true the primitive is rendered. If false, it is skipped. The default
    is to render the primitive if hidden is not set.
  * `:fill` - Fills in the interior with the specified paint. If not set, the
    default is to not draw anything in the interior. This is similar to specifying
    fill: :clear, except optimized out to do nothing.
  * `:stroke` - The width and paint to draw the outline with. If the stroke is not
    specified then the default stroke is `{1, :white}`

  Example:

      graph
      |> circle( 40, fill: :red, stroke: {3, :blue}, translate: {100, 200} )

  While you could apply a `:rotate` transform to a circle, it wouldn't do
  anything visible unless you also add a uneven `:scale` transform to make it
  into an ellipse.

  """
  @spec circle(
          source :: Graph.t() | Primitive.t(),
          radius :: number,
          options :: list
        ) :: Graph.t() | Primitive.t()

  def circle(graph_or_primitive, radius, opts \\ [])

  def circle(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.Circle, data, opts)
  end

  def circle(%Primitive{module: Primitive.Circle} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Add an Ellipse to a graph

  Ellipses are defined by two radii.

  Data:

      {100, 140}

  The following example will draw an ellipse.

      graph
      |> ellipse( {100, 140} )

  If you want the ellipse to be on an angle, apply a `:rotate` transform.

  ### Styles

  Ellipses honor the following styles

  * `:hidden` - If true the outline is rendered. If false, it is skipped. The default
    is to render the primitive if hidden is not set.
  * `:fill` - Fills in the interior with the specified paint. If not set, the
    default is to not draw anything in the interior. This is similar to specifying
    fill: :clear, except optimized out to do nothing.
  * `:stroke` - The width and paint to draw the outline with. If the stroke is not
    specified then the default stroke is `{1, :white}`

  Example:

      graph
      |> ellipse( {40, 60}, fill: :red, stroke: {3, :blue}, rotate: 0.4 )

  """
  @spec ellipse(
          source :: Graph.t() | Primitive.t(),
          radii :: Math.vector_2(),
          options :: list
        ) :: Graph.t() | Primitive.t()

  def ellipse(graph_or_primitive, radii, opts \\ [])

  def ellipse(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.Ellipse, data, opts)
  end

  def ellipse(%Primitive{module: Primitive.Ellipse} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Create a new branch in a Graph

  The Group primitive creates a new branch in the Graph's tree. The data field
  you pass in is a function callback, which allows you to add more
  primitives inside the new group.

  The single parameter to your anonymous callback is a transformed graph that
  knows to add new primitives to the right branch in the tree.

      @graph Graph.build( )
      |> text( "Hello World" )
      |> group(fn(g) ->
        g
        |> text( "Im in the Group" )
      end, translate: {40,200})

  ### Styles

  Groups will accept all styles. They don't use the styles directly, but
  any styles you set on a group become the new defaults for all primitives
  you add to that group's branch in the graph. Note: styles are not
  inherited across scene_refs. (see below)

  The `:hidden` is particularly effective when applied to a group as it
  causes that entire branch to be drawn, or not.

  ### Transforms

  Any transforms you apply to a group are added into the render matrix stack and
  are applied to all items in that branch, including crossing scene_refs.
  """
  @spec group(
          source :: Graph.t(),
          builder :: function(),
          options :: list
        ) :: Graph.t()

  def group(graph_or_primitive, builder, opts \\ [])

  def group(%Graph{} = graph, builder, opts) when is_function(builder, 1) do
    Primitive.Group.add_to_graph(graph, builder, opts)
  end

  # --------------------------------------------------------
  @doc """
  Add a line to a graph

  Lines are pretty simple. They start at one point and go to another.

  Data:

      { {from_x, from_y}, {to_x,to_y} }

  The following example will draw a diagonal line from the upper left
  corner `{0,0}` to the point `{100,200}`, which is down and to the right.

      graph
      |> line( {{0,0}, {100,200}} )

  ### Styles

  Lines honor the following styles

  * `:hidden` - If true the line is rendered. If false, it is skipped. The default
    is to render the primitive if hidden is not set.
  * `:stroke` - The width and paint to draw the line with. If the stroke is not
    specified then the default stroke is `{1, :white}`
  * `:cap` - Specifies the shape of the ends of the line. Can be one of `:round`,
    `:butt`, or `:square`. If cap is not specified, then the default is `:butt`

  Example:

      graph
      |> line( {{0,0}, {100,200}}, stroke: {4, :blue}, cap: :round )

  """
  @spec line(
          source :: Graph.t() | Primitive.t(),
          line :: Math.line(),
          options :: list
        ) :: Graph.t() | Primitive.t()

  def line(graph_or_primitive, line, opts \\ [])

  def line(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.Line, data, opts)
  end

  def line(%Primitive{module: Primitive.Line} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Add custom, complex shape to a graph

  A custom path is defined by a list of actions that the renderer
  can follow. This is about as close as Scenic gets to immediate
  mode rendering.

  See the Path primitive for details.

      graph
      |> path( [
          :begin,
          {:move_to, 10, 20},
          {:line_to, 30, 40},
          {:bezier_to, 10, 11, 20, 21, 30, 40},
          {:quadratic_to, 10, 11, 50, 60},
          {:arc_to, 70, 80, 90, 100, 20},
          :close_path,
        ],
        stroke: {4, :blue}, cap: :round
      )

  """
  @spec path(
          source :: Graph.t() | Primitive.t(),
          elements :: list,
          options :: list
        ) :: Graph.t() | Primitive.t()

  def path(graph_or_primitive, elements, opts \\ [])

  def path(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.Path, data, opts)
  end

  def path(%Primitive{module: Primitive.Path} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Add a Quadrilateral (quad) to a graph

  Quads are defined by four points on the screen.

  Data:

      { {x0,y0}, {x1,y1}, {x2,y2}, {x3,y3} }

  The following example will draw a quad.

      graph
      |> quad( {{10,20}, {100,20}, {90, 120}, {15, 70}} )

  ### Styles

  Quads honor the following styles

  * `:hidden` - If true the primitive is rendered. If false, it is skipped. The default
    is to render the primitive if hidden is not set.
  * `:fill` - Fills in the interior with the specified paint. If not set, the
    default is to not draw anything in the interior. This is similar to specifying
    fill: :clear, except optimized out to do nothing.
  * `:stroke` - The width and paint to draw the outline with. If the stroke is not
    specified then the default stroke is `{1, :white}`
  * `:join` - Specifies how the lines are joined together where they meet. Can be
    one of `:miter`, `:round`, or `:bevel`. If join is not specified, then
    the default is `:miter`
  * `:miter_limit` - Apply an optional miter limit to the joints. If the angle
    is very shallow, the pointy bit might extend out far beyond the joint.
    Specifying `:miter_limit` puts a limit on the joint and bevels it if
    it goes out too far.


  Example:

      graph
      |> quad( {{10,20}, {100,20}, {90, 120}, {15, 70}},
        fill, :red, stroke: {3, :blue}, join: :round )

  """
  @spec quad(
          source :: Graph.t() | Primitive.t(),
          quad :: Math.quad(),
          options :: list
        ) :: Graph.t() | Primitive.t()

  def quad(graph_or_primitive, quad, opts \\ [])

  def quad(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.Quad, data, opts)
  end

  def quad(%Primitive{module: Primitive.Quad} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Shortcut to the `rectangle/3` function.

  `rect/3` is the same as calling `rectangle/3`
  """
  @spec rect(
          source :: Graph.t() | Primitive.t(),
          rect :: {width :: number, height :: number},
          options :: list
        ) :: Graph.t() | Primitive.t()

  def rect(graph_or_primitive, rect, opts \\ []) do
    rectangle(graph_or_primitive, rect, opts)
  end

  @doc """
  Add a rectangle to a graph

  Rectangles are defined by a width and height.

  Data:

      { width, height }

  The following example will draw a rectangle.

      graph
      |> rectangle( {100, 200} )

  ### Styles

  Rectangles honor the following styles

  * `:hidden` - If true the primitive is rendered. If false, it is skipped. The default
    is to render the primitive if hidden is not set.
  * `:fill` - Fills in the interior with the specified paint. If not set, the
    default is to not draw anything in the interior. This is similar to specifying
    fill: :clear, except optimized out to do nothing.
  * `:stroke` - The width and paint to draw the outline with. If the stroke is not
    specified then the default stroke is `{1, :white}`
  * `:join` - Specifies how the lines are joined together where they meet. Can be
    one of `:miter`, `:round`, or `:bevel`. If join is not specified, then
    the default is `:miter`
  * `:miter_limit` - Apply an optional miter limit to the joints. If the angle
    is very shallow, the pointy bit might extend out far beyond the joint.
    Specifying `:miter_limit` puts a limit on the joint and bevels it if
    it goes out too far.


  Example:

      graph
      |> rectangle( {100, 200},
        fill, :red, stroke: {3, :blue}, join: :round )

  """
  @spec rectangle(
          source :: Graph.t() | Primitive.t(),
          rectangle :: {width :: number, height :: number},
          options :: list
        ) :: Graph.t() | Primitive.t()

  def rectangle(graph_or_primitive, rectangle, opts \\ [])

  def rectangle(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.Rectangle, data, opts)
  end

  def rectangle(%Primitive{module: Primitive.Rectangle} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Shortcut to the `rounded_rectangle/3` function.

  `rrect/3` is the same as calling `rounded_rectangle/3`
  """
  @spec rrect(
          source :: Graph.t() | Primitive.t(),
          rrect :: {width :: number, height :: number, radius :: number},
          options :: list
        ) :: Graph.t() | Primitive.t()

  def rrect(graph_or_primitive, rrect, opts \\ []) do
    rounded_rectangle(graph_or_primitive, rrect, opts)
  end

  @doc """
  Add a rounded rectangle to a graph

  Rounded rectangles are defined by a width, height, and radius.

  Data:

      { width, height, radius }

  The following example will draw a rounded rectangle.

      graph
      |> rounded_rectangle( {100, 200, 8} )

  ### Styles

  Rounded rectangles honor the following styles

  * `:hidden` - If true the primitive is rendered. If false, it is skipped. The default
    is to render the primitive if hidden is not set.
  * `:fill` - Fills in the interior with the specified paint. If not set, the
    default is to not draw anything in the interior. This is similar to specifying
    fill: :clear, except optimized out to do nothing.
  * `:stroke` - The width and paint to draw the outline with. If the stroke is not
    specified then the default stroke is `{1, :white}`

  Example:

      graph
      |> rounded_rectangle( {100, 200, 8},
        fill, :red, stroke: {3, :blue} )

  """
  @spec rounded_rectangle(
          source :: Graph.t() | Primitive.t(),
          rounded_rectangle :: {width :: number, height :: number, radius :: number},
          options :: list
        ) :: Graph.t() | Primitive.t()

  def rounded_rectangle(graph_or_primitive, rounded_rectangle, opts \\ [])

  def rounded_rectangle(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.RoundedRectangle, data, opts)
  end

  def rounded_rectangle(%Primitive{module: Primitive.RoundedRectangle} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Reference another scene or graph from within a graph.

  The SceneRef allows you to next other graphs inside a graph. This means
  you can build smaller components that you can compose into a larger image.

  *Typically you do not specify SceneRefs yourself.* These get added
  for you when you add components to you graph. Examples: Buttons,
  Sliders, checkboxes, etc.

  Usually, the graph you reference is controlled by another scene, but
  it doesn't have to be. A single scene could create multiple graphs
  and reference them into each other.

  **See the SceneRef primitive for details.**

  Be careful not to create circular references. That won't work well.

  ### Styles

  The only style that has any meaning on a SceneRef is `:hidden`. The
  rest are ignored and are not inherited across to the referenced scene.

  ### Transforms

  Any transforms you apply to a group are added into the render matrix stack and
  are applied to all items in that branch, including crossing scene_refs.
  """
  @spec scene_ref(
          source :: Graph.t() | Primitive.t(),
          ref ::
            {:graph, reference, any}
            | {module :: atom, init_data :: any}
            | (scene_name :: atom),
          options :: list
        ) :: Graph.t() | Primitive.t()

  def scene_ref(graph_or_primitive, ref, opts \\ [])

  def scene_ref(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.SceneRef, data, opts)
  end

  def scene_ref(%Primitive{module: Primitive.SceneRef} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Add a sector to a graph

  A sector looks like a piece of pie. It is wedge shaped with a pointy
  bit on one side and a rounded bit on the other. It has a radius, a
  start angle and an ending angle. The angles are specified in radians.

  Data:

      {radius, start, finish}

  To create a sector of an ellipse, create a normal sector, and apply
  a `:scale` transform with unequal x and y sizing.

  The following example will draw a sector with a radius of 100,
  starting straight out to the right, then going down 0.4 radians.

      |> sector( {100, 0, 0.4} )

  ### Styles

  Sectors honor the following styles

  * `:hidden` - If true the outline is rendered. If false, it is skipped. The default
    is true.
  * `:fill` - Fills in the interior with the specified paint. If not set, the
    default is to not draw anything in the interior. This is similar to specifying
    fill: :clear, except optimized out to do nothing.
  * `:stroke` - Draws the outline with the specified width and paint. The default
    if not set is `{1, :white}`

  When you apply a stroke to a sector, it goes around the whole piece
  of pie. If you only want to stroke the curvy part, which is common
  in pie charts, overlay an Arc on top of the sector and stroke that.

  If you also put both the sector and the arc together in a Group, you can
  then apply transforms to the group to position both the primitives as a single
  unit.

  Example:

      graph
      |> group(fn(g) ->
        g
        |> sector( {100, 0, 0.4}, fill: :red )
        |> arc( {100, 0, 0.4}, stroke: {4, :blue} )
      end, translate: {30, 40})

  """
  @spec sector(
          source :: Graph.t() | Primitive.t(),
          sector :: {radius :: number, start :: number, finish :: number},
          options :: list
        ) :: Graph.t() | Primitive.t()

  def sector(graph_or_primitive, sector, opts \\ [])

  def sector(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.Sector, data, opts)
  end

  def sector(%Primitive{module: Primitive.Sector} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Adds text to a graph

  Text pretty simple. Specify the string you would like drawn.

  Data:

      "Draw this string on the screen"

  The following example will draw some text on the screen.

      graph
      |> text( "Hello World", translate: {20, 20} )

  ### Styles

  Text honors the following styles

  * `:hidden` - If true the primitive is rendered. If false, it is skipped.
    The default is to render the primitive if hidden is not set.
  * `:fill` - The paint to color the text with. If not specified, the default
    is :white. Note: Text can only be filled with solid colors at this time.
  * `:font` - Specifies font family to draw the text with. The built-in system
    fonts are `:roboto`, `:roboto_mono`, and `:roboto_slab`. If not specified, the
    default is `:roboto`. You can also load your own font into the Scenic.Cache,
    then specify its key for the font.
  * `:font_blur` - Draw the text with a blur effect. If you draw text with blur,
    then draw it again without blur, slightly offset, you get a nice drop shadow
    effect. The default is to draw with no blur.
  * `:text_align` - Specify the alignment of the text you are drawing. You will
    usually specify one of: :left, :center, or :right. You can also specify
    vertical alignment. See the TextAlign docs for details.
  * `:text_height` - Specify the vertical spacing between rows of text.


  Example:

      graph
      |> text( "Hello World", fill: :yellow, font: :roboto_mono
        flont_blur: 2.0, text_align: :center )

  """
  @spec text(
          source :: Graph.t() | Primitive.t(),
          text :: String.t(),
          options :: list
        ) :: Graph.t() | Primitive.t()

  def text(graph_or_primitive, text, opts \\ [])

  def text(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.Text, data, opts)
  end

  def text(%Primitive{module: Primitive.Text} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Add a Triangle to a graph

  Triangles are defined by three points on the screen.

  Data:

      { {x0,y0}, {x1,y1}, {x2,y2} }

  The following example will draw a triangle.

      graph
      |> triangle( {{10,20}, {100,20}, {50, 120}} )

  ### Styles

  Triangles honor the following styles

  * `:hidden` - If true the primitive is rendered. If false, it is skipped. The default
    is to render the primitive if hidden is not set.
  * `:fill` - Fills in the interior with the specified paint. If not set, the
    default is to not draw anything in the interior. This is similar to specifying
    fill: :clear, except optimized out to do nothing.
  * `:stroke` - The width and paint to draw the outline with. If the stroke is not
    specified then the default stroke is `{1, :white}`
  * `:join` - Specifies how the lines are joined together where they meet. Can be
    one of `:miter`, `:round`, or `:bevel`. If join is not specified, then
    the default is `:miter`
  * `:miter_limit` - Apply an optional miter limit to the joints. If the angle
    is very shallow, the pointy bit might extend out far beyond the joint.
    Specifying `:miter_limit` puts a limit on the joint and bevels it if
    it goes out too far.


  Example:

      graph
      |> triangle( {{10,20}, {100,20}, {50, 120}}, fill: :red,
        stroke: {3, :blue}, join: :round )

  """
  @spec triangle(
          source :: Graph.t() | Primitive.t(),
          triangle :: Math.triangle(),
          options :: list
        ) :: Graph.t() | Primitive.t()

  def triangle(graph_or_primitive, triangle, opts \\ [])

  def triangle(%Graph{} = g, data, opts) do
    add_to_graph(g, Primitive.Triangle, data, opts)
  end

  def triangle(%Primitive{module: Primitive.Triangle} = p, data, opts) do
    modify(p, data, opts)
  end

  # --------------------------------------------------------
  @doc """
  Update the options of a primitive without changing its data.

  This is not used during graph creation. Only when modifying it later.

  All the primitive-specific helpers require you to specify the
  data for the primitive. If you only want to modify a transform
  or add a style, then use update_opts.

  Example:

      Graph.modify(graph, :rect, fn(p) ->
        update_opts(p, rotate: 0.5)
      end)

      # or, more compactly...

      Graph.modify(graph, :rect, &update_opts(&1, rotate: 0.5) )

  """
  @spec update_opts(
          Primitive.t(),
          options :: list
        ) :: Primitive.t()

  def update_opts(p, opts), do: Primitive.merge_opts(p, opts)

  # ============================================================================
  # generic workhorse versions

  defp add_to_graph(%Graph{} = g, mod, data, opts) do
    mod.verify!(data)
    mod.add_to_graph(g, data, opts)
  end

  defp modify(%Primitive{module: mod} = p, data, opts) do
    mod.verify!(data)
    Primitive.put(p, data, opts)
  end
end
