#
#  Created by Boyd Multerer on 6/4/18.
#  Copyright © 2017 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Utilities.Draw.Paint do
  alias Scenic.Utilities.Draw


  #============================================================================
  # data verification and serialization

  #--------------------------------------------------------
  # verify that a color is correctly described

  def verify( paint ) do
    try do
      normalize( paint )
      true
    rescue
      _ -> false
    end
  end

  #--------------------------------------------------------
  # single color
  def normalize( {:color, color} ),     do: {:color, Draw.Color.normalize(color)}
  def normalize( {:linear, gradient} ), do: {:linear, Draw.LinearGradient.normalize(gradient)}
  def normalize( {:box, gradient} ),    do: {:box, Draw.BoxGradient.normalize(gradient)}
  def normalize( {:radial, gradient} ), do: {:radial, Draw.RadialGradient.normalize(gradient)}
  def normalize( {:image, pattern} ), do: {:image, Draw.Image.normalize(pattern)}
  # default is to treat it like a sindle color
  def normalize( color ), do: {:color, Draw.Color.normalize(color)}

end