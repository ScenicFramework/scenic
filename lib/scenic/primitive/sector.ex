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
  def verify( {center, start, finish, radius} ), do:
    verify( {center, start, finish, radius, {1.0,1.0}} )
  def verify( {{x, y}, start, finish, radius, {h,k}} = data ) when
    is_number(x) and is_number(y) and is_number(start) and
    is_number(finish) and is_number(radius) and
    is_number(h) and is_number(k), do: {:ok, data}
  def verify( _ ), do: :invalid_data

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {center, start, finish, radius}, order ), do:
    serialize( {center, start, finish, radius, {1.0,1.0}}, order )
  def serialize( {{x, y}, start, finish, radius, {h,k}}, :native ) do
    { :ok,
      <<
        x       :: integer-size(16)-native,
        y       :: integer-size(16)-native,
        start   :: integer-size(16)-native,
        finish  :: integer-size(16)-native,
        radius  :: integer-size(16)-native,
        h       :: integer-size(16)-native,
        k       :: integer-size(16)-native,
      >>
    }
  end
  def serialize( {{x, y}, start, finish, radius, {h,k}}, :big ) do
    { :ok,
      <<
        x       :: integer-size(16)-big,
        y       :: integer-size(16)-big,
        start   :: integer-size(16)-big,
        finish  :: integer-size(16)-big,
        radius  :: integer-size(16)-big,
        h       :: integer-size(16)-big,
        k       :: integer-size(16)-big,
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
      h       :: integer-size(16)-native,
      k       :: integer-size(16)-native,
      bin     :: binary
    >>, :native ) do
    {:ok, {{x, y}, start, finish, radius, {h,k}}, bin}
  end
  def deserialize( <<
      x       :: integer-size(16)-big,
      y       :: integer-size(16)-big,
      start   :: integer-size(16)-big,
      finish  :: integer-size(16)-big,
      radius  :: integer-size(16)-big,
      h       :: integer-size(16)-big,
      k       :: integer-size(16)-big,
      bin     :: binary
    >>, :big ) do
    {:ok, {{x, y}, start, finish, radius, {h,k}}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


  #============================================================================
  def valid_styles(), do: @styles


  #--------------------------------------------------------
  def default_pin({{x, y},_,_,_}),    do: {x,y}
  def default_pin({{x, y},_,_,_,_}),  do: {x,y}

  #--------------------------------------------------------
  def expand( { {x,y}, s, f, r }, width ) do
    {{x,y}, s, f, r + width}
  end
  def expand( { {x,y}, s, f, r, factor }, width ) do
    {{x,y}, s, f, r + width, factor}
  end

end