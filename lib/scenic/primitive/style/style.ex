#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# the primitive style is not a primitive element in itself.
# this is a type of styling that is applied to other primitive elements

defmodule Scenic.Primitive.Style do
  alias Scenic.Primitive.Style

  #  import IEx

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

      def verify!(data) do
        case verify(data) do
          true ->
            data

          false ->
            raise FormatError, message: info(data), module: __MODULE__, data: data
        end
      end

      def normalize(data), do: data

      # --------------------------------------------------------
      defoverridable normalize: 1
    end

    # quote
  end

  # defmacro

  # ===========================================================================
  def verify(style_key, style_data) do
    case Map.get(@style_name_map, style_key) do
      # don't verify non-primitives
      nil -> true
      module -> module.verify(style_data)
    end
  end

  # ===========================================================================
  def verify!(style_key, style_data) do
    case Map.get(@style_name_map, style_key) do
      nil -> style_data
      module -> module.verify!(style_data)
    end
  end

  # ===========================================================================
  # normalize the format of the style data
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
  # filter a style map so only the primitive types remain
  def primitives(style_map)

  def primitives(style_map) do
    Enum.reduce(@primitive_styles, %{}, fn k, acc ->
      case Map.get(style_map, k) do
        nil -> acc
        v -> Map.put(acc, k, normalize(k, v))
      end
    end)
  end
end
