#
#  Created by Boyd Multerer on 2017-05-06.
#  Copyright © 2017-2021 Kry10 Limited. All rights reserved.
#

defmodule Scenic.Primitive.Style do
  @moduledoc """
  Modify the look of a primitive by applying a Style.

  Styles are optional modifiers that you can put on any primitive. Each style does a
  specific thing and some only affect certain primitives.

  ```elixir
  Graph.build()
    |> rect( {100, 50}, fill: blue, stroke: {2, :yellow} )
  ```

  The above example draws a rectangle, that is filled with blue and outlined in yellow.
  The primitive is `Scenic.Primitive.Rectangle` and the styles are `:fill` and `:stroke`.


  ### Inheritance
  Styles are inherited by primitives that are placed in a group. This allows you to set
  styles that will be used by many primitives. Those primitives can override the style
  set on the group by setting it again.

  Example:

  ```elixir
  Graph.build( font: :roboto, font_size: 24 )
    |> text( "Some text drawn using roboto" )
    |> text( "Text using roboto_mono", font: :roboto_mono )
    |> text( "back to drawing in roboto" )
  ```

  In the above example, the text primitives inherit the fonts set on the root group
  when the Graph is created. The middle text primitive overrides the `:font` style,
  but keeps using the `:font_size` set on the group.

  ### Components

  In general, styles are NOT inherited across a component boundary unless they are
  explicitly set on the component itself. This allows components to manage their own
  consistent look and feel.

  The exception to this rule is the `:theme` style. This IS inherited across groups
  and into components. This allows you to set an overall color scheme such as
  `:light` or `:dark` that makes sense with the components.
  """

  alias Scenic.Primitive.Style

  # import IEx

  @type t :: %{atom => any}

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

  @doc false
  def opts_map(), do: @opts_map

  @doc false
  def opts_schema(), do: @opts_schema

  # ===========================================================================
  # defmodule FormatError do
  #   defexception message: nil, module: nil, data: nil
  # end

  # ===========================================================================
  #  defmacro __using__([type_code: type_code]) when is_integer(type_code) do
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive.Style
    end
  end
end
