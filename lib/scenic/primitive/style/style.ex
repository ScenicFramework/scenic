#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style do
  @moduledoc """
  Modify the look of a primitive by applying a Style.

  Styles are optional modifiers that you can put on any primitive. Each style does a specific thing and some only affect certain primitives.

  There is a fixed list of primitive styles which are understood by the drivers. Some Components may introduce their own optional styles, but the only ones sent down to the drivers for rendering are contained in the list below.

  In general, the primitive styles are each defined in their own module, but you apply them as options in a primitive's option list.

  For example, to use the style defined in the module Scenic.Primitive.Style.Font you would define an option on a text primitive like this:

      graph =
        Graph.build
        |> text( "Styled Text", font: :roboto )

  ## Primitive Styles

  * [`Cap`](Scenic.Primitive.Style.Cap.html) sets how to draw the end of a line.
  * [`ClearColor`](Scenic.Primitive.Style.ClearColor.html) sets the background color. 
  * [`Fill`](Scenic.Primitive.Style.Fill.html) fills in a primitive with a [paint style](overview_styles.html#primitive-paint-styles).
  * [`Font`](Scenic.Primitive.Style.Font.html) sets the font to use to draw text.
  * [`FontBlur`](Scenic.Primitive.Style.FontBlur.html) applies a blur effect to text.
  * [`FontSize`](Scenic.Primitive.Style.FontSize.html) sets the point size text.
  * [`Hidden`](Scenic.Primitive.Style.Hidden.html) a flag that sets if a primitive is drawn at all.
  * [`Join`](Scenic.Primitive.Style.Join.html) sets how to render the intersection of two lines. Works on the intersections of other primitives as well.
  * [`LineHeight`](Scenic.Primitive.Style.LineHeight.html) sets the vertical spacing between lines of text
  * [`MiterLimit`](Scenic.Primitive.Style.MiterLimit.html) sets whether or not to miter a joint if the intersection of two lines is very sharp.
  * [`Scissor`](Scenic.Primitive.Style.Scissor.html) defines a rectangle that drawing will be clipped to.
  * [`Stroke`](Scenic.Primitive.Style.Stroke.html) defines how to draw the edge of a primitive. Specifies both a width and a [paint style](overview_styles.html#primitive-paint-styles).
  * [`TextAlign`](Scenic.Primitive.Style.TextAlign.html) sets the horizontal alignment of text. Examples: :left, :center, or :right
  * [`TextBase`](Scenic.Primitive.Style.TextAlign.html) sets the vertical alignment of text 
  * [`Theme`](Scenic.Primitive.Style.Theme.html) a collection of default colors. Usually passed to components, telling them how to draw in your preferred color scheme.

  ## Primitive Paint Styles

  The `Fill` and `Stroke` styles accept a paint type. This describes what to fill or stroke the the primitive with.

  There is a fixed set of paint types that the drivers know how to render.

  * [`Color`](Scenic.Primitive.Style.Paint.Color.html) fills a primitive with a solid color. 
  * [`Image`](Scenic.Primitive.Style.Paint.Image.html) fills a primitive with an image that is loaded into `Scenic.Assets.Static`.
  * [`Dynamic`](Scenic.Primitive.Style.Paint.Dynamic.html) fills a primitive with an texture that is loaded into `Scenic.Assets.Dynamic`.
  * [`LinearGradient`](Scenic.Primitive.Style.Paint.LinearGradient.html) fills a primitive with a linear gradient.
  * [`RadialGradient`](Scenic.Primitive.Style.Paint.RadialGradient.html) fills a primitive with a radial gradient.

  ### Specifying Paint

  When you use either the `Fill` and `Stroke` you specify the paint in a tuple like this.

      graph =
        Graph.build
        |> circle( 100, fill: {:color, :green}, stroke: {2, {:color, :blue}} )

  Each paint type has specific values it expects in order to draw. See the documentation for that paint type for details.

  ### Color Paint

  Specifying a solid color to paint is very common, so has a shortcut. If you simply set a valid color as the paint type, it is assumed that you mean `Color`.

      graph =
        Graph.build
        |> circle( 100, fill: :green, stroke: {2, :blue} )  # simple color
        |> rect( {100, 200}, fill: {:green, 128} )          # color with alpha
        |> rect( {100, 100}, fill: {10, 20, 30, 40} )       # red, green, blue, alpha
  """

  alias Scenic.Primitive.Style

  # import IEx

  @type m :: %{atom => any}

  @opts_map %{
    :input => Style.Input,
    :hidden => Style.Hidden,
    :texture_wrap => Style.TextureWrap,
    :texture_filter => Style.TextureFilter,
    :fill => Style.Fill,
    :stroke => Style.Stroke,
    :join => Style.Join,
    :cap => Style.Cap,
    :line_height => Style.LineHeight,
    :miter_limit => Style.MiterLimit,
    :font => Style.Font,
    :font_blur => Style.FontBlur,
    :font_size => Style.FontSize,
    :text_align => Style.TextAlign,
    :text_base => Style.TextBase,
    # :text_height => Style.TextHeight,
    :scissor => Style.Scissor,
    :theme => Style.Theme
  }

  @opts_schema [
    input: [type: {:custom, Style.Input, :validate, []}],
    hidden: [type: {:custom, Style.Hidden, :validate, []}],
    fill: [type: {:custom, Style.Fill, :validate, []}],
    stroke: [type: {:custom, Style.Stroke, :validate, []}],
    join: [type: {:custom, Style.Join, :validate, []}],
    cap: [type: {:custom, Style.Cap, :validate, []}],
    line_height: [type: {:custom, Style.LineHeight, :validate, []}],
    miter_limit: [type: {:custom, Style.MiterLimit, :validate, []}],
    font: [type: {:custom, Style.Font, :validate, []}],
    font_size: [type: {:custom, Style.FontSize, :validate, []}],
    text_align: [type: {:custom, Style.TextAlign, :validate, []}],
    text_base: [type: {:custom, Style.TextBase, :validate, []}],
    # text_height: [type: {:custom, Style.TextHeight, :validate, []}],
    scissor: [type: {:custom, Style.Scissor, :validate, []}],
    theme: [type: {:custom, Style.Theme, :validate, []}]
  ]

  @callback validate(data :: any) :: {:ok, data :: any} | {:error, String.t()}

  def opts_map(), do: @opts_map
  def opts_schema(), do: @opts_schema

  # ===========================================================================
  defmodule FormatError do
    defexception message: nil, module: nil, data: nil
  end

  # ===========================================================================
  #  defmacro __using__([type_code: type_code]) when is_integer(type_code) do
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive.Style
    end
  end
end
