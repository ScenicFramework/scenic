#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Text do
  use Scenic.Primitive

#  alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :font_family, :font_size, :font_style, :color]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Text data must be a point and a bitstring. Like this: {{x,y}, a_string}"

  #--------------------------------------------------------
  def verify( {{x, y}, text} ) when
    is_number(x) and is_number(y) and is_bitstring(text), do: true
  def verify( _ ), do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {{x0, y0}, text}, :native ) do
    { :ok,
      <<
        x0              :: integer-size(16)-native,
        y0              :: integer-size(16)-native,
        byte_size(text) :: unsigned-integer-native-size( 16 ),
        text            :: bitstring
      >>
    }
  end
  def serialize( {{x0, y0}, text}, :big ) do
    { :ok,
      <<
        x0              :: integer-size(16)-big,
        y0              :: integer-size(16)-big,
        byte_size(text) :: unsigned-integer-big-size( 16 ),
        text            :: bitstring
      >>
    }
  end

  #--------------------------------------------------------
  def deserialize( binary_data, order \\ :native )
  def deserialize( <<
      x0          :: integer-size(16)-native,
      y0          :: integer-size(16)-native,
      num_bytes   :: unsigned-integer-native-size( 16 ),
      bin         :: binary
    >>, :native ) do
    << text :: binary-size(num_bytes), bin :: binary >> = bin
    {:ok, {{x0, y0}, text}, bin}
  end
  def deserialize( <<
      x0          :: integer-size(16)-big,
      y0          :: integer-size(16)-big,
      num_bytes   :: unsigned-integer-big-size( 16 ),
      bin         :: binary
    >>, :big ) do
    << text :: binary-size(num_bytes), bin :: binary >> = bin
    {:ok, {{x0, y0}, text}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }




  #============================================================================
  def valid_styles(), do: @styles


  #--------------------------------------------------------
  def default_pin( data )
  def default_pin( {{x, y}, _} ) do
    {x, y}
  end

end