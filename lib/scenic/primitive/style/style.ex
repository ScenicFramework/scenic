#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
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
  * [`MiterLimit`](Scenic.Primitive.Style.MiterLimit.html) sets whether or not to miter a joint if the intersection of two lines is very sharp.
  * [`Scissor`](Scenic.Primitive.Style.Scissor.html) defines a rectangle that drawing will be clipped to.
  * [`Stroke`](Scenic.Primitive.Style.Stroke.html) defines how to draw the edge of a primitive. Specifies both a width and a [paint style](overview_styles.html#primitive-paint-styles).
  * [`TextAlign`](Scenic.Primitive.Style.TextAlign.html) sets the alignment of text relative to the starting point. Examples: :left, :center, or :right
  * [`Theme`](Scenic.Primitive.Style.Theme.html) a collection of default colors. Usually passed to components, telling them how to draw in your preferred color scheme.

  ## Primitive Paint Styles

  The `Fill` and `Stroke` styles accept a paint type. This describes what to fill or stroke the the primitive with.

  There is a fixed set of paint types that the drivers know how to render.

  * [`BoxGradient`](Scenic.Primitive.Style.Paint.BoxGradient.html) fills a primitive with a box gradient.
  * [`Color`](Scenic.Primitive.Style.Paint.Color.html) fills a primitive with a solid color. 
  * [`Image`](Scenic.Primitive.Style.Paint.Image.html) fills a primitive with an image that is loaded into `Scenic.Cache`.
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

  @style_name_map %{
    :hidden => Style.Hidden,
    :clear_color => Style.ClearColor,
    :texture_wrap => Style.TextureWrap,
    :texture_filter => Style.TextureFilter,
    :fill => Style.Fill,
    :stroke => Style.Stroke,
    :join => Style.Join,
    :cap => Style.Cap,
    :miter_limit => Style.MiterLimit,
    :font => Style.Font,
    :font_blur => Style.FontBlur,
    :font_size => Style.FontSize,
    :text_align => Style.TextAlign,
    :text_height => Style.TextHeight,
    :scissor => Style.Scissor,
    :theme => Style.Theme
  }

  @primitive_styles [
    :hidden,
    :clear_color,
    :texture_wrap,
    :texture_filter,
    :fill,
    :stroke,
    :join,
    :cap,
    :miter_limit,
    :font,
    :font_blur,
    :font_size,
    :text_align,
    :text_height,
    :scissor,
    :theme
  ]

  @callback info(data :: any) :: bitstring
  @callback verify(any) :: boolean

  # ===========================================================================
  defmodule FormatError do
    defexception message: nil, module: nil, data: nil
  end

  # ===========================================================================
  #  defmacro __using__([type_code: type_code]) when is_integer(type_code) do
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive.Style

      @doc false
      def verify!(data) do
        case verify(data) do
          true ->
            data

          false ->
            raise FormatError, message: info(data), module: __MODULE__, data: data
        end
      end

      @doc false
      def normalize(data), do: data

      # --------------------------------------------------------
      defoverridable normalize: 1
    end

    # quote
  end

  # defmacro

  # ===========================================================================
  @doc false
  def verify(style_key, style_data) do
    case Map.get(@style_name_map, style_key) do
      # don't verify non-primitives
      nil -> true
      module -> module.verify(style_data)
    end
  end

  # ===========================================================================
  @doc false
  def verify!(style_key, style_data) do
    case Map.get(@style_name_map, style_key) do
      nil -> style_data
      module -> module.verify!(style_data)
    end
  end

  # ===========================================================================
  # normalize the format of the style data
  @doc false
  def normalize(style_type, data)

  def normalize(style_type, data) do
    case Map.get(@style_name_map, style_type) do
      nil ->
        nil

      mod ->
        mod.verify!(data)
        mod.normalize(data)
    end
  end

  # ===========================================================================
  # transform a style map so only the primitive types remain
  @doc false
  def primitives(style_map)

  def primitives(style_map) do
    Enum.reduce(@primitive_styles, %{}, fn
      # only send direct font refs to the drivers
      :font, acc ->
        case Map.get(style_map, :font) do
          nil ->
            acc

          {type, hash} ->
            Map.put(acc, :font, {type, hash})

          fm_hash ->
            case Scenic.Cache.Static.FontMetrics.get(fm_hash) do
              %FontMetrics{source: %{font_type: type, signature: hash}} ->
                Map.put(acc, :font, {type, hash})

              _ ->
                acc
            end
        end

      k, acc ->
        case Map.get(style_map, k) do
          nil -> acc
          v -> Map.put(acc, k, normalize(k, v))
        end
    end)
  end
end
