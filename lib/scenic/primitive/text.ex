#
#  Created by Boyd Multerer on 5/6/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Text do
  use Scenic.Primitive
  alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :fill, :font, :font_size, :font_blur, :text_align, :text_height]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Text data must be a point and a bitstring. Like this: {{x,y}, a_string}"

  #--------------------------------------------------------
  def verify( {{x, y}, text} = data ) when
    is_number(x) and is_number(y) and is_bitstring(text), do: {:ok, data}
  def verify( _ ), do: :invalid_data


  #============================================================================
  def valid_styles(), do: @styles


  #--------------------------------------------------------
  def default_pin( data )
  def default_pin( {{x, y}, _} ) do
    {x, y}
  end

  #============================================================================
  # override put

  # allow just a new string to be put, preserving the position
  def put( %Primitive{data: {pos,_}} = p, text ) when is_bitstring(text) do
    super(p,{pos,text})
  end
  def put(p,text), do: super(p,text)

end