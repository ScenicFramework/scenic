#
#  Created by Boyd Multerer on 10/29/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Sector do
  use Scenic.Primitive

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :color, :border_color, :border_width]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Rectangle data must be a point, width and height. Like this: {{x0,y0}, width, height}"

  #--------------------------------------------------------
  def verify( {{x, y}, start, finish, radius} ) when
    is_number(x0) and is_number(y0) and
    is_number(start) and is_number(start) and is_number(radius), do: true
  def verify( _ ), do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {{x, y}, start, finish, radius}, :native ) do
    { :ok,
      <<
        x       :: integer-size(16)-native,
        y       :: integer-size(16)-native,
        start   :: integer-size(16)-native,
        finish  :: integer-size(16)-native,
        radius  :: integer-size(16)-native,
      >>
    }
  end
  def serialize( {{x, y}, start, finish, radius}, :big ) do
    { :ok,
      <<
        x       :: integer-size(16)-big,
        y       :: integer-size(16)-big,
        start   :: integer-size(16)-big,
        finish  :: integer-size(16)-big,
        radius  :: integer-size(16)-big,
      >>
    }
  end

  #--------------------------------------------------------
  def deserialize( binary_data, order \\ :native )
  def deserialize( <<
      x       :: integer-size(16)-native,
      y       :: integer-size(16)-native,
      start   :: integer-size(16)-native,
      finish  :: integer-size(16)-native,
      radius  :: integer-size(16)-native,
      bin     :: binary
    >>, :native ) do
    {:ok, {{x, y}, start, finish, radius}, bin}
  end
  def deserialize( <<
      x       :: integer-size(16)-big,
      y       :: integer-size(16)-big,
      start   :: integer-size(16)-big,
      finish  :: integer-size(16)-big,
      radius  :: integer-size(16)-big,
      bin     :: binary
    >>, :big ) do
    {:ok, {{x, y}, start, finish, radius}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


  #============================================================================
  def valid_styles(), do: @styles


  #--------------------------------------------------------
  def default_pin({{x, y},_,_,_}), do: {x,y}

  #--------------------------------------------------------
  def expand( { {x,y}, s, f, r }, width ) do
    {{x,y}, s, f, r + width}
  end

end