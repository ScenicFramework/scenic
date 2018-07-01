#
#  Created by Boyd Multerer on 5/8/17.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Primitive.Rectangle do
  use Scenic.Primitive

# alias Scenic.Primitive
#  alias Scenic.Primitive.Style


  @styles   [:hidden, :fill, :stroke]


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  def info(), do: "Rectangle data must width and height. Like this: {width, height}"

  #--------------------------------------------------------
  def verify( {width, height} = data ) when is_number(width) and is_number(height) do
    {:ok, data}
  end
  def verify( _ ), do:  :invalid_data


  #============================================================================
  def valid_styles(), do: @styles


  #--------------------------------------------------------
  def default_pin(data), do: centroid( data )

  #--------------------------------------------------------
  def centroid(data)
  def centroid({width, height}) do
    { width / 2, round(height / 2) }
  end

  #--------------------------------------------------------
  def contains_point?( { w, h }, {xp,yp} ) do
    xp * w > 0 &&           # width and xp must be the same sign
    yp * h > 0 &&           # height and yp must be the same sign
    abs(xp) < abs(w) &&     # xp must be less than the width
    abs(yp) < abs(h)        # yp must be less than the height
  end

end











