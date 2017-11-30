#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

# the primitive style is not a primitive element in itself.
# this is a type of styling that is applied to other primitive elements

defmodule Scenic.Primitive.Style do
  alias Scenic.Primitive.Style

  import IEx

#  @dflag      2


  @style_name_map     %{
    :border_color =>                      Style.BorderColor,
    :border_width =>                      Style.BorderWidth,
    :color =>                             Style.Color,
    :hidden =>                            Style.Hidden,
    :line_width =>                        Style.LineWidth,
    :line_stipple =>                      Style.LineStipple,
    :clear_color =>                       Style.ClearColor,
  }

  @primitive_styles   [:hidden, :color, :border_color, :border_width, :line_width, :line_stipple, :clear_color, :font]


  @callback info() :: bitstring
  @callback verify( any ) :: boolean

  #===========================================================================
  defmodule FormatError do
    defexception [ message: nil, module: nil, data: nil ]
  end

  #===========================================================================
#  defmacro __using__([type_code: type_code]) when is_integer(type_code) do
  defmacro __using__(_opts) do
    quote do
      @behaviour Scenic.Primitive.Style

      #def type_code(), do: << unquote(type_code) :: unsigned-integer-size(16)-native>>

      def verify!( data ) do
        case verify(data) do
          true -> data
          false ->
            raise FormatError, message: info(), module: __MODULE__, data: data
        end
      end

      def normalize( data ), do: data

      #--------------------------------------------------------
      defoverridable [
        normalize:      1,
      ]
    end # quote
  end # defmacro


  # map a atom name to a style module. See @style_name_map above
#  def name_to_style( name ) when is_atom(name), do: @style_name_map[name]

#  #===========================================================================
  def verify( style_key, style_data ) do
    case Map.get(@style_name_map, style_key) do
      nil    -> true # don't verify non-primitives
      module -> module.verify( style_data )
    end
  end

  #===========================================================================
  def verify!( style_key, style_data ) do
    case Map.get(@style_name_map, style_key) do
      nil -> style_data
      module -> module.verify!( style_data )
    end
  end

  #===========================================================================
  # normalize the format of the style data
  def normalize(style_type, data)
  def normalize(style_type, data) do
    case Map.get(@style_name_map, style_type) do
      nil -> nil
      mod ->
        mod.verify!( data )
        mod.normalize( data )
    end
  end


  #===========================================================================
  # filter a style map so only the primitive types remain
  def primitives( style_map )
  def primitives( style_map ) do
    Enum.reduce(@primitive_styles, %{}, fn(k,acc) ->
      case Map.get(style_map, k) do
        nil ->  acc
        v   ->  Map.put(acc, k, normalize(k,v) )
      end
    end)
  end

end













