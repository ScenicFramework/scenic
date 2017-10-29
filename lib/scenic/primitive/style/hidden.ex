#
#  Created by Boyd Multerer on 5/11/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Style.Hidden do
  use Scenic.Primitive.Style, type_code: 0x0010
#  alias Scenic.Primitive.Style

#  @dflag            Style.dflag()
#  @type_code        0x0010



  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Style :hidden can only be true or false"

  #--------------------------------------------------------
  def verify( true ),     do: true
  def verify( false ),    do: true
  def verify( _ ),        do: false

  #--------------------------------------------------------
  def serialize( data, order \\ :native )
  def serialize( true, _ ),  do: <<1>>
  def serialize( false, _ ), do: <<0>>

  #--------------------------------------------------------
  def deserialize( binary_data, order \\ :native )
  def deserialize( <<1, bin :: binary>>, _ ), do: {:ok, true, bin}
  def deserialize( <<0, bin :: binary>>, _ ), do: {:ok, false, bin}

end