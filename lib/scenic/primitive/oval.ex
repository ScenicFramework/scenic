#
#  Created by Boyd Multerer on 10/29/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Oval do
  use Scenic.Primitive

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :color, :border_color, :border_width]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Rectangle data must be a point, width and height. Like this: {{x0,y0}, width, height}"

  #--------------------------------------------------------
  def verify( {center, radius} ), do:
    verify( {center, radius, 1.0, 1.0} )
  def verify( {{x, y}, radius, x_factor, y_factor} ) when
    is_number(x) and is_number(y) and is_number(radius) and
    is_number(x_factor) and is_number(y_factor), do: true
  def verify( _ ), do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( {center, radius}, order ), do:
    serialize( {center, radius, 1.0, 1.0}, order )
  def serialize( {{x, y}, radius, x_factor, y_factor}, :native ) do
    { :ok,
      <<
        x         :: integer-size(16)-native,
        y         :: integer-size(16)-native,
        radius    :: integer-size(16)-native,
        x_factor  :: integer-size(16)-native,
        y_factor  :: integer-size(16)-native,
      >>
    }
  end
  def serialize( {{x, y}, radius, x_factor, y_factor}, :big ) do
    { :ok,
      <<
        x         :: integer-size(16)-big,
        y         :: integer-size(16)-big,
        radius    :: integer-size(16)-big,
        x_factor  :: integer-size(16)-big,
        y_factor  :: integer-size(16)-big,
      >>
    }
  end

  #--------------------------------------------------------
  def deserialize( binary_data, order \\ :native )
  def deserialize( <<
      x         :: integer-size(16)-native,
      y         :: integer-size(16)-native,
      radius    :: integer-size(16)-native,
      x_factor  :: integer-size(16)-native,
      y_factor  :: integer-size(16)-native,
      bin       :: binary
    >>, :native ) do
    {:ok, {{x, y}, radius, x_factor, y_factor}, bin}
  end
  def deserialize( <<
      x         :: integer-size(16)-big,
      y         :: integer-size(16)-big,
      radius    :: integer-size(16)-big,
      x_factor  :: integer-size(16)-big,
      y_factor  :: integer-size(16)-big,
      bin       :: binary
    >>, :big ) do
    {:ok, {{x, y}, radius, x_factor, y_factor}, bin}
  end
  def deserialize( binary_data, order ), do: {:err_invalid, binary_data, order }


  #============================================================================
  def valid_styles(), do: @styles


  #--------------------------------------------------------
  def default_pin({{x, y},_,_,_}), do: {x,y}

  #--------------------------------------------------------
  def expand( { {x,y}, r }, width ) do
    {{x,y}, r + width}
  end
  def expand( { {x,y}, r, xf, yf }, width ) do
    {{x,y}, r + width, xf, yf}
  end

end