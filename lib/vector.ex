#
#  Created by Boyd Multerer on 7/2/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Math.Vector do
  alias Scenic.Math.Matrix

#  import IEx

  #--------------------------------------------------------
  def build( x, y ) when is_number(x) and is_number(y) do
    { x, y }
  end
  def build( x, y, z ) when is_number(x) and is_number(y)
      and is_number(z) do
    { x, y, z }
  end
  def build( x, y, z, w ) when is_number(x) and is_number(y)
      and is_number(z) and is_number(w) do
    { x, y, z, w }
  end


  #--------------------------------------------------------
  # truncate the values into ints
  def trunc( {x, y} ) do
    {Kernel.trunc(x), Kernel.trunc(y)}
  end
  def trunc( {x, y, z} ) do
    {Kernel.trunc(x), Kernel.trunc(y), Kernel.trunc(z)}
  end

  #--------------------------------------------------------
  # round the values into ints
  def round( {x, y} ) do
    {Kernel.round(x), Kernel.round(y)}
  end
  def round( {x, y, z} ) do
    {Kernel.round(x), Kernel.round(y), Kernel.round(z)}
  end

  #--------------------------------------------------------
  def invert( vector )
  def invert( {x,y} ),       do: {-x, -y}
  def invert( {x,y,z} ),     do: {-x, -y, -z}
  def invert( {x,y,z,w} ),   do: {-x, -y, -z, -w}

  #--------------------------------------------------------
  def length( vector ) do
    vector
    |> length_squared()
    |> :math.sqrt()
  end

  #--------------------------------------------------------
  def length_squared( vector )
  def length_squared( {x,y} ),      do: (x*x) + (y*y)
  def length_squared( {x,y,z} ),    do: (x*x) + (y*y) + (z*z)
  def length_squared( {x,y,z,w} ),  do: (x*x) + (y*y) + (z*z) + (w*w)

  #--------------------------------------------------------
  def project( vector, matrix ) do
    Matrix.project_vector(matrix, vector)
  end

end

